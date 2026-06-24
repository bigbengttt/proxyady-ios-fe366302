<?php
require_once __DIR__ . '/common.php';
$u = require_supremo();

$users = load_users();
$keys = read_keys_file();

$sellers = [];
foreach ($users as $user) {
    $role = sanitize_role($user['role'] ?? $user['plan'] ?? 'free');
    if ($role !== 'seller') continue;

    $username = strval($user['username'] ?? $user['email'] ?? '');
    $sellerKeys = [];
    foreach ($keys as $k) {
        $owner = strval($k['created_by'] ?? $k['owner'] ?? $k['username'] ?? '');
        if (strcasecmp($owner, $username) !== 0) continue;

        $key = strval($k['key'] ?? $k['key_code'] ?? '');
        if ($key === '') continue;

        $expires = strval($k['expires_at'] ?? '');
        $status = strtolower(strval($k['status'] ?? 'active'));
        $expTs = parse_ts($expires);
        $expired = $expTs > 0 && time() >= $expTs;
        if ($expired) $status = 'expired';

        $sellerKeys[] = [
            'key' => $key,
            'status' => $status,
            'used' => boolval($k['used'] ?? false) || !empty($k['activated_at']),
            'expired' => $expired,
            'type' => strval($k['type'] ?? $k['package'] ?? 'PADRAO'),
            'duration' => intval($k['days'] ?? $k['duration_days'] ?? $k['duration'] ?? 1),
            'duration_type' => norm_unit($k['duration_type'] ?? $k['unit'] ?? 'day'),
            'created_at' => strval($k['created_at'] ?? ''),
            'activated_at' => strval($k['activated_at'] ?? ''),
            'expires_at' => $expires,
            'device' => strval($k['device_token'] ?? $k['device'] ?? $k['device_info'] ?? $k['uidd'] ?? $k['udid'] ?? '')
        ];
    }

    $sellers[] = [
        'username' => $username,
        'email' => strval($user['email'] ?? $username),
        'credits' => floatval($user['credits'] ?? $user['credit'] ?? $user['balance'] ?? $user['saldo'] ?? 0),
        'status' => strval($user['status'] ?? 'active'),
        'keys_count' => count($sellerKeys),
        'keys' => array_values($sellerKeys)
    ];
}

usort($sellers, function($a, $b) {
    return strcasecmp($a['username'], $b['username']);
});

ok($sellers, 'OK', ['sellers'=>$sellers, 'total'=>count($sellers)]);
?>
