#!/bin/bash
# ============================================================
# Script común para todas las VMs del cluster k3s
# Prepara el sistema base antes de la configuración con Ansible
# ============================================================
set -e

echo "============================================"
echo "=== Configuración común del nodo         ==="
echo "============================================"

export DEBIAN_FRONTEND=noninteractive

# ----------------------------------------------------------
# 1. Actualizar índice de paquetes
# ----------------------------------------------------------
echo ">>> Actualizando índice de paquetes..."
apt-get update -y

# ----------------------------------------------------------
# 2. Instalar utilidades básicas
# ----------------------------------------------------------
echo ">>> Instalando utilidades básicas..."
apt-get install -y \
  vim \
  curl \
  wget \
  net-tools \
  apt-transport-https \
  ca-certificates \
  software-properties-common \
  gnupg2 \
  sshpass \
  jq

# ----------------------------------------------------------
# 3. Configurar /etc/hosts para resolución entre VMs
#    (idempotente: solo añade si no existe)
# ----------------------------------------------------------
echo ">>> Configurando /etc/hosts..."
if ! grep -q "${MASTER_IP} master" /etc/hosts; then
  echo "${MASTER_IP} master" >> /etc/hosts
fi
if ! grep -q "${WORKER1_IP} worker1" /etc/hosts; then
  echo "${WORKER1_IP} worker1" >> /etc/hosts
fi
if ! grep -q "${WORKER2_IP} worker2" /etc/hosts; then
  echo "${WORKER2_IP} worker2" >> /etc/hosts
fi

# ----------------------------------------------------------
# 4. Configurar zona horaria
# ----------------------------------------------------------
echo ">>> Configurando zona horaria..."
timedatectl set-timezone Europe/Madrid || true

# ----------------------------------------------------------
# 5. Deshabilitar swap (requerido por Kubernetes)
# ----------------------------------------------------------
echo ">>> Deshabilitando swap..."
swapoff -a
# Comentar la línea de swap en /etc/fstab para que no se active al reiniciar
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# ----------------------------------------------------------
# 6. Configurar módulos del kernel necesarios para k3s
# ----------------------------------------------------------
echo ">>> Cargando módulos del kernel..."
modprobe br_netfilter
modprobe overlay

cat > /etc/modules-load.d/k3s.conf <<EOF
br_netfilter
overlay
EOF

# ----------------------------------------------------------
# 7. Configurar parámetros de red del kernel (sysctl)
# ----------------------------------------------------------
echo ">>> Configurando parámetros de red del kernel..."
cat > /etc/sysctl.d/k3s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# ----------------------------------------------------------
# 8. Habilitar autenticación por contraseña SSH (para Ansible)
# ----------------------------------------------------------
echo ">>> Configurando SSH para Ansible..."
# -------------------------------------------------------
# IMPORTANTE: ubuntu/focal64 (cloud image) incluye archivos en
# /etc/ssh/sshd_config.d/ que SOBREESCRIBEN sshd_config.
# El archivo 60-cloudimg-settings.conf suele traer:
#   PasswordAuthentication no
# Hay que eliminar esa directiva para que nuestra config funcione.
# -------------------------------------------------------

# 1. Eliminar cualquier override de PasswordAuthentication en sshd_config.d
if [ -d /etc/ssh/sshd_config.d ]; then
  for f in /etc/ssh/sshd_config.d/*.conf; do
    [ -f "$f" ] && sed -i 's/^PasswordAuthentication no/#PasswordAuthentication no/' "$f"
  done
  # Crear nuestro propio override con máxima prioridad
  echo 'PasswordAuthentication yes' > /etc/ssh/sshd_config.d/99-allow-password.conf
fi

# 2. Configurar el fichero principal sshd_config
sed -i 's/^[#[:space:]]*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^[#[:space:]]*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
grep -q '^PasswordAuthentication' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
grep -q '^PermitRootLogin' /etc/ssh/sshd_config || echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# 3. Reiniciar SSH para aplicar cambios
systemctl restart sshd

# 4. Verificar que PasswordAuthentication está activo
echo ">>> Verificando SSH PasswordAuthentication..."
sshd -T 2>/dev/null | grep -i passwordauthentication || echo "(no se pudo verificar sshd -T)"

# Establecer contraseña para el usuario vagrant (para Ansible)
echo "vagrant:vagrant" | chpasswd

echo "============================================"
echo "=== Configuración común completada       ==="
echo "============================================"
