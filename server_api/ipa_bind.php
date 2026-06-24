<?php
header('Content-Type: application/json; charset=utf-8');

$KEYS_FILE = "/var/www/proxybrasil2026.io.vn/data/ADMIN/keys.json";
$SESSION_SECONDS = 300; // 5 minutos: só sessão/IP, não apaga dias da key

function client_ip() {
    $candidates = [
        $_SERVER["HTTP_CF_CONNECTING_IP"] ?? "",
        $_SERVER["HTTP_X_REAL_IP"] ?? "",
        $_SERVER["HTTP_X_FORWARDED_FOR"] ?? "",
        $_SERVER["REMOTE_ADDR"] ?? ""
    ];
    foreach ($candidates as $raw) {
        $ip = trim(explode(',', $raw)[0]);
        if ($ip !== "") return $ip;
    }
    return "";
}

function load_keys($file) {
    if (!file_exists($file)) return [];
    $data = json_decode(file_get_contents($file), true);
    if (!is_array($data)) return [];
    if (array_keys($data) !== range(0, count($data) - 1)) {
        $out = [];
        foreach ($data as $k => $v) {
            $row = is_array($v) ? $v : [];
            if (!isset($row['key'])) $row['key'] = strval($k);
            $out[] = $row;
        }
        return $out;
    }
    return $data;
}

function parse_time_value($v) {
    if ($v === null || $v === "") return 0;
    if (is_numeric($v)) return intval($v);
    $t = strtotime(strval($v));
    return $t ? $t : 0;
}

function save_keys($file, $rows) {
    $dir = dirname($file);
    if (!is_dir($dir)) mkdir($dir, 0755, true);
    $tmp = $file . ".tmp";
    file_put_contents($tmp, json_encode($rows, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE), LOCK_EX);
    rename($tmp, $file);
}

if (isset($_GET["config"])) {
    echo json_encode([
        "success" => true,
        "force_login" => true,
        "remember_key" => true,
        "app_name" => "ProxyADY",
        "host" => "191.252.210.109",
        "proxy_host" => "191.252.210.109",
        "port" => "8088",
        "default_port" => "8088",
        "minutes" => 5,
        "session_timeout_seconds" => $SESSION_SECONDS,
        "show_certificate" => true,
        "certificate_url" => "http://191.252.210.109/proxy2026.der",
        "copy_button_text" => "Copiar servidor",
        "certificate_button_text" => "Baixar certificado",
        "ports" => [
            "8088 = HS alto",
            "8091 = HS alto + pescoço",
            "8092 = HS alto + antena",
            "8093 = HS peito",
            "8094 = HS peito + antena",
            "8095 = Bala mágica + antena",
            "8096 = HS pescoço + alto + antena",
            "8097 = HS pescoço"
        ]
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

$raw = file_get_contents("php://input");
$j = json_decode($raw, true);
if (!is_array($j)) $j = [];

$key = trim($j["key"] ?? $_POST["key"] ?? $_GET["key"] ?? "");
$ip = client_ip();
$now = time();

if ($key === "") {
    echo json_encode(["success"=>false,"valid"=>false,"message"=>"MISSING_KEY","error"=>"MISSING_KEY"], JSON_UNESCAPED_UNICODE);
    exit;
}

$keys = load_keys($KEYS_FILE);
$found = false;
$failMessage = "KEY INVALIDA OU APAGADA";

foreach ($keys as &$row) {
    if (!is_array($row)) continue;
    if (strval($row["key"] ?? "") !== $key) continue;

    $status = strtolower(trim(strval($row["status"] ?? "active")));
    if (!in_array($status, ["active", "ativo", "valid", "valido", ""], true)) {
        $failMessage = "KEY INATIVA";
        break;
    }

    $licExp = parse_time_value($row["expires_at"] ?? $row["expire_at"] ?? $row["valid_until"] ?? "");
    if ($licExp && $licExp <= $now) {
        $row["status"] = "expired";
        $failMessage = "KEY VENCIDA";
        break;
    }

    $found = true;
    $sessionExp = $now + $SESSION_SECONDS;
    $row["ip"] = $ip;
    $row["ip_bound"] = $ip;
    $row["activated_at"] = date("Y-m-d H:i:s", $now);
    $row["session_expires_at"] = date("Y-m-d H:i:s", $sessionExp);
    $row["session_expires_ts"] = $sessionExp;
    $row["last_ipa_bind_at"] = date("Y-m-d H:i:s", $now);
    break;
}
unset($row);

if (!$found) {
    save_keys($KEYS_FILE, $keys);
    echo json_encode(["success"=>false,"valid"=>false,"message"=>$failMessage,"error"=>$failMessage], JSON_UNESCAPED_UNICODE);
    exit;
}

save_keys($KEYS_FILE, $keys);

$sessionExpIso = date("Y-m-d H:i:s", $now + $SESSION_SECONDS);
echo json_encode([
    "success" => true,
    "valid" => true,
    "message" => "IP LIBERADO POR 5 MINUTOS",
    "ip" => $ip,
    "host" => "191.252.210.109",
    "port" => "8088",
    "minutes" => 5,
    "time_left" => $SESSION_SECONDS,
    "session_expires_at" => $sessionExpIso,
    "data" => [
        "key" => $key,
        "ip" => $ip,
        "time_left" => $SESSION_SECONDS,
        "session_expires_at" => $sessionExpIso,
        "proxy" => ["host" => "191.252.210.109", "port" => "8088"]
    ]
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
