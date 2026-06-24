<?php
require_once __DIR__ . '/common.php';
$u = require_user();
$input = input_json();
$list = $input['keys'] ?? [];
if (!is_array($list)) $list = [$list];
if (isset($input['key']) && $input['key']) $list[] = $input['key'];
$list = array_values(array_unique(array_filter(array_map('strval', $list))));
if (!$list) fail('NENHUMA_KEY');
$keys = read_keys_file();
$changed = 0;
foreach ($keys as &$k) {
    $code = strval($k['key'] ?? $k['key_code'] ?? '');
    $owner = strval($k['created_by'] ?? $k['owner'] ?? $k['username'] ?? '');
    $can = (($u['role'] ?? '') === 'admin') || ($owner === ($u['username'] ?? ''));
    if (in_array($code, $list, true) && $can) {
        foreach (['ip','ip_bound','first_ip','device','device_info','uidd','udid','session_expires_at'] as $f) $k[$f] = '';
        $k['used'] = false;
        $k['activated_at'] = '';
        $changed++;
    }
}
unset($k);
write_keys_file($keys);
log_event('reset_keys', ['user'=>$u['username'], 'count'=>$changed]);
ok(['reset'=>$changed], 'KEYS_RESETADAS', ['reset'=>$changed]);
