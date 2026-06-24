CORREÇÕES APLICADAS

Gerador de Keys:
- generate_key.php, create_key.php, keys.php e delete_keys.php usam o JSON certo:
  /var/www/proxybrasil2026.io.vn/data/ADMIN/keys.json
- A aba Keys mostra as últimas 100 keys desse JSON.
- Ao apagar uma key, o registro inteiro é removido; assim o IP some junto e o cliente precisa entrar novamente na IPA.
- Geração limitada a no máximo 10 por vez para evitar centenas de keys sem querer.
- Visual do gerador continua separado do visual da Proxy IPA.
