#!/bin/bash
set -e

echo "=== Instalando PHP y extensiones ==="

apt-get install -y \
  php \
  libapache2-mod-php \
  php-mysql \
  php-curl \
  php-gd \
  php-mbstring \
  php-xml \
  php-cli

echo "=== Reiniciando Apache para cargar PHP ==="
systemctl restart apache2

echo "PHP y extensiones instaladas correctamente"

