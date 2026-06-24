<?php
// Configurador online da IPA. Suba este arquivo em /var/www/html/api/ipa_admin_config.php
// Use: POST JSON com admin_token e campos que quer alterar.
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$BASE_DIR = '/var/www/proxybrasil2026.io.vn/data/IPA';
$CONFIG = $BASE_DIR . '/ipa_config.json';
$ADMIN_TOKEN = getenv('IPA_ADMIN_TOKEN') ?: 'DKehoXVTzOryt1T8/K5V89fmfuP5nwLCY0vcHB/DDBWNi0nwolEDstMEOrlEsxHyiUUj4M/7hRwYD6VApIf9c3kkgQYy6dWE/B69+eT5F0g=';

function out_json($ok, $message, $data=[]) {
    echo json_encode(['success'=>$ok,'message'=>$message,'data'=>$data], JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE);
    exit;
}
function read_json($path, $default=[]) {
    if (!file_exists($path)) return $default;
    $j=json_decode(file_get_contents($path), true);
    return is_array($j)?$j:$default;
}
function write_json($path, $data) {
    if (!is_dir(dirname($path))) @mkdir(dirname($path), 0775, true);
    return file_put_contents($path, json_encode($data, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE), LOCK_EX)!==false;
}
$body=json_decode(file_get_contents('php://input'), true);
if (!is_array($body)) $body=$_POST;
$tok=trim((string)($body['admin_token'] ?? ''));
if ($tok==='' || !hash_equals($ADMIN_TOKEN, $tok)) out_json(false, 'admin_token inválido.');
$config=read_json($CONFIG, read_json(__DIR__.'/ipa_config.json', []));
$allowed=['app_name','name','subtitle','title','success_title','success_status','host','proxy_host','default_port','certificate_url','logos_api_token','bridge_token','heartbeat_seconds','session_timeout_seconds','background','particles','particles_enabled','particle_color','button_text'];
foreach ($allowed as $k) { if (array_key_exists($k,$body) && $body[$k] !== '') $config[$k]=$body[$k]; }
foreach (['ports','ui','texts','colors','theme'] as $k) {
    if (isset($body[$k]) && is_array($body[$k])) $config[$k]=$body[$k];
}
// Também aceita campos soltos para mexer rápido sem JSON grande
if (!isset($config['ui']) || !is_array($config['ui'])) $config['ui']=[];
if (!isset($config['texts']) || !is_array($config['texts'])) $config['texts']=[];
if (!isset($config['colors']) || !is_array($config['colors'])) $config['colors']=[];
$uiKeys=['show_logo','show_title','show_subtitle','show_security_card','show_paste_button','top_padding','logo_height','field_height','button_height'];
foreach ($uiKeys as $k) { if (array_key_exists($k,$body)) $config['ui'][$k]=$body[$k]; }
$textKeys=['subtitle','instruction_login','input_placeholder','connect_button','paste_button'];
foreach ($textKeys as $k) { if (array_key_exists($k,$body)) $config['texts'][$k]=$body[$k]; }
$colorKeys=['background','screen_bg','primary','primary_dark','button_color','particle_color','card_bg','input_bg','text_primary','text_secondary'];
foreach ($colorKeys as $k) { if (array_key_exists($k,$body)) $config['colors'][$k]=$body[$k]; }
if (!write_json($CONFIG,$config)) out_json(false,'Falha ao salvar config. Verifique permissão em /var/www/proxybrasil2026.io.vn/data/IPA');
out_json(true,'Config online atualizada. Reinicie a IPA no iPhone para puxar mudanças.', $config);
