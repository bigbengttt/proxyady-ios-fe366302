CORREÇÕES APLICADAS

Proxy IPA:
- Salva a key no iPhone depois do primeiro login.
- Ao abrir de novo, valida a key salva automaticamente e não pede key.
- Se a key for apagada, bloqueada ou vencida, limpa a key salva e pede novamente.
- Ao validar, envia o IP para /api/ipa_bind.php.
- Sessão da proxy: 5 minutos. Depois o Server_IPA_ONLY.py remove ip/ip_bound automaticamente.
- Visual online separado pelo arquivo /var/www/proxybrasil2026.io.vn/data/IPA/ipa_config.json.
- Partículas verdes e botões verdes controlados pelo endpoint config=1.

Suba server_api/ipa_bind.php em /var/www/html/api/ipa_bind.php
Suba server_api/Server_IPA_ONLY.py em /root/Server_IPA_ONLY.py
Suba server_api/ipa_admin_config.php em /var/www/html/api/ipa_admin_config.php
