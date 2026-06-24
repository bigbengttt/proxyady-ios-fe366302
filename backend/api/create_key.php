<?php
require_once __DIR__ . '/common.php';
$actor = require_seller_or_admin();
$input = input_json();

$quantity = intval($_GET['qtd'] ?? $_GET['quantity'] ?? $input['qtd'] ?? $input['quantity'] ?? 1);
if ($quantity < 1) $quantity = 1;
$maxQty = intval(cfg_value('max_keys_per_request', 100));
if ($maxQty < 1) $maxQty = 100;
if ($quantity > $maxQty) $quantity = $maxQty;

$duration = max(1, intval($_GET['duracao'] ?? $_GET['duration'] ?? $input['duracao'] ?? $input['duration'] ?? $input['days'] ?? 1));
$durationType = norm_unit($_GET['unit'] ?? $_GET['duration_type'] ?? $input['duration_type'] ?? $input['unit'] ?? 'day');
$durationLabel = unit_label($durationType, $duration);
$alias = strtoupper(trim($_GET['alias'] ?? $input['alias'] ?? $input['prefix'] ?? cfg_value('default_alias', 'ADMIN')));
$alias = preg_replace('/[^A-Z0-9_-]/', '', $alias);
if ($alias === '') $alias = 'ADMIN';
$type = trim($_GET['type'] ?? $input['type'] ?? $input['package'] ?? 'PADRAO');
$owner = $actor['username']; // nunca confiar em owner vindo do app
$isAdmin = (is_admin_role($actor['role'] ?? ''));

$costPerKey = floatval(cfg_value('cost_per_key', 1));
$totalCost = $quantity * $costPerKey;
$users = load_users();
$actorIndex = find_user_index($users, $owner);
if ($actorIndex < 0) fail('USUARIO_NAO_ENCONTRADO', 404);
$credit = floatval($users[$actorIndex]['credits'] ?? $users[$actorIndex]['credit'] ?? 0);
$adminPays = boolval(cfg_value('admin_pays_for_keys', true));
if (($actor['role'] ?? 'free') === 'free') fail('PLANO_FREE_NAO_GERA_KEY', 403);
if (!is_admin_role($actor['role'] ?? '') || $adminPays) {
    if ($credit < $totalCost) fail('CREDITO_INSUFICIENTE', 402, ['need'=>$totalCost, 'credit'=>$credit]);
}

$keys = read_keys_file();
$newKeys = [];
$now = time();
for ($i=0; $i<$quantity; $i++) {
    do { $code = key_code($alias); } while (array_filter($keys, fn($k)=>($k['key'] ?? '') === $code));
    $item = [
        'key' => $code,
        'key_code' => $code,
        'name' => $code,
        'owner' => $owner,
        'username' => $owner,
        'created_by' => $owner,
        'alias' => $alias,
        'type' => $type,
        'package' => $type,
        'days' => $duration,
        'duration' => $duration,
        'duration_days' => $duration,
        'duration_type' => $durationType,
        'duration_label' => $durationLabel,
        'unit' => $durationType,
        'unit_label' => $durationLabel,
        'status' => 'active',
        'used' => false,
        'starts_counting' => 'on_activation',
        'created_at' => date('Y-m-d H:i:s', $now),
        'activated_at' => '',
        'expires_at' => '',
        'ip' => '',
        'ip_bound' => '',
        'device' => '',
        'device_info' => '',
        'session_expires_at' => ''
    ];
    $keys[] = $item;
    $newKeys[] = $item;
}
if (!is_admin_role($actor['role'] ?? '') || $adminPays) {
    $newCredit = max(0, $credit - $totalCost);
    foreach (['credit','credits','balance','saldo'] as $f) $users[$actorIndex][$f] = $newCredit;
}
save_users($users);
write_keys_file($keys);
log_event('generate_keys', ['owner'=>$owner, 'qty'=>$quantity, 'cost'=>$totalCost]);
$strings = array_map(fn($k) => $k['key'], $newKeys);
ok($newKeys, count($newKeys) . ' key(s) gerada(s)', ['count'=>count($newKeys), 'key'=>$strings[0] ?? '', 'keys'=>$strings, 'user'=>public_user($users[$actorIndex])]);
