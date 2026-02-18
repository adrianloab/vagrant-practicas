 #!/bin/bash
 set -e

 echo "=== Configurando WordPress ==="

 cd /var/www/html

 # Crear wp-config.php a partir del de ejemplo
 if [ ! -f wp-config.php ]; then
   cp wp-config-sample.php wp-config.php
 fi

 # Comprobar variables de entorno requeridas
 : "${DB_HOST:?DB_HOST no definido}"
 : "${DB_NAME:?DB_NAME no definido}"
 : "${DB_USER:?DB_USER no definido}"
 : "${DB_PASS:?DB_PASS no definido}"

 echo "=== Configurando credenciales de base de datos en wp-config.php ==="
 sed -i "s/database_name_here/$DB_NAME/" wp-config.php
 sed -i "s/username_here/$DB_USER/" wp-config.php
 sed -i "s/password_here/$DB_PASS/" wp-config.php
 sed -i "s/localhost/$DB_HOST/" wp-config.php

 echo "=== Generando claves SALT de seguridad ==="
 SALT_KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

 if [ -n "$SALT_KEYS" ]; then
   # Eliminar definiciones anteriores de claves si existen
   sed -i "/AUTH_KEY/d" wp-config.php
   sed -i "/SECURE_AUTH_KEY/d" wp-config.php
   sed -i "/LOGGED_IN_KEY/d" wp-config.php
   sed -i "/NONCE_KEY/d" wp-config.php
   sed -i "/AUTH_SALT/d" wp-config.php
   sed -i "/SECURE_AUTH_SALT/d" wp-config.php
   sed -i "/LOGGED_IN_SALT/d" wp-config.php
   sed -i "/NONCE_SALT/d" wp-config.php

   # Añadir nuevas claves al final del fichero
   printf "\n%s\n" "$SALT_KEYS" >> wp-config.php
 else
   echo "No se pudieron obtener claves SALT desde WordPress.org"
 fi

 echo "=== Añadiendo configuración adicional a wp-config.php ==="
 cat >> wp-config.php <<'EOF'
 /* Configuración adicional */
 define('WP_DEBUG', false);
 define('WP_AUTO_UPDATE_CORE', false);
 define('DISALLOW_FILE_EDIT', true);
 /* Dirección del sitio */
 define('WP_SITEURL', 'http://192.168.56.10');
 define('WP_HOME', 'http://192.168.56.10');
 EOF

 # Verificar conexión a base de datos
 echo "=== Verificando conexión a base de datos desde PHP ==="
 php -r "
 try {
   \$pdo = new PDO('mysql:host=${DB_HOST};dbname=${DB_NAME}', '${DB_USER}', '${DB_PASS}');
   echo 'Conexión a BD exitosa!';
 } catch (PDOException \$e) {
   echo 'Error: ' . \$e->getMessage();
   exit(1);
 }
 "

 chown www-data:www-data wp-config.php

 echo "=== WordPress configurado correctamente ==="
 echo ""
 echo "Accede a: http://localhost:8080"
 echo "O directamente: http://192.168.56.10"

