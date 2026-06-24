PROJETO CONFIGURADO PARA NOVA VPS 100% ONLINE

VPS nova: 191.252.210.109
Ponte da IPA: http://191.252.210.109/api/ipa_bind.php
Config online: /var/www/proxybrasil2026.io.vn/data/IPA/ipa_config.json
Certificado: http://191.252.210.109/proxy2026.der

O que ficou online sem recompilar IPA:
- app_name: muda o nome mostrado dentro da IPA
- logos_api_token: muda token da API online
- bridge_token: token da ponte IPA
- host: servidor do Wi-Fi/proxy
- default_port e ports
- certificate_url
- heartbeat_seconds e session_timeout_seconds

ATENÇÃO: o nome embaixo do ícone do iPhone vem do Info.plist e só muda recompilando/reinstalando. O nome dentro da tela da IPA muda online pelo app_name.

COMO SUBIR API NA VPS:
1) Envie a pasta server_api para /root do servidor.
2) Rode:
   cd /root/ipa
   bash server_api/install_online_api.sh

TESTES:
curl -v http://191.252.210.109/api/ipa_bind.php?config=1
curl -v http://191.252.210.109/proxy2026.der

COMO MUDAR NOME/TOKEN ONLINE:
curl -X POST http://191.252.210.109/api/ipa_admin_config.php \
  -H 'Content-Type: application/json' \
  -d '{"admin_token":"DKehoXVTzOryt1T8/K5V89fmfuP5nwLCY0vcHB/DDBWNi0nwolEDstMEOrlEsxHyiUUj4M/7hRwYD6VApIf9c3kkgQYy6dWE/B69+eT5F0g=","app_name":"NovoNome","logos_api_token":"NOVO_TOKEN","bridge_token":"NOVO_TOKEN"}'

PORTAS IPA:
8088, 8091, 8092, 8093, 8094, 8095, 8096, 8097

VISUAL:
- Removida ideia de chuva de dinheiro.
- Tela aprovada usa partículas verdes neon animadas.

TLS:
- A ponte da IPA agora usa HTTP para evitar erro TLS na abertura do app.
- O certificado mitmproxy continua sendo usado apenas para o proxy Wi-Fi.
