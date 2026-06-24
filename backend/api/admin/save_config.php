<?php
require_once dirname(__DIR__) . '/common.php';
$admin = require_admin();
$input = input_json();
if (!$input) fail('JSON_INVALIDO');
$current = read_json('app_config', []);
$merged = array_replace_recursive($current, $input);
write_json('app_config', $merged);
log_event('save_config', ['admin'=>$admin['username']]);
ok($merged, 'CONFIG_ATUALIZADA');
