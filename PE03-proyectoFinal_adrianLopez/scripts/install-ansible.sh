#!/bin/bash
# ============================================================
# Instala Ansible en el nodo master
# Extra: +1.0 puntos - Provisioning con Ansible
# ============================================================
set -e

echo "============================================"
echo "=== Instalando Ansible en el master      ==="
echo "============================================"

export DEBIAN_FRONTEND=noninteractive

# Instalar Ansible desde el PPA oficial
apt-get install -y software-properties-common
apt-add-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

# Verificar instalación
ansible --version

# Configurar Ansible para no verificar host keys SSH
cat > /etc/ansible/ansible.cfg <<EOF
[defaults]
host_key_checking = False
timeout = 30
retry_files_enabled = False
stdout_callback = yaml

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
pipelining = True
EOF

echo "=== Ansible instalado correctamente ==="
