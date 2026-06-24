<?php
require_once __DIR__ . '/common.php';
$input = input_json();
$username = preg_replace('/[^a-zA-Z0-9_.-]/', '', trim($input['username'] ?? ''));
$email = trim($input['email'] ?? $username);
$password = strval($input['password'] ?? '');
if (strlen($username) < 2 || strlen($password) < 4) fail('DADOS_INVALIDOS');
$users = load_users();
if (username_exists($username, $email)) fail('USUARIO_JA_EXISTE');
$role = count($users) === 0 ? 'admin' : 'free'; // primeiro usuário vira admin para instalação inicial
$user = [
    'id'=>$username,
    'username'=>$username,
    'email'=>$email,
    'name'=>$username,
    'password_hash'=>password_hash($password, PASSWORD_DEFAULT),
    'token'=>make_token(),
    'role'=>$role,
    'plan'=>$role,
    'credits'=>0,
    'credit'=>0,
    'balance'=>0,
    'saldo'=>0,
    'status'=>'active',
    'created_at'=>now_iso()
];
$users[] = $user;
save_users($users);
log_event('register', ['user'=>$username, 'role'=>$role]);
ok(public_user($user), 'CONTA_CRIADA', ['token'=>$user['token'], 'user'=>public_user($user)]);
