<?php
header('Content-Type: application/json; charset=utf-8');

$KEYS_FILE = "/var/www/proxybrasil2026.io.vn/data/ADMIN/keys.json";
$SESSION_SECONDS = 300;

$PORTS = [
    "8088 = HS alto",
    "8091 = HS alto + pescoço",
    "8092 = HS alto + antena",
    "8093 = HS peito",
    "8094 = HS peito + antena",
    "8095 = Bala mágica + antena",
    "8096 = HS pescoço + alto + antena",
    "8097 = HS pescoço"
];

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

function save_keys($file, $rows) {
    $dir = dirname($file);
    if (!is_dir($dir)) mkdir($dir, 0755, true);
    $tmp = $file . ".tmp";
    file_put_contents($tmp, json_encode($rows, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE), LOCK_EX);
    rename($tmp, $file);
}

function parse_time_value($v) {
    if ($v === null || $v === "") return 0;
    if (is_numeric($v)) return intval($v);
    $t = strtotime(strval($v));
    return $t ? $t : 0;
}

function key_exp_ts($row) {
    return parse_time_value($row["expires_at"] ?? $row["expire_at"] ?? $row["valid_until"] ?? $row["expiry"] ?? "");
}

function format_validade($ts) {
    if (!$ts) return "Sem validade definida";
    return date("d/m/Y H:i:s", $ts);
}

if (isset($_GET["config"])) {
    echo json_encode([
        "success" => true,
        "force_login" => true,
        "remember_key" => true,
        "require_device_token" => true,
        "require_uidd" => false,
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
        "ports" => $PORTS
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

$raw = file_get_contents("php://input");
$j = json_decode($raw, true);
if (!is_array($j)) $j = [];

$key = trim($j["key"] ?? $_POST["key"] ?? $_GET["key"] ?? "");
$deviceToken = trim($j["device_token"] ?? $_POST["device_token"] ?? $_GET["device_token"] ?? "");
$deviceModel = trim($j["device_model"] ?? "");
$bundle = trim($j["bundle"] ?? "");
$ip = client_ip();
$now = time();

if ($key === "") {
    echo json_encode(["success"=>false,"valid"=>false,"message"=>"MISSING_KEY","error"=>"MISSING_KEY"], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($deviceToken === "") {
    echo json_encode(["success"=>false,"valid"=>false,"message"=>"DEVICE_TOKEN_MISSING","error"=>"DEVICE_TOKEN_MISSING"], JSON_UNESCAPED_UNICODE);
    exit;
}

$keys = load_keys($KEYS_FILE);
$found = false;
$failMessage = "KEY INVALIDA OU APAGADA";
$licExp = 0;

foreach ($keys as &$row) {
    if (!is_array($row)) continue;
    if (strval($row["key"] ?? "") !== $key) continue;

    $status = strtolower(trim(strval($row["status"] ?? "active")));
    if (!in_array($status, ["active", "ativo", "valid", "valido", ""], true)) {
        $failMessage = "KEY INATIVA";
        break;
    }

    $licExp = key_exp_ts($row);
    if ($licExp && $licExp <= $now) {
        $row["status"] = "expired";
        $failMessage = "KEY VENCIDA";
        break;
    }

    $savedToken = trim(strval($row["device_token"] ?? $row["install_token"] ?? ""));
    if ($savedToken !== "" && !hash_equals($savedToken, $deviceToken)) {
        $failMessage = "KEY JÁ ATIVADA EM OUTRO CELULAR";
        break;
    }

    $found = true;
    $sessionExp = $now + $SESSION_SECONDS;

    $row["device_token"] = $deviceToken;
    $row["device_bound_at"] = $row["device_bound_at"] ?? date("Y-m-d H:i:s", $now);
    $row["device_model"] = $deviceModel;
    $row["bundle"] = $bundle;
    $row["ip"] = $ip;
    $row["ip_bound"] = $ip;
    $row["activated_at"] = $row["activated_at"] ?? date("Y-m-d H:i:s", $now);
    $row["session_active"] = true;
    $row["session_expires_at"] = date("Y-m-d H:i:s", $sessionExp);
    $row["session_expires_ts"] = $sessionExp;
    $row["last_ipa_bind_at"] = date("Y-m-d H:i:s", $now);
    break;
}
unset($row);

if (!$found) {
    save_keys($KEYS_FILE, $keys);
    echo json_encode(["success"=>false,"valid"=>false,"message"=>$failMessage,"error"=>$failMessage], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

save_keys($KEYS_FILE, $keys);

$sessionExpIso = date("Y-m-d H:i:s", $now + $SESSION_SECONDS);
$validade = format_validade($licExp);

echo json_encode([
    "success" => true,
    "valid" => true,
    "message" => "IP LIBERADO POR 5 MINUTOS",
    "ip" => $ip,
    "host" => "191.252.210.109",
    "port" => "8088",
    "default_port" => "8088",
    "minutes" => 5,
    "time_left" => $SESSION_SECONDS,
    "session_expires_at" => $sessionExpIso,
    "expires_at" => $validade,
    "valid_until" => $validade,
    "ports" => $PORTS,
    "data" => [
        "key" => $key,
        "ip" => $ip,
        "device_token_saved" => true,
        "time_left" => $SESSION_SECONDS,
        "session_expires_at" => $sessionExpIso,
        "expires_at" => $validade,
        "valid_until" => $validade,
        "ports" => $PORTS,
        "proxy" => ["host" => "191.252.210.109", "port" => "8088"]
    ]
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
