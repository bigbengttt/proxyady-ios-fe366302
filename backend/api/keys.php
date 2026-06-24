<?php
require_once __DIR__ . '/common.php';
$u = require_user();
$input = input_json();
$q = trim($input['q'] ?? $input['search'] ?? $_GET['q'] ?? $_GET['search'] ?? '');
$requested = trim($input['username'] ?? $input['owner'] ?? $_GET['username'] ?? $_GET['owner'] ?? '');
$username = $u['username'];
if (is_admin_role($u['role'] ?? '') && $requested !== '') $username = $requested;
$keys = read_keys_file();
$out = [];
$now = time();
foreach (array_reverse($keys) as $k) {
    $createdBy = strval($k['created_by'] ?? $k['owner'] ?? $k['username'] ?? '');
    if (!is_admin_role($u['role'] ?? '') && $createdBy !== $username) continue;
    if (is_admin_role($u['role'] ?? '') && $requested !== '' && $createdBy !== $username) continue;
    $key = strval($k['key'] ?? $k['key_code'] ?? '');
    if ($key === '') continue;
    if ($q !== '' && stripos($key, $q) === false && stripos(strval($k['alias'] ?? ''), $q) === false) continue;
    $duration = intval($k['days'] ?? $k['duration_days'] ?? $k['duration'] ?? 1);
    $unit = norm_unit($k['duration_type'] ?? $k['unit'] ?? 'day');
    $label = unit_label($unit, $duration);
    $expires = strval($k['expires_at'] ?? '');
    $status = strtolower(strval($k['status'] ?? 'active'));
    $expTs = parse_ts($expires);
    $isExpired = $expTs > 0 && $now >= $expTs;
    if ($isExpired) $status = 'expired';
    $ip = strval($k['ip_bound'] ?? $k['ip'] ?? '');
    $device = strval($k['device'] ?? $k['device_info'] ?? $k['uidd'] ?? $k['udid'] ?? '');
    if ($device === '' && $ip !== '') $device = 'IP: ' . $ip;
    if ($device === '' && !empty($k['activated_at'])) $device = 'Ativada';
    $out[] = [
        'id' => md5($key), 'key' => $key, 'key_code' => $key, 'name' => strval($k['name'] ?? $key),
        'owner' => $createdBy, 'username' => $createdBy, 'created_by' => $createdBy,
        'type' => strval($k['type'] ?? $k['package'] ?? 'PADRAO'), 'package' => strval($k['package'] ?? $k['type'] ?? 'PADRAO'),
        'days' => $duration, 'duration' => $duration, 'duration_days' => $duration,
        'duration_type' => $unit, 'duration_label' => $label, 'unit' => $unit, 'unit_label' => $label,
        'status' => $status, 'expired' => $isExpired, 'used' => boolval($k['used'] ?? false) || !empty($k['activated_at']),
        'ip' => $ip, 'ip_bound' => $ip, 'device' => $device, 'device_info' => $device,
        'session_expires_at' => strval($k['session_expires_at'] ?? ''), 'created_at' => strval($k['created_at'] ?? ''),
        'activated_at' => strval($k['activated_at'] ?? ''), 'expires_at' => $expires
    ];
}
ok($out, 'OK', ['keys'=>$out]);
