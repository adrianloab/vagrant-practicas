#!/bin/bash
set -e

echo "=== Instalando Apache ==="

apt-get install -y apache2

echo "=== Habilitando módulos de Apache ==="
a2enmod rewrite
a2enmod ssl

echo "=== Habilitando y arrancando servicio apache2 ==="
systemctl enable apache2
systemctl restart apache2

echo "Apache instalado y configurado correctamente"

