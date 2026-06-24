CORREÇÕES INCLUÍDAS

1) Endpoint online para tema do gerador:
   /api/app_design.php
   /api/app_config.php
   /api/config.php

2) Cores/botões/fundo online:
   - primary
   - secondary
   - button_gradient_1
   - button_gradient_2
   - card_bg
   - card_border
   - text_primary
   - text_secondary

3) Keys separadas por vendedor:
   A IPA agora chama keys.php com username salvo.
   Exemplo: /api/keys.php?username=calvoios07

4) Pesquisa de key:
   Campo "Pesquisar key" na tela Keys.
   Backend também aceita: /api/keys.php?username=USUARIO&q=ADMIN

5) Resetar key:
   Botão resetar nas keys selecionadas.
   Endpoint: /api/reset_keys.php
   Remove IP/dispositivo/sessão, mas mantém activated_at/expires_at.
   Assim não zera os dias.

6) Dispositivos:
   Aba Dispositivos agora mostra keys usadas, IP/dispositivo, ativação e vencimento.

7) Duração corrigida:
   Hora aparece como hora, dia aparece como dia.
   A key gerada fica sem expires_at até o cliente ativar na IPA Proxy.

8) Keys vencidas destacadas:
   As keys expired aparecem em vermelho e com status Expired.

COMANDOS servidor

Copie a pasta backend/api/* para /var/www/html/api/
Depois reinicie o servidor web:

- Se for nginx:
systemctl restart nginx

- Se for apache:
systemctl restart apache2

TESTES

curl http://191.252.210.109/api/app_design.php
curl "http://191.252.210.109/api/keys.php?username=calvoios07"
curl "http://191.252.210.109/api/keys.php?username=calvoios07&q=ADMIN"
