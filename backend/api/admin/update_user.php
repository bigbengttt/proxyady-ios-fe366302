<?php
require_once dirname(__DIR__) . '/common.php';
$admin = require_admin();
$input = input_json();
$target = trim($input['email'] ?? $input['username'] ?? $input['login'] ?? $_GET['username'] ?? '');
$role = sanitize_role(strtolower(trim($input['role'] ?? $input['plan'] ?? $_GET['role'] ?? 'seller')));
$addCredits = floatval($input['credits'] ?? $input['credit'] ?? $_GET['credit'] ?? 0);
$mode = strtolower(trim($input['credit_mode'] ?? $input['mode'] ?? cfg_value('admin_credit_mode', 'add'))); // add ou set
if ($target === '') fail('USUARIO_VAZIO');
if ($role === 'free' && !boolval(cfg_value('allow_admin_downgrade', false))) {
    // evita rebaixar admin/revendedor por acidente; pode liberar online em app_config.json
}
$users = load_users();
$adminIndex = find_user_index($users, $admin['username']);
$targetIndex = find_user_index($users, $target);
$adminPays = boolval(cfg_value('admin_pays_for_credit_transfer', true));
if ($adminPays && $addCredits > 0 && $adminIndex >= 0) {
    $adminCredit = floatval($users[$adminIndex]['credits'] ?? 0);
    if ($adminCredit < $addCredits) fail('CREDITO_INSUFICIENTE', 402, ['credit'=>$adminCredit, 'need'=>$addCredits]);
    $users[$adminIndex]['credits'] = $users[$adminIndex]['credit'] = $users[$adminIndex]['balance'] = $users[$adminIndex]['saldo'] = $adminCredit - $addCredits;
}
if ($targetIndex >= 0) {
    // quem já é admin não volta pra seller/free sem allow_admin_downgrade=true
    $oldRole = $users[$targetIndex]['role'] ?? 'free';
    if (is_admin_role($oldRole) && !is_admin_role($role) && !boolval(cfg_value('allow_admin_downgrade', false))) $role = 'admin';
    $oldCredit = floatval($users[$targetIndex]['credits'] ?? $users[$targetIndex]['credit'] ?? 0);
    $newCredit = ($mode === 'set') ? $addCredits : ($oldCredit + $addCredits);
    $users[$targetIndex]['role'] = $role; $users[$targetIndex]['plan'] = $role;
    foreach (['credits','credit','balance','saldo'] as $f) $users[$targetIndex][$f] = $newCredit;
    $users[$targetIndex]['status'] = 'active';
    $users[$targetIndex]['updated_at'] = now_iso();
    $out = $users[$targetIndex];
} else {
    $password = bin2hex(random_bytes(4));
    $out = [
        'id'=>$target, 'username'=>$target, 'email'=>$target, 'name'=>$target,
        'password_hash'=>password_hash($password, PASSWORD_DEFAULT),
        'role'=>$role, 'plan'=>$role, 'credits'=>$addCredits, 'credit'=>$addCredits, 'balance'=>$addCredits, 'saldo'=>$addCredits,
        'status'=>'active', 'created_by'=>$admin['username'], 'created_at'=>now_iso(), 'temporary_password'=>$password
    ];
    $users[] = $out;
}
save_users($users);
log_event('admin_update_user', ['admin'=>$admin['username'], 'target'=>$target, 'credits'=>$addCredits, 'mode'=>$mode, 'role'=>$role]);
$public = public_user($out);
if (isset($out['temporary_password'])) $public['temporary_password'] = $out['temporary_password'];
ok($public, 'USUARIO_ATUALIZADO', ['user'=>$public, 'charged_from'=>$admin['username'], 'charged_amount'=>$adminPays ? $addCredits : 0]);
