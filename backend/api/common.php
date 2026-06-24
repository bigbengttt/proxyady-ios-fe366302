<?php
header('Content-Type: application/json; charset=utf-8');

// CORS controlado online por app_config.json. Padrão aberto para não quebrar app antigo.
$cfgFile = __DIR__ . '/app_config.json';
$cfg = file_exists($cfgFile) ? json_decode(file_get_contents($cfgFile), true) : [];
if (!is_array($cfg)) $cfg = [];
$allowedOrigin = $cfg['allowed_origin'] ?? '*';
header('Access-Control-Allow-Origin: ' . $allowedOrigin);
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Admin-Secret');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }

define('API_DIR', __DIR__);
define('DATA_DIR', __DIR__); // fonte única: backend/api/*.json
if (!is_dir(DATA_DIR)) { mkdir(DATA_DIR, 0775, true); }

function path_json($name) { return DATA_DIR . '/' . $name . '.json'; }
function read_json($name, $default = []) {
    $p = path_json($name);
    if (!file_exists($p)) {
        file_put_contents($p, json_encode($default, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE), LOCK_EX);
        return $default;
    }
    $j = json_decode(file_get_contents($p), true);
    return is_array($j) ? $j : $default;
}
function write_json($name, $data) {
    file_put_contents(path_json($name), json_encode($data, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE), LOCK_EX);
}
function input_json() {
    $raw = file_get_contents('php://input');
    $j = json_decode($raw, true);
    return is_array($j) ? $j : $_POST;
}
function ok($data = null, $message = 'ok', $extra = []) {
    echo json_encode(array_merge(['success'=>true,'message'=>$message,'data'=>$data], $extra), JSON_UNESCAPED_UNICODE);
    exit;
}
function fail($message = 'erro', $code = 400, $extra = []) {
    http_response_code($code);
    echo json_encode(array_merge(['success'=>false,'message'=>$message,'data'=>null], $extra), JSON_UNESCAPED_UNICODE);
    exit;
}
function now_iso() { return date('c'); }
function make_id($prefix='id') { return $prefix . '_' . bin2hex(random_bytes(8)); }
function make_token() { return bin2hex(random_bytes(32)); }
function key_code($alias='KEY') {
    $alias = preg_replace('/[^A-Z0-9_-]/', '', strtoupper($alias));
    if ($alias === '') $alias = 'KEY';
    return $alias . '-' . strtoupper(bin2hex(random_bytes(2))) . '-' . strtoupper(bin2hex(random_bytes(2))) . '-' . strtoupper(bin2hex(random_bytes(2)));
}
function bearer_token() {
    $h = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (stripos($h, 'Bearer ') === 0) return trim(substr($h, 7));
    return $_GET['token'] ?? $_POST['token'] ?? '';
}
function sanitize_role($role) {
    $role = strtolower(trim((string)$role));
    if (in_array($role, ['supremo','super','super_admin','admin_supremo','owner'], true)) return 'supremo';
    return in_array($role, ['free','seller','admin'], true) ? $role : 'free';
}
function is_admin_role($role) { return in_array(sanitize_role($role), ['admin','supremo'], true); }
function is_supremo_role($role) { return sanitize_role($role) === 'supremo'; }
function public_user($u) {
    unset($u['password'], $u['password_hash'], $u['token']);
    $u['role'] = $u['role'] ?? 'free';
    $u['plan'] = $u['plan'] ?? $u['role'];
    $c = floatval($u['credits'] ?? $u['credit'] ?? $u['balance'] ?? $u['saldo'] ?? 0);
    $u['credits'] = $c; $u['credit'] = $c; $u['balance'] = $c; $u['saldo'] = $c;
    $u['status'] = $u['status'] ?? 'active';
    return $u;
}
function normalize_users($users) {
    if (!is_array($users)) return [];
    $out = [];
    foreach ($users as $k=>$u) {
        if (!is_array($u)) continue;
        if (!isset($u['username']) && is_string($k)) $u['username'] = $k;
        $u['username'] = preg_replace('/[^a-zA-Z0-9_.-]/', '', trim($u['username'] ?? $u['email'] ?? ''));
        if ($u['username'] === '') continue;
        $u['id'] = $u['id'] ?? $u['username'];
        $u['email'] = $u['email'] ?? $u['username'];
        $u['role'] = sanitize_role($u['role'] ?? $u['plan'] ?? 'free');
        $u['plan'] = $u['role'];
        $c = floatval($u['credits'] ?? $u['credit'] ?? $u['balance'] ?? $u['saldo'] ?? 0);
        $u['credits'] = $c; $u['credit'] = $c; $u['balance'] = $c; $u['saldo'] = $c;
        $u['status'] = $u['status'] ?? 'active';
        $out[] = $u;
    }
    return $out;
}
function load_users() { return normalize_users(read_json('users', [])); }
function save_users($users) { write_json('users', array_values(normalize_users($users))); }
function find_user_index(&$users, $login) {
    $login = strtolower(trim($login));
    foreach ($users as $i=>$u) {
        if ($login === strtolower($u['username'] ?? '') || $login === strtolower($u['email'] ?? '') || $login === strtolower($u['id'] ?? '')) return $i;
    }
    return -1;
}
function username_exists($username, $email) {
    $users = load_users();
    foreach ($users as $u) {
        if (strtolower($u['username'] ?? '') === strtolower($username) || strtolower($u['email'] ?? '') === strtolower($email)) return true;
    }
    return false;
}
function require_user() {
    $token = bearer_token();
    if (!$token) fail('Sem token', 401);
    $users = load_users();
    foreach ($users as $u) {
        if (($u['token'] ?? '') && hash_equals((string)$u['token'], (string)$token)) {
            if (($u['status'] ?? 'active') !== 'active') fail('Usuário bloqueado', 403);
            return $u;
        }
    }
    fail('Sessão inválida', 401);
}
function auth_user() { return require_user(); }
function require_admin($u=null) { $u = $u ?: require_user(); if (!is_admin_role($u['role'] ?? 'free')) fail('Precisa ser ADM', 403); return $u; }
function require_supremo($u=null) { $u = $u ?: require_user(); if (!is_supremo_role($u['role'] ?? 'free')) fail('Precisa ser ADM SUPREMO', 403); return $u; }
function require_seller_or_admin($u=null) { $u = $u ?: require_user(); if (!in_array(sanitize_role($u['role'] ?? 'free'), ['seller','admin','supremo'], true)) fail('Sem permissão. Sua conta está free.', 403); return $u; }
function cfg_value($key, $default=null) { $c = read_json('app_config', []); return is_array($c) && array_key_exists($key, $c) ? $c[$key] : $default; }
function proxy_keys_file() { return cfg_value('keys_file', '/var/www/proxybrasil2026.io.vn/data/ADMIN/keys.json'); }
function read_keys_file() {
    $f = proxy_keys_file();
    $dir = dirname($f); if (!is_dir($dir)) @mkdir($dir, 0775, true);
    if (!file_exists($f)) file_put_contents($f, '[]', LOCK_EX);
    $j = json_decode(file_get_contents($f), true);
    return is_array($j) ? $j : [];
}
function write_keys_file($keys) { file_put_contents(proxy_keys_file(), json_encode(array_values($keys), JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE), LOCK_EX); }
function norm_unit($u) {
    $u = strtolower(trim((string)$u));
    $u = str_replace(['á','à','ã','â','é','ê','í','ó','ô','õ','ú','ç'], ['a','a','a','a','e','e','i','o','o','o','u','c'], $u);
    if (in_array($u, ['h','hr','hrs','hora','horas','hour','hours'])) return 'hour';
    if (in_array($u, ['d','dia','dias','day','days'])) return 'day';
    if (in_array($u, ['s','semana','semanas','week','weeks'])) return 'week';
    if (in_array($u, ['mes','meses','month','months'])) return 'month';
    if (in_array($u, ['ano','anos','year','years'])) return 'year';
    return 'day';
}
function unit_label($u, $n) {
    $u = norm_unit($u);
    if ($u === 'hour') return $n == 1 ? 'hora' : 'horas';
    if ($u === 'day') return $n == 1 ? 'dia' : 'dias';
    if ($u === 'week') return $n == 1 ? 'semana' : 'semanas';
    if ($u === 'month') return $n == 1 ? 'mês' : 'meses';
    if ($u === 'year') return $n == 1 ? 'ano' : 'anos';
    return 'dias';
}
function parse_ts($v) { if (!$v) return 0; if (is_numeric($v)) return intval($v); $t = strtotime((string)$v); return $t ?: 0; }
function log_event($type, $data=[]) {
    $logs = read_json('audit_log', []);
    $logs[] = ['at'=>date('c'), 'ip'=>$_SERVER['REMOTE_ADDR'] ?? '', 'type'=>$type, 'data'=>$data];
    if (count($logs) > 1000) $logs = array_slice($logs, -1000);
    write_json('audit_log', $logs);
}
?>
