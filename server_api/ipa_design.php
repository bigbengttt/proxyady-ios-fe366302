<?php
header('Content-Type: application/json; charset=utf-8');

echo json_encode([
  "success" => true,
  "app_name" => "ProxyADY",
  "theme" => "online_total",
  "session_timeout_seconds" => 300,

  "texts" => [
    "instruction_login" => "INSIRA SUA KEY PARA CONTINUAR",
    "input_placeholder" => "Insira sua key",
    "paste_button" => "COLAR KEY",
    "connect_button" => "CONECTAR  →"
  ],

  "colors" => [
    "primary" => "#00ff66",
    "primary_dark" => "#009944",
    "background" => "#000000",
    "card_bg" => "#071107",
    "input_bg" => "#101510",
    "text_primary" => "#ffffff",
    "text_secondary" => "#d8ffd8",
    "particle" => "#00ff66",
    "particle_color" => "#00ff66"
  ],

  "ui" => [
    "show_logo" => true,
    "show_title" => false,
    "show_subtitle" => false,
    "show_security_card" => false,
    "show_paste_button" => true,
    "top_padding" => 70,
    "logo_height" => 110,
    "field_height" => 74,
    "button_height" => 76,
    "background_url" => "",
    "logo_url" => "",
    "particle_image_url" => "",
    "particle_mode" => "dot",
    "particle_birth_rate" => 42,
    "buttons" => []
  ],

  "particles" => true,
  "particle_mode" => "dot",
  "particle_birth_rate" => 42,
  "logo_url" => "",
  "background_url" => "",
  "particle_image_url" => "",

  "buttons" => [
    // Exemplo:
    // ["title" => "SUPORTE", "url" => "https://t.me/seusuporte", "color" => "#00aa44", "text_color" => "#ffffff"]
  ]
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
