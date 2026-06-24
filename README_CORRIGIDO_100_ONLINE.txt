GERADOR PROXYADY - CORRIGIDO 100% ONLINE

O que foi corrigido:
1) Login agora gera token aleatório real e salva em users.json.
2) App iOS agora envia Authorization: Bearer TOKEN automaticamente.
3) generate_key.php não aceita mais owner/username falso do app: gera só para o usuário logado pelo token.
4) admin/update_user.php não aceita mais actor/admin/created_by do app: usa o admin do token.
5) Crédito do usuário é SOMADO por padrão, não sobrescrito.
6) Admin existente não volta para seller/free por acidente. Só libera se allow_admin_downgrade=true no app_config.json.
7) Usuário novo não recebe mais senha fixa 123456. Agora recebe senha temporária aleatória.
8) users.json foi unificado em backend/api/users.json.
9) config/design/key_ui/home_ui/buttons/regras ficam online em backend/api/app_config.json.
10) Adicionado admin/save_config.php para atualizar configuração online por POST com token de admin.
11) Adicionado admin/audit_log.php para ver últimas ações.

INSTALAÇÃO NA VPS:
1) Envie a pasta backend/api para /var/www/html/api
2) Ajuste permissões:
   chown -R www-data:www-data /var/www/html/api
   chmod -R 755 /var/www/html/api
   chmod 666 /var/www/html/api/*.json

TESTE:
   curl http://SEU_HOST/api/app_design.php

CRIAR PRIMEIRO ADMIN:
O primeiro usuário registrado vira admin automaticamente.
Depois faça login no app.

IMPORTANTE:
Se já existe users.json antigo, deixe em /var/www/html/api/users.json.
O sistema aceita senhas antigas em texto no primeiro login e converte para password_hash.

CONFIG ONLINE PRINCIPAL:
Arquivo: /var/www/html/api/app_config.json
Campos úteis:
- app_name
- theme.primary / theme.secondary / theme.background
- home_ui.show_admin_panel
- key_ui.show_package
- key_ui.duration_options
- buttons
- cost_per_key
- max_keys_per_request
- admin_pays_for_keys
- admin_pays_for_credit_transfer
- admin_credit_mode: add ou set
- allow_admin_downgrade
- keys_file

ATUALIZAR CONFIG ONLINE VIA CURL:
TOKEN="COLE_TOKEN_ADMIN_AQUI"
curl -X POST http://SEU_HOST/api/admin/save_config.php \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"app_name":"ProxyADY","theme":{"primary":"#ff1e1e","secondary":"#ff4444","background":"#050505"}}'

VER LOG:
curl http://SEU_HOST/api/admin/audit_log.php -H "Authorization: Bearer $TOKEN"

REGRAS DE CRÉDITO:
- Vendedor sempre paga ao gerar key.
- Admin também paga se admin_pays_for_keys=true.
- Ao colocar crédito em outro usuário, o crédito SOMA se admin_credit_mode=add.
- Para substituir saldo, use admin_credit_mode=set.

