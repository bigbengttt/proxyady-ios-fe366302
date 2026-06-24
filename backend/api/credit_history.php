<?php
require __DIR__.'/common.php';
$u=require_user();
$tx=array_values(read_json('credit_tx',[]));
if(($u['role'] ?? 'free') !== 'admin') $tx=array_values(array_filter($tx, fn($t)=>($t['username']??'')===$u['username']));
ok($tx,'ok');
?>
