PROXYADY - PROJETO 100% ONLINE CORRIGIDO

Correções feitas nesta versão:
1) Corrigido erro de build Swift no HomeViewController: ParticleBackgroundView agora usa configure(), sem acessar propriedade privada.
2) ipa_bind.php agora pega o IP real do cliente e libera por 5 minutos usando session_expires_at/session_expires_ts.
3) ipa_bind.php NÃO encurta mais expires_at da key. A validade da key continua sendo a validade original; só a sessão/IP dura 5 minutos.
4) ipa_design.php aceita online:
   - logo_url
   - background_url
   - particle_image_url
   - particle_mode: dot, money, heart, star, snow, image
   - particle_birth_rate
   - buttons[] para criar botões extras por API
   - cores/textos/layout
5) Workflow do GitHub agora grava erro de build em xcodebuild.log/build_logs.

COMO USAR NA VPS:
- Suba a pasta server_api para /var/www/html/api ou copie os arquivos:
  ipa_bind.php, ipa_design.php, ipa_ports.php, ipa_security.php
- Garanta que o keys.json real está em:
  /var/www/proxybrasil2026.io.vn/data/ADMIN/keys.json

TESTES:
curl http://191.252.210.109/api/ipa_bind.php?config=1
curl http://191.252.210.109/api/ipa_design.php

EXEMPLO CHUVA DE DINHEIRO VIA API:
"particles": true,
"particle_mode": "money",
"particle_color": "#00ff66"

EXEMPLO IMAGEM PNG CAINDO:
"particles": true,
"particle_mode": "image",
"particle_image_url": "https://SEUDOMINIO.com/dinheiro.png"

EXEMPLO LOGO ONLINE:
"logo_url": "https://SEUDOMINIO.com/logo.png"

EXEMPLO FUNDO ONLINE:
"background_url": "https://SEUDOMINIO.com/fundo.jpg"

EXEMPLO BOTÕES:
"buttons": [
  {"title":"SUPORTE", "url":"https://t.me/seusuporte", "color":"#00aa44", "text_color":"#ffffff"}
]
