CORREÇÕES APLICADAS

1) A aba Keys agora chama /keys.php?username=USUARIO_LOGADO.
   Cada vendedor vê apenas as próprias keys.

2) Botão de pesquisa adicionado na aba Keys.

3) Botão de reset adicionado para keys selecionadas.
   Reset limpa IP/dispositivo, mas NÃO apaga activated_at nem expires_at.
   Ou seja: não zera os dias da key.

4) Keys geradas começam com expires_at vazio.
   Os dias só começam a contar quando o cliente usa a key na IPA Proxy.

5) Generate key desconta crédito automaticamente:
   - nego = supremo, não desconta
   - seller/admin normal desconta 1 crédito por key
   - free não gera key

6) Login não aceita qualquer usuário como ADM.

7) Endpoints novos:
   /api/reset_keys.php
   /api/reset_key.php
   /api/search_key.php

OBSERVAÇÃO IMPORTANTE PARA A IPA PROXY:
Para os dias começarem só quando o cliente logar na IPA Proxy, o ipa_bind.php da servidor precisa ativar a key na primeira validação:
- se activated_at estiver vazio, setar activated_at=agora e expires_at=agora+duração
- se activated_at já existir, não mexer em expires_at
