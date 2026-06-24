<?php
require_once dirname(__DIR__) . '/common.php';
require_admin();
$logs = read_json('audit_log', []);
ok(array_slice($logs, -200), 'OK');
