<?php
require_once __DIR__ . '/common.php';
$saved = read_json('app_config', []);
$primary = $saved['theme']['primary'] ?? ($saved['primary_color'] ?? '#ff1e1e');
$secondary = $saved['theme']['secondary'] ?? ($saved['accent_color'] ?? '#ff4444');
$background = $saved['theme']['background'] ?? '#050505';
$cfg = [
  'success' => true,
  'app_name' => $saved['app_name'] ?? 'ProxyADY',
  'app' => [ 'name' => $saved['app_name'] ?? 'ProxyADY', 'theme' => 'online' ],
  'home_ui' => $saved['home_ui'] ?? [],
  'key_ui' => $saved['key_ui'] ?? [],
  'keys_ui' => $saved['key_ui'] ?? [],
  'colors' => [
    'background' => $background,
    'primary' => $primary,
    'secondary' => $secondary,
    'primary_dark' => $saved['theme']['primary_dark'] ?? $primary,
    'card_bg' => $saved['theme']['card_bg'] ?? '#111111',
    'card_border' => $saved['theme']['card_border'] ?? $primary,
    'text_primary' => $saved['theme']['text_primary'] ?? '#ffffff',
    'text_secondary' => $saved['theme']['text_secondary'] ?? '#b8c7d9',
    'success' => '#22c55e',
    'danger' => '#ff3355',
    'button_gradient_1' => $primary,
    'button_gradient_2' => $secondary
  ],
  'buttons' => $saved['buttons'] ?? [],
  'features' => [
    'enable_online_update' => true,
    'enable_change_theme' => true,
    'enable_key_search' => true,
    'enable_key_reset' => true,
    'show_used_device' => true,
    'highlight_expired_keys' => true,
    'enforce_credits' => true
  ],
  'server_rules' => [
    'keys_file' => $saved['keys_file'] ?? '/var/www/proxybrasil2026.io.vn/data/ADMIN/keys.json',
    'cost_per_key' => $saved['cost_per_key'] ?? 1,
    'admin_pays_for_keys' => $saved['admin_pays_for_keys'] ?? true,
    'admin_pays_for_credit_transfer' => $saved['admin_pays_for_credit_transfer'] ?? true,
    'admin_credit_mode' => $saved['admin_credit_mode'] ?? 'add'
  ]
];
echo json_encode($cfg, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
