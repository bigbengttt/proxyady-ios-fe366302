TELA 100% ONLINE - PROXYADY

O que foi mudado:
- Tirou BIGBENG da tela de login.
- Tirou o texto "Conexão rápida e segura".
- Tirou o card "Conexão segura" de baixo.
- Tirou o ícone antigo de QR no campo.
- Colocou botão "COLAR KEY".
- Botão retorno do teclado agora fecha o teclado.
- Tela puxa config online da VPS toda vez que abre.

Arquivos importantes da VPS:
- server_api/ipa_bind.php
- server_api/ipa_admin_config.php
- server_api/ipa_config.json

Para subir na VPS:
cp server_api/ipa_bind.php /var/www/html/api/ipa_bind.php
cp server_api/ipa_admin_config.php /var/www/html/api/ipa_admin_config.php
mkdir -p /var/www/html/api/data
cp server_api/ipa_config.json /var/www/html/api/data/ipa_config.json
chmod -R 777 /var/www/html/api/data
systemctl restart nginx

Exemplo para esconder botão colar online:
curl -X POST http://SEU_IP/api/ipa_admin_config.php \
 -H 'Content-Type: application/json' \
 -d '{"admin_token":"SEU_TOKEN_ADMIN","show_paste_button":false}'

Exemplo para mudar nome online e mostrar título:
curl -X POST http://SEU_IP/api/ipa_admin_config.php \
 -H 'Content-Type: application/json' \
 -d '{"admin_token":"SEU_TOKEN_ADMIN","app_name":"NOVO NOME","show_title":true}'

Exemplo para mudar cor rosa/roxo:
curl -X POST http://SEU_IP/api/ipa_admin_config.php \
 -H 'Content-Type: application/json' \
 -d '{"admin_token":"SEU_TOKEN_ADMIN","primary":"#ff2fb3","primary_dark":"#b00068","background":"#050005"}'

Exemplo para mudar posição/tamanho:
curl -X POST http://SEU_IP/api/ipa_admin_config.php \
 -H 'Content-Type: application/json' \
 -d '{"admin_token":"SEU_TOKEN_ADMIN","top_padding":30,"logo_height":90,"field_height":70,"button_height":72}'

Depois de mudar online, fecha e abre a IPA no iPhone para puxar a config nova.
