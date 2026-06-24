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
$removed = 0;
$out = [];
foreach ($keys as $k) {
    $code = strval($k['key'] ?? $k['key_code'] ?? '');
    $owner = strval($k['created_by'] ?? $k['owner'] ?? $k['username'] ?? '');
    $can = (($u['role'] ?? '') === 'admin') || ($owner === ($u['username'] ?? ''));
    if (in_array($code, $list, true) && $can) { $removed++; continue; }
    $out[] = $k;
}
write_keys_file($out);
log_event('delete_keys', ['user'=>$u['username'], 'count'=>$removed]);
ok(['removed'=>$removed], 'KEYS_APAGADAS', ['removed'=>$removed]);
