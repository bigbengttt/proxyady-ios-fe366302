from mitmproxy import http, ctx
import os, json, subprocess, signal, time
from datetime import datetime

# ProxyADY / Proxy key login: IP liberado por sessão de 10 minutos via ipa_bind.php
DATA_DIR = "/var/www/html/api/data"
SESSIONS_FILE = os.path.join(DATA_DIR, "ipa_sessions.json")
DEFAULT_PORT = "8088"
PORT_FOLDER_MAP = {
    "8088": "8088", "8091": "8091", "8092": "8092", "8093": "8093",
    "8094": "8094", "8095": "8095", "8096": "8096", "8097": "8097",
}
ASSETS_BASE = "/var/www/proxybrasil2026.io.vn/data"
connected_ips = set()

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)

def runtime_port():
    try:
        return str(ctx.options.listen_port)
    except Exception:
        return os.environ.get("PROXYADY_PORT", DEFAULT_PORT)

def read_json(path, default):
    try:
        if not os.path.exists(path):
            return default
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        log(f"❌ JSON erro {path}: {e}")
        return default

def session_ok(ip):
    sessions = read_json(SESSIONS_FILE, {})
    row = sessions.get(ip)
    if not isinstance(row, dict):
        return False, "", 0
    exp = int(row.get("expires_ts") or 0)
    left = exp - int(time.time())
    if left <= 0:
        return False, row.get("key", ""), 0
    return True, row.get("key", ""), left

def asset_base_path():
    port = runtime_port()
    folder = PORT_FOLDER_MAP.get(port, port)
    return os.path.join(ASSETS_BASE, folder)

def request(flow: http.HTTPFlow):
    ip = flow.client_conn.peername[0]
    port = runtime_port()
    url = flow.request.pretty_url

    if ip not in connected_ips:
        connected_ips.add(ip)
        log(f"📱 CONECTOU | IP: {ip} | PORTA: {port}")

    ok, key, left = session_ok(ip)
    if not ok:
        log(f"⛔ BLOQUEADO | IP: {ip} | PORTA: {port} | MOTIVO: sem sessão IPA ativa ou passou 10 minutos")
        flow.kill()
        return

    if "freefiremobile.com" not in url:
        return

    base = asset_base_path()
    target_file = None
    label = None
    if url.endswith("fileinfo"):
        target_file = "fileinfo"
        label = "FILEINFO"
    elif "assetindexer" in url:
        label = "ASSETINDEXER"
        try:
            target_file = next(x for x in os.listdir(base) if x.startswith("assetindexer"))
        except Exception:
            target_file = None

    if not target_file:
        return

    path = os.path.join(base, target_file)
    if not os.path.exists(path):
        log(f"⚠️ {label} não encontrado em {path}")
        return

    try:
        with open(path, "rb") as f:
            data = f.read()
        flow.response = http.Response.make(200, data, {"Content-Type": "application/octet-stream"})
        log(f"✅ TROCOU {label} | IP: {ip} | KEY: {key} | RESTA: {left}s | ARQ: {target_file} | BYTES: {len(data)}")
    except Exception as e:
        log(f"❌ ERRO TROCAR {label}: {e}")

def start_server(port=None):
    port = str(port or DEFAULT_PORT)
    pid_file = f"/tmp/proxyady_ipa_{port}.pid"
    if os.path.exists(pid_file):
        print(f"⚠️ Já existe PID: {pid_file}")
        return
    os.makedirs(DATA_DIR, exist_ok=True)
    if not os.path.exists(SESSIONS_FILE):
        with open(SESSIONS_FILE, "w", encoding="utf-8") as f:
            f.write("{}")
    env = os.environ.copy()
    env["PROXYADY_PORT"] = port
    proc = subprocess.Popen([
        "mitmdump", "-s", __file__,
        "--set", f"listen_port={int(port)}",
        "--set", "block_global=false",
        "--set", "keep_host_header=false",
        "--set", "http2=false",
        "--set", "ssl_insecure=true",
        "--set", "connection_strategy=lazy"
    ], env=env)
    with open(pid_file, "w") as f:
        f.write(str(proc.pid))
    print(f"✅ Proxy rodando | porta {port} | PID {proc.pid} | Sessão IPA 10 minutos")

def stop_server(port=None):
    port = str(port or DEFAULT_PORT)
    pid_file = f"/tmp/proxyady_ipa_{port}.pid"
    if not os.path.exists(pid_file):
        print(f"⚠️ Sem PID para porta {port}")
        return
    with open(pid_file) as f:
        pid = int(f.read().strip())
    try:
        os.kill(pid, signal.SIGTERM)
        print(f"🛑 Kill {pid}")
    except Exception:
        pass
    try:
        os.remove(pid_file)
    except Exception:
        pass

if __name__ == "__main__":
    import sys
    if len(sys.argv) >= 3 and sys.argv[1] == "-start":
        start_server(sys.argv[2])
    elif len(sys.argv) >= 3 and sys.argv[1] == "-stop":
        stop_server(sys.argv[2])
    elif len(sys.argv) >= 2 and sys.argv[1] == "-start":
        start_server(DEFAULT_PORT)
    elif len(sys.argv) >= 2 and sys.argv[1] == "-stop":
        stop_server(DEFAULT_PORT)
