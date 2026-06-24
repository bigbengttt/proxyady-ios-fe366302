<?php
require __DIR__.'/common.php';
$u=require_user();
$devices=array_values(read_json('devices',[]));
if(($u['role'] ?? 'free') !== 'admin') $devices=array_values(array_filter($devices, fn($d)=>($d['username']??'')===$u['username']));
ok($devices,'ok');
?>
