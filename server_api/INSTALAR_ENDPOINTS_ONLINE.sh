#!/usr/bin/env bash
set -e
mkdir -p /var/www/html/api
cp -f ipa_bind.php ipa_design.php ipa_ports.php ipa_security.php /var/www/html/api/
chmod 644 /var/www/html/api/ipa_bind.php /var/www/html/api/ipa_design.php /var/www/html/api/ipa_ports.php /var/www/html/api/ipa_security.php
systemctl restart apache2
echo OK_ENDPOINTS_ONLINE
