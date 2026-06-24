#!/usr/bin/env bash
set -e
mkdir -p /var/www/html/api
mkdir -p /var/www/proxybrasil2026.io.vn/data/IPA
cp server_api/ipa_bind.php /var/www/html/api/ipa_bind.php
cp server_api/ipa_admin_config.php /var/www/html/api/ipa_admin_config.php
cp server_api/ipa_config.json /var/www/proxybrasil2026.io.vn/data/IPA/ipa_config.json
# Se tiver o certificado antigo da VPS em /root/.mitmproxy, publica para o iPhone baixar.
if [ -f /root/.mitmproxy/mitmproxy-ca-cert.cer ]; then
  cp /root/.mitmproxy/mitmproxy-ca-cert.cer /var/www/html/proxy2026.der
fi
chown -R www-data:www-data /var/www/proxybrasil2026.io.vn/data /var/www/html/api || true
chmod -R 775 /var/www/proxybrasil2026.io.vn/data || true
chmod 644 /var/www/html/api/*.php /var/www/html/proxy2026.der 2>/dev/null || true
systemctl reload nginx 2>/dev/null || systemctl restart nginx 2>/dev/null || true
echo OK
