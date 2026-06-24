<?php
require_once __DIR__ . '/common.php';
$u = require_user();
ok(public_user($u), 'OK', ['user'=>public_user($u)]);
