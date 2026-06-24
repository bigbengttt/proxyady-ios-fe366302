<?php
require_once __DIR__ . '/../api/common.php';
header('Content-Type: text/html; charset=utf-8');
$admin_key = 'TROQUE_ESSA_SENHA_ADM';
if (($_GET['key'] ?? $_POST['key'] ?? '') !== $admin_key) { echo '<h2>Acesso ADM</h2><form><input name="key" placeholder="senha adm"><button>Entrar</button></form>'; exit; }
$msg='';
if ($_SERVER['REQUEST_METHOD']==='POST') {
  $cfg = read_json('app_config', []);
  $cfg['app_name'] = $_POST['app_name'] ?? $cfg['app_name'];
  $cfg['logo_url'] = $_POST['logo_url'] ?? $cfg['logo_url'];
  $cfg['primary_color'] = $_POST['primary_color'] ?? $cfg['primary_color'];
  $cfg['accent_color'] = $_POST['accent_color'] ?? $cfg['accent_color'];
  $cfg['welcome_subtitle'] = $_POST['welcome_subtitle'] ?? $cfg['welcome_subtitle'];
  $cfg['support_url'] = $_POST['support_url'] ?? $cfg['support_url'];
  $buttons = json_decode($_POST['buttons'] ?? '[]', true);
  if (is_array($buttons)) $cfg['buttons'] = $buttons;
  $cfg['features'] = [
    'show_generate_key'=>isset($_POST['show_generate_key']),
    'show_keys'=>isset($_POST['show_keys']),
    'show_devices'=>isset($_POST['show_devices']),
    'show_credit'=>isset($_POST['show_credit'])
  ];
  write_json('app_config', $cfg);
  if (!empty($_POST['edit_username'])) {
    $users=read_json('users',[]); $un=trim($_POST['edit_username']);
    if (isset($users[$un])) {
      $users[$un]['role']=sanitize_role($_POST['edit_role'] ?? 'free');
      $users[$un]['plan']=$_POST['edit_plan'] ?: $users[$un]['role'];
      $users[$un]['credit']=(float)($_POST['edit_credit'] ?? 0);
      $users[$un]['status']=$_POST['edit_status'] ?? 'active';
      write_json('users',$users); $msg='Config e usuário atualizados.';
    } else { $msg='Config salva. Usuário não encontrado.'; }
  } else { $msg='Config salva.'; }
}
$cfg=read_json('app_config', []); $users=read_json('users', []);
?>
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>ProxyADY ADM</title>
<style>body{background:#090914;color:white;font-family:Arial;margin:0;padding:20px}.card{background:#171227;border:1px solid #31224d;border-radius:18px;padding:16px;margin:12px 0}input,textarea,select{width:100%;padding:12px;margin:6px 0;border-radius:10px;border:1px solid #5b21b6;background:#0f0b1a;color:white}button{background:linear-gradient(90deg,#7c3aed,#4f46e5);color:white;border:0;border-radius:12px;padding:12px 18px;font-weight:700}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px}table{width:100%;border-collapse:collapse}td,th{border-bottom:1px solid #31224d;padding:8px;text-align:left}.ok{color:#a78bfa}</style></head><body>
<h1>ProxyADY ADM Online</h1><p class="ok"><?=htmlspecialchars($msg)?></p>
<form method="post"><input type="hidden" name="key" value="<?=htmlspecialchars($_GET['key'] ?? $_POST['key'] ?? '')?>">
<div class="grid"><div class="card"><h2>Logo e tema</h2><input name="app_name" value="<?=htmlspecialchars($cfg['app_name']??'')?>" placeholder="Nome do app"><input name="logo_url" value="<?=htmlspecialchars($cfg['logo_url']??'')?>" placeholder="URL da logo PNG"><input name="primary_color" value="<?=htmlspecialchars($cfg['primary_color']??'#7C3AED')?>"><input name="accent_color" value="<?=htmlspecialchars($cfg['accent_color']??'#A855F7')?>"><input name="welcome_subtitle" value="<?=htmlspecialchars($cfg['welcome_subtitle']??'')?>"><input name="support_url" value="<?=htmlspecialchars($cfg['support_url']??'')?>"></div>
<div class="card"><h2>Funções visíveis</h2><label><input type="checkbox" name="show_generate_key" <?=!empty($cfg['features']['show_generate_key'])?'checked':''?>> Gerar key</label><br><label><input type="checkbox" name="show_keys" <?=!empty($cfg['features']['show_keys'])?'checked':''?>> Keys</label><br><label><input type="checkbox" name="show_devices" <?=!empty($cfg['features']['show_devices'])?'checked':''?>> Dispositivos</label><br><label><input type="checkbox" name="show_credit" <?=!empty($cfg['features']['show_credit'])?'checked':''?>> Crédito</label></div></div>
<div class="card"><h2>Botões online JSON</h2><p>Edite aqui para criar/tirar botão sem mexer na IPA.</p><textarea name="buttons" rows="12"><?=htmlspecialchars(json_encode($cfg['buttons']??[], JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE))?></textarea></div>
<div class="card"><h2>Mudar usuário online</h2><input name="edit_username" placeholder="username"><select name="edit_role"><option>free</option><option>seller</option><option>admin</option></select><input name="edit_credit" placeholder="crédito ex: 50"><input name="edit_plan" placeholder="plano ex: seller"><select name="edit_status"><option>active</option><option>blocked</option></select></div>
<button>Salvar tudo online</button></form>
<div class="card"><h2>Usuários</h2><table><tr><th>User</th><th>Email</th><th>Role</th><th>Crédito</th><th>Status</th></tr><?php foreach($users as $u){ echo '<tr><td>'.htmlspecialchars($u['username']).'</td><td>'.htmlspecialchars($u['email']).'</td><td>'.htmlspecialchars($u['role']).'</td><td>'.htmlspecialchars($u['credit']).'</td><td>'.htmlspecialchars($u['status']).'</td></tr>'; } ?></table></div>
</body></html>
