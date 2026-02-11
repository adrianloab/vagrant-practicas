#!/bin/bash
set -e

echo "=== Configurando virtual host personalizado para Apache ==="

VHOST_CONF="/etc/apache2/sites-available/lamp.conf"

cat > "$VHOST_CONF" <<'EOF'
<VirtualHost *:80>
    ServerName lamp.local
    ServerAdmin webmaster@localhost

    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/lamp_error.log
    CustomLog \${APACHE_LOG_DIR}/lamp_access.log combined
</VirtualHost>
EOF

echo "=== Deshabilitando sitio por defecto y habilitando lamp.conf ==="
a2dissite 000-default.conf || true
a2ensite lamp.conf

echo "=== Recargando Apache ==="
systemctl reload apache2

echo "Virtual host personalizado configurado correctamente (ServerName lamp.local)"

