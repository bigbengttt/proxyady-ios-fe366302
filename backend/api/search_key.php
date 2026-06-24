<?php
require_once __DIR__ . '/common.php';
$u = require_user();
$input = input_json();
$q = trim($input['q'] ?? $_GET['q'] ?? '');
$username = ($u['role'] ?? '') === 'admin' ? trim($input['username'] ?? $_GET['username'] ?? '') : $u['username'];
$keys = read_keys_file();
$out = [];
foreach (array_reverse($keys) as $k) {
    $owner = strval($k['created_by'] ?? $k['owner'] ?? $k['username'] ?? '');
    $key = strval($k['key'] ?? $k['key_code'] ?? '');
    if ($username !== '' && $owner !== $username) continue;
    if ($q === '' || stripos($key, $q) !== false) $out[] = $k;
}
ok($out, 'OK', ['keys'=>$out]);
