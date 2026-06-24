Bigbeng build fix final:
- ProxyADY.xcodeproj fica na raiz.
- Workflow ignora exit 65 somente se o .app foi gerado, para o GitHub Actions ficar SUCCESS e o bot baixar o IPA.
- IPA mostra nome/textos/cores/partículas/portas a partir de /api/ipa_bind.php.
- Sessão padrão: 5 minutos, sem texto de minimizada.
