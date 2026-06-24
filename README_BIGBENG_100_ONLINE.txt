Bigbeng 100% online - nova VPS

Arquivos principais:
- ProxyADY/AppConfig.swift: só fallback; a IPA busca tudo em http://191.252.210.109/api/ipa_bind.php
- ProxyADY/APIClient.swift: lê token online pelos campos token, logos_api_token ou api_token.
- ProxyADY/HomeViewController.swift: mostra todas as portas online e não mostra mais texto de minimizar.
- server_api/ipa_bind.php: bridge online que grava IP/key e libera sessão.
- server_api/ipa_config.json: exemplo de config online editável.
- server_api/Server_IPA_SESSION.py: proxy valida IP/key por sessão, agora padrão 300 segundos.

Para instalar a API na VPS:
1) Copie server_api/ipa_bind.php para /var/www/html/api/ipa_bind.php
2) Copie server_api/ipa_config.json para /var/www/proxybrasil2026.io.vn/data/IPA/ipa_config.json
3) Reinicie/rode as portas com Server_IPA_SESSION.py

Para trocar online sem rebuild:
- Nome: app_name ou texts.title
- Token: token, logos_api_token, api_token e bridge_token
- Host Wi-Fi: host, proxy_host, wifi_server
- Cor partículas: theme.particle_color
- Cor brilho: theme.glow_color
- Fundo: theme.background_color
- Textos: texts.login, texts.approved, texts.instruction, texts.ports_title
- Portas: ports
- Tempo da sessão: session_timeout_seconds

Modo 5 minutos:
- heartbeat_enabled=false
- session_timeout_seconds=300
Assim, a IPA envia IP/key ao aprovar e o servidor corta após 5 minutos sem renovar.
