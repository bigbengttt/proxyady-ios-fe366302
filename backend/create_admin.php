<?php
require_once __DIR__ . '/api/common.php';
if ($argc < 4) { echo "Uso: php create_admin.php usuario email senha\n"; exit(1); }
$username = preg_replace('/[^a-zA-Z0-9_\.\-]/', '', $argv[1]);
$email = $argv[2]; $pass = $argv[3];
$users = read_json('users', []);
$users[$username] = [
  'id'=>make_id('usr'), 'username'=>$username, 'email'=>$email,
  'password_hash'=>password_hash($pass, PASSWORD_DEFAULT),
  'role'=>'admin', 'credit'=>999999, 'plan'=>'admin', 'status'=>'active', 'created_at'=>now_iso()
];
write_json('users', $users);
echo "ADM criado/atualizado: $username\n";
?>
