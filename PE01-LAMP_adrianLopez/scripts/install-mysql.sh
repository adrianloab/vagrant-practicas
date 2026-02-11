#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "=== Instalando MySQL Server ==="
apt-get install -y mysql-server

echo "=== Habilitando y arrancando servicio mysql ==="
systemctl enable mysql
systemctl restart mysql

echo "=== Configurando base de datos y usuario ==="
mysql <<EOF
CREATE DATABASE IF NOT EXISTS lamp_db;
CREATE USER IF NOT EXISTS 'lamp_user'@'localhost' IDENTIFIED BY 'lamp_pass';
GRANT ALL PRIVILEGES ON lamp_db.* TO 'lamp_user'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "MySQL instalado y configurado correctamente"

