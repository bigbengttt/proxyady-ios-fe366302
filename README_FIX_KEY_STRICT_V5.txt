CORREÇÃO V5

O que foi corrigido:
1) A IPA não digita mais key pelo teclado: agora é somente botão COLAR KEY.
2) Removido risco de liberar com qualquer texto/config demo.
3) ipa_bind.php agora é STRICT: só libera se a key existir em keys.json, status active e validade futura.
4) Proxy Python agora confere session_expires_at de 10 minutos, não aceita IP solto.
5) Tela continua online via ipa_config.json: dá para mudar logo, textos, cores, posição, botão colar, etc.

IMPORTANTE NA VPS:
Suba os arquivos da pasta server_api para sua VPS e substitua o ipa_bind.php antigo.
Se a VPS continuar com o ipa_bind.php antigo, a IPA pode continuar liberando TESTE ou qualquer coisa.

Comando rápido para testar a API depois de subir:
curl -s -X POST http://191.252.210.109/api/ipa_bind.php \
  -H 'Content-Type: application/json' \
  -d '{"action":"bind","key":"QUALQUERCOISA"}'

Tem que responder:
KEY_NOT_FOUND

Se responder success true, ainda tem arquivo antigo na VPS.
