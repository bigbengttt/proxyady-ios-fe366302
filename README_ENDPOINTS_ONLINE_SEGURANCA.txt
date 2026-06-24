PROXY IPA - ONLINE DESIGN + PROTEÇÃO

Endpoints que a IPA lê ao abrir:
- /api/ipa_bind.php?config=1  -> config principal, key, host, porta, certificado
- /api/ipa_design.php         -> visual online: cores, fundo, botões, partículas, textos
- /api/ipa_ports.php          -> IP do servidor e lista de portas
- /api/ipa_security.php       -> tempo de sessão e opções de segurança

Instalação na VPS:
cd /root/server_api
bash INSTALAR_ENDPOINTS_ONLINE.sh

Atenção: nenhuma proteção deixa app 100% impossível de modificar. Foi adicionado:
- Keychain para salvar key
- validação online da key salva
- endpoint ofuscado
- bloqueio básico de jailbreak/dylib suspeita/Frida/Substrate
- flags de release/strip/dead-code quando o projeto usa Release
