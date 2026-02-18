 #!/bin/bash
 set -e

 export DEBIAN_FRONTEND=noninteractive

 echo "=== Instalando MySQL ==="
 apt-get install -y mysql-server

echo "=== Configurando MySQL para acceso remoto ==="
# Cambiar bind-address a 0.0.0.0 para aceptar conexiones externas (robusto ante espacios)
if grep -q "bind-address" /etc/mysql/mysql.conf.d/mysqld.cnf; then
  sed -i "s/^[[:space:]]*bind-address[[:space:]]*=.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
else
  echo "bind-address = 0.0.0.0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
fi

 systemctl restart mysql

 echo "=== Creando base de datos y usuario ==="
 mysql <<EOF
 -- Crear base de datos
 CREATE DATABASE IF NOT EXISTS wordpress_db
   DEFAULT CHARACTER SET utf8mb4
   COLLATE utf8mb4_unicode_ci;

 -- Crear usuario con acceso desde red privada
 CREATE USER IF NOT EXISTS 'wp_user'@'192.168.56.%' IDENTIFIED BY 'wp_secure_pass';

 -- Otorgar permisos
 GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wp_user'@'192.168.56.%';

 -- Asegurar que no hay accesos root remotos
 DELETE FROM mysql.user WHERE User = 'root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

 FLUSH PRIVILEGES;

 -- Verificar
 SHOW DATABASES;
 SELECT User, Host FROM mysql.user;
 EOF

 echo "=== MySQL configurado correctamente ==="
 echo "Base de datos: wordpress_db"
 echo "Usuario: wp_user (acceso desde 192.168.56.%)"

