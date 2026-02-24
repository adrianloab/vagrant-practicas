#!/bin/bash
# ============================================================
# Ejecuta los playbooks de Ansible desde el nodo master
# Configura el cluster k3s completo
# ============================================================
set -e

echo "============================================"
echo "=== Ejecutando Ansible Playbooks         ==="
echo "============================================"

# Crear inventario dinámico de Ansible
cat > /tmp/inventory.ini <<EOF
[master]
${MASTER_IP} ansible_connection=local

[workers]
${WORKER1_IP} ansible_user=vagrant ansible_password=vagrant ansible_become=yes ansible_ssh_common_args='-o PubkeyAuthentication=no'
${WORKER2_IP} ansible_user=vagrant ansible_password=vagrant ansible_become=yes ansible_ssh_common_args='-o PubkeyAuthentication=no'

[k3s_cluster:children]
master
workers
EOF

echo ">>> Inventario creado:"
cat /tmp/inventory.ini

# Ejecutar el playbook principal
echo ">>> Ejecutando playbook principal..."
cd /vagrant/ansible
ansible-playbook -i /tmp/inventory.ini site.yml -v

echo "============================================"
echo "=== Ansible Playbooks completados        ==="
echo "============================================"
