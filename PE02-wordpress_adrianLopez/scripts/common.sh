 #!/bin/bash
 set -e

 echo "=== Configuración común ==="

 # Actualizar índice de paquetes
 apt-get update -y

 # Instalar utilidades básicas
 apt-get install -y vim curl wget net-tools mysql-client

# Configurar /etc/hosts para resolución de nombres entre VMs
# Se añaden las entradas de forma idempotente
if ! grep -q "192.168.56.10 web-server" /etc/hosts; then
  echo "192.168.56.10 web-server" >> /etc/hosts
fi
if ! grep -q "192.168.56.20 db-server" /etc/hosts; then
  echo "192.168.56.20 db-server" >> /etc/hosts
fi

 # Configurar zona horaria
 timedatectl set-timezone Europe/Madrid || true

 echo "=== Configuración común completada ==="


