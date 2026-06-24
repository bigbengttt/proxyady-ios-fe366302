Projeto revisado nesta versão:

- Tela de sucesso sem nome Bigbeng no fallback.
- Fundo substituído por arte estilo battle royale/Free Fire, com blur escuro para leitura.
- Layout da tela de sucesso alinhado por linhas: porta, descrição e check.
- Botões e partículas controlados online por /api/ipa_bind.php?config=1.
- Key salva no Keychain do iPhone; não pede toda vez.
- Se a key vencer/apagar/bloquear, a IPA remove a key salva e pede login novamente.
- Endpoint principal ofuscado no código Swift, não aparece mais em texto simples no AppConfig.swift.
- Build Release reforçado com strip/otimização no GitHub Actions.
- VPS mantém sessão de IP por 5 minutos e depois apaga IP/sessão no keys.json.

Observação honesta: nenhum app iOS fica 100% impossível de analisar com IDA/Frida/Hex. Esta versão reduz exposição e remove segredos simples do código, mas a segurança principal precisa ficar no servidor/VPS, nunca só dentro da IPA.
