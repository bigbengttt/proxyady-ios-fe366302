from mitmproxy import http, ctx
import os, json, subprocess, sys, signal, time
from datetime import datetime

BASE_DIR = "/var/www/proxybrasil2026.io.vn/data"
KEY_TYPE = os.environ.get("PROXYADY_KEY_TYPE", "ADMIN").strip().upper()
DEFAULT_PORT = "8088"
PORT_FOLDER_MAP = {
    "7722": "7722",
    "8088": "8088",
    "8091": "8091",
    "8092": "8092",
    "8093": "8093",
    "8094": "8094",
    "8095": "8095",
    "8096": "8096",
    "8097": "8097",
}

connected_ips = set()
keys_cache = []
last_load = 0

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)

def get_runtime_port():
    try:
        return int(ctx.options.listen_port)
    except Exception:
        return int(os.environ.get("PROXYADY_PORT", DEFAULT_PORT))

def get_port_text():
    return os.environ.get("PROXYADY_PORT_TEXT", str(get_runtime_port()))

def get_assets_base_path():
    porta = get_port_text()
    pasta = PORT_FOLDER_MAP.get(porta, porta)
    return os.path.join(BASE_DIR, pasta)

def keys_path():
    return os.path.join(BASE_DIR, KEY_TYPE, "keys.json")

def read_json(path, default=None):
    try:
        if not os.path.exists(path):
            return default if default is not None else {}
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        log(f"❌ ERRO JSON {path}: {e}")
        return default if default is not None else {}

def save_json(path, data):
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        os.replace(tmp, path)
        return True
    except Exception as e:
        log(f"❌ ERRO SALVAR JSON {path}: {e}")
        return False

def normalize_list(data):
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        out = []
        for k, v in data.items():
            row = v if isinstance(v, dict) else {}
            row["key"] = row.get("key") or k
            out.append(row)
        return out
    return []

def parse_time(v):
    if not v:
        return None
    try:
        if isinstance(v, (int, float)) or str(v).isdigit():
            return int(v)
        raw = str(v).strip().replace('/', '-')
        return int(datetime.strptime(raw, "%Y-%m-%d %H:%M:%S").timestamp())
    except Exception:
        try:
            return int(datetime.fromisoformat(str(v).replace('Z','+00:00')).timestamp())
        except Exception:
            return None

def load_keys_fresh(force=False):
    global keys_cache, last_load
    if not force and time.time() - last_load <= 1:
        return keys_cache
    path = keys_path()
    rows = normalize_list(read_json(path, []))
    now = int(time.time())
    changed = False
    for row in rows:
        if not isinstance(row, dict):
            continue
        # Key vencida/apagada/bloqueada corta tudo.
        lic_exp = parse_time(row.get("expires_at"))
        if lic_exp and now >= lic_exp:
            if str(row.get("status", "")).lower() != "expired":
                row["status"] = "expired"
                row["expired_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                changed = True
            for f in ("ip", "ip_bound", "activated_at", "session_expires_at", "session_expires_ts"):
                if row.get(f):
                    row[f] = "" if f != "session_expires_ts" else 0
                    changed = True
            continue
        # Sessão de IP expirada: apaga só IP/sessão, mantém key ativa.
        sess_exp = parse_time(row.get("session_expires_at")) or int(row.get("session_expires_ts") or 0)
        if sess_exp and now >= sess_exp and (row.get("ip_bound") or row.get("ip")):
            old_ip = row.get("ip_bound") or row.get("ip")
            row["ip"] = ""
            row["ip_bound"] = ""
            row["activated_at"] = ""
            row["session_expires_at"] = ""
            row["session_expires_ts"] = 0
            changed = True
            log(f"⏱️ SESSAO 5 MIN EXPIRADA | IP REMOVIDO: {old_ip} | KEY: {row.get('key','')}")
    if changed:
        save_json(path, rows)
    keys_cache = rows
    last_load = time.time()
    return rows

def check_ip_auth(flow):
    ip = flow.client_conn.peername[0]
    keys = load_keys_fresh()
    now = int(time.time())
    for row in keys:
        if not isinstance(row, dict):
            continue
        status = str(row.get("status", "active")).lower().strip()
        if status not in ("active", ""):
            continue
        if row.get("is_blocked") or row.get("is_paused"):
            continue
        lic_exp = parse_time(row.get("expires_at"))
        if lic_exp and now >= lic_exp:
            continue
        saved_ip = str(row.get("ip_bound") or row.get("ip") or "").strip()
        if saved_ip != ip:
            continue
        sess_exp = parse_time(row.get("session_expires_at")) or int(row.get("session_expires_ts") or 0)
        if not sess_exp:
            return False, f"sessao_sem_validade: {ip}", ""
        if now >= sess_exp:
            row["ip"] = ""
            row["ip_bound"] = ""
            row["activated_at"] = ""
            row["session_expires_at"] = ""
            row["session_expires_ts"] = 0
            save_json(keys_path(), keys)
            log(f"⏱️ SESSAO 5 MIN EXPIRADA | IP REMOVIDO: {ip} | KEY: {row.get('key','')}")
            return False, f"SESSAO EXPIRADA 5 MIN: {ip}", ""
        return True, "OK", row.get("key", "")
    return False, f"IP não autorizado ou key vencida/bloqueada/apagada: {ip}", ""

def forbidden_response():
    body = b"KEY_EXPIRED_OR_BLOCKED"
    return http.Response.make(403, body, {
        "Content-Type": "text/plain",
        "Content-Length": str(len(body)),
        "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
        "Pragma": "no-cache",
        "Expires": "0",
        "Connection": "close",
    })

def close_client_connection(flow):
    try:
        flow.client_conn.close()
    except Exception:
        pass
    try:
        flow.server_conn.close()
    except Exception:
        pass

def is_game_asset_url(url):
    u = (url or "").lower()
    if "freefiremobile.com" not in u:
        return False
    return u.endswith("fileinfo") or "assetindexer" in u or "/abhotsupdates/" in u

def block_if_not_authorized(flow, stage):
    ip = flow.client_conn.peername[0]
    url = flow.request.pretty_url
    ok, msg, key = check_ip_auth(flow)
    if not ok:
        log(f"⛔ BLOQUEADO POR IP 3S SEM DOWNLOAD/SEM INJETAR | FASE: {stage} | IP: {ip} | PORTA: {get_runtime_port()} | TIPO: {KEY_TYPE} | URL: {url[:120]} | {msg}")
        time.sleep(3)
        flow.response = forbidden_response()
        close_client_connection(flow)
        return True, msg, ""
    log(f"✅ IP LIBERADO | IP: {ip} | PORTA: {get_runtime_port()} | KEY: {key}")
    return False, "OK", key

def inject_asset_if_authorized(flow, key):
    ip = flow.client_conn.peername[0]
    url = flow.request.pretty_url.lower()
    base_path = get_assets_base_path()
    target_file = None
    tipo = None

    if url.endswith("fileinfo"):
        target_file = "fileinfo"
        tipo = "FILEINFO"
    elif "assetindexer" in url:
        tipo = "ASSETINDEXER"
        try:
            target_file = next(x for x in os.listdir(base_path) if x.startswith("assetindexer"))
        except Exception:
            target_file = None

    if not target_file:
        return

    file_path = os.path.join(base_path, target_file)
    if not os.path.exists(file_path):
        log(f"❌ ERRO {tipo} | IP: {ip} | ARQUIVO NÃO EXISTE: {file_path}")
        flow.response = forbidden_response()
        return

    with open(file_path, "rb") as f:
        data = f.read()

    log(f"✅ TROCOU {tipo} | IP: {ip} | PORTA: {get_runtime_port()} | PASTA: {base_path} | TIPO: {KEY_TYPE} | KEY: {key} | ARQUIVO: {target_file} | TAMANHO: {len(data)} bytes")
    flow.response = http.Response.make(200, data, {
        "Content-Length": str(len(data)),
        "Content-Type": "application/octet-stream",
        "Connection": "keep-alive",
        "Accept-Ranges": "bytes",
    })

def request(flow: http.HTTPFlow):
    try:
        ip = flow.client_conn.peername[0]
        if ip not in connected_ips:
            connected_ips.add(ip)
            log(f"📱 CONECTOU | IP: {ip} | PORTA: {get_runtime_port()} | TIPO: {KEY_TYPE}")
        blocked, msg, key = block_if_not_authorized(flow, "REQUEST")
        if blocked:
            return
    except Exception as e:
        log(f"❌ RUNTIME ERROR REQUEST: {e}")

def response(flow: http.HTTPFlow):
    try:
        url = flow.request.pretty_url
        if not is_game_asset_url(url):
            return
        blocked, msg, key = block_if_not_authorized(flow, "RESPONSE")
        if blocked:
            return
        inject_asset_if_authorized(flow, key)
    except Exception as e:
        log(f"❌ RUNTIME ERROR RESPONSE: {e}")

class ProxyADYIPA:
    def request(self, flow: http.HTTPFlow):
        request(flow)
    def response(self, flow: http.HTTPFlow):
        response(flow)

addons = [ProxyADYIPA()]

def start_server(port=None):
    port_text = str(port or DEFAULT_PORT)
    port_int = int(port_text)
    pid_file = f"/tmp/proxyady_ipa_{port_text}.pid"
    os.makedirs(os.path.join(BASE_DIR, KEY_TYPE), exist_ok=True)
    os.makedirs(os.path.join(BASE_DIR, port_text), exist_ok=True)
    if not os.path.exists(keys_path()):
        with open(keys_path(), "w", encoding="utf-8") as f:
            f.write("[]")
    env = os.environ.copy()
    env["PROXYADY_PORT"] = str(port_int)
    env["PROXYADY_PORT_TEXT"] = port_text
    env["PROXYADY_KEY_TYPE"] = KEY_TYPE
    proc = subprocess.Popen([
        "mitmdump", "-s", __file__,
        "--set", f"listen_port={port_int}",
        "--set", "block_global=false",
        "--set", "keep_host_header=false",
        "--set", "http2=false",
        "--set", "ssl_insecure=true",
        "--set", "connection_strategy=lazy",
    ], env=env)
    with open(pid_file, "w") as f:
        f.write(str(proc.pid))
    print(f"✅ Proxy IPA rodando | porta {port_text} | PID {proc.pid}")
    print(f"🔐 Keys: {keys_path()}")
    print(f"📦 Arquivos: {os.path.join(BASE_DIR, port_text)}")

def stop_server(port=None):
    port_text = str(port or DEFAULT_PORT)
    pid_file = f"/tmp/proxyady_ipa_{port_text}.pid"
    if os.path.exists(pid_file):
        with open(pid_file) as f:
            pids = [int(x.strip()) for x in f if x.strip()]
        for pid in pids:
            try:
                os.kill(pid, signal.SIGTERM)
                print(f"🛑 Kill {pid}")
            except Exception:
                pass
        try:
            os.remove(pid_file)
        except Exception:
            pass
    else:
        os.system(f"pkill -f 'listen_port={port_text}'")
    print(f"🔥 Proxy IPA parada | porta {port_text}")

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) >= 2 else ""
    port = sys.argv[2] if len(sys.argv) >= 3 else DEFAULT_PORT
    if action == "-start":
        start_server(port)
    elif action == "-stop":
        stop_server(port)
    else:
        print("Uso:")
        print("  python3 /root/Server_IPA_ONLY.py -start 8097")
        print("  python3 /root/Server_IPA_ONLY.py -stop 8097")
