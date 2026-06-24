<?php
require_once __DIR__ . '/common.php';
$input = input_json();
$login = strtolower(trim($input['email'] ?? $input['username'] ?? $input['login'] ?? ''));
$password = strval($input['password'] ?? '');
if ($login === '' || $password === '') fail('USUARIO_OU_SENHA_INVALIDO', 401);
$users = load_users();
foreach ($users as $i=>$u) {
    $okLogin = ($login === strtolower($u['username'] ?? '') || $login === strtolower($u['email'] ?? '') || $login === strtolower($u['id'] ?? ''));
    if (!$okLogin) continue;
    $okPass = false;
    if (isset($u['password_hash']) && password_verify($password, $u['password_hash'])) $okPass = true;
    if (!$okPass && isset($u['password']) && hash_equals(strval($u['password']), $password)) {
        $okPass = true;
        $users[$i]['password_hash'] = password_hash($password, PASSWORD_DEFAULT);
        unset($users[$i]['password']);
    }
    if (!$okPass) fail('USUARIO_OU_SENHA_INVALIDO', 401);
    if (($users[$i]['status'] ?? 'active') !== 'active') fail('USUARIO_BLOQUEADO', 403);
    $users[$i]['token'] = make_token();
    $users[$i]['last_login_at'] = now_iso();
    save_users($users);
    log_event('login', ['user'=>$users[$i]['username']]);
    ok(public_user($users[$i]), 'LOGIN OK', ['token'=>$users[$i]['token'], 'user'=>public_user($users[$i])]);
}
fail('USUARIO_OU_SENHA_INVALIDO', 401);
