PROXYADY - DESIGN ONLINE TOTAL

Este projeto foi ajustado para a IPA aceitar pela VPS:

1) logo_url
   Troca a logo da tela por imagem PNG/JPG online.

2) background_url ou login_background_url
   Coloca imagem de fundo online.

3) particle_mode
   Tipos aceitos:
   - dot
   - money
   - heart
   - star
   - snow
   - image

4) particle_image_url
   Usa qualquer PNG online como partícula caindo.
   Exemplo: dinheiro.png, moeda.png, caveira.png, raio.png, fogo.png.

5) particle_birth_rate
   Quantidade de partículas. Exemplo: 20 leve, 60 médio, 120 forte.

6) buttons
   Cria botões extras online, cada um com title, url, color e text_color.

EXEMPLO DE /var/www/html/api/ipa_design.php:

cat > /var/www/html/api/ipa_design.php << 'PHP'
<?php
header('Content-Type: application/json; charset=utf-8');

echo json_encode([
  "success" => true,
  "app_name" => "ProxyADY",
  "title" => "INSIRA SUA KEY PARA CONTINUAR",
  "subtitle" => "",

  "logo_url" => "http://191.252.210.109/logo.png",
  "background_url" => "http://191.252.210.109/fundo.jpg",

  "colors" => [
    "primary" => "#00ff66",
    "primary_dark" => "#00aa44",
    "background" => "#050805",
    "card" => "#101510",
    "input_bg" => "#101810",
    "text_primary" => "#ffffff",
    "text_secondary" => "#e8ffe8",
    "particle" => "#00ff66"
  ],

  "particles" => true,
  "particle_mode" => "money",
  "particle_image_url" => "http://191.252.210.109/dinheiro.png",
  "particle_birth_rate" => 70,

  "buttons" => [
    [
      "title" => "SUPORTE WHATSAPP",
      "url" => "https://wa.me/5500000000000",
      "color" => "#00aa44",
      "text_color" => "#ffffff"
    ],
    [
      "title" => "BAIXAR CERTIFICADO",
      "url" => "http://191.252.210.109/proxy2026.der",
      "color" => "#111111",
      "text_color" => "#00ff66"
    ]
  ]
], JSON_UNESCAPED_UNICODE);
PHP

COMO SUBIR IMAGENS:

cp logo.png /var/www/html/logo.png
cp fundo.jpg /var/www/html/fundo.jpg
cp dinheiro.png /var/www/html/dinheiro.png
chmod 644 /var/www/html/logo.png /var/www/html/fundo.jpg /var/www/html/dinheiro.png

Depois teste:
curl http://191.252.210.109/api/ipa_design.php
