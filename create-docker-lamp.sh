#!/bin/bash

# Creating a directory structure
mkdir -p docker/nginx
mkdir -p docker/php
mkdir -p env
mkdir -p logs/nginx
mkdir -p src

# default.conf
echo "# docker/nginx/default.conf
server {
	listen 80;
	index index.php index.htm index.html;

	root /var/www/html;

	error_log  /var/log/nginx/error.log;
	access_log /var/log/nginx/access.log;

	location ~ \.php$ {
		try_files \$uri =404;
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass php:9000;
		fastcgi_index index.php;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		fastcgi_param PATH_INFO \$fastcgi_path_info;
	}
}" > docker/nginx/default.conf

# Dockerfile for nginx
echo "# docker/nginx/Dockerfile
FROM nginx:1.23

ADD default.conf /etc/nginx/conf.d/default.conf" > docker/nginx/Dockerfile

# Dockerfile for php
echo "# docker/php/Dockerfile
FROM php:8.2-fpm

RUN apt-get update
RUN docker-php-ext-install pdo pdo_mysql mysqli" > docker/php/Dockerfile

# mysql.env
echo "MYSQL_HOSTNAME=mysql
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=helloworld
MYSQL_USER=helloworld
MYSQL_PASSWORD=helloworldpassword" > env/mysql.env

# index.php
echo "# src/index.php
<?php
echo phpinfo();" > src/index.php

# mysqlinfo.php
echo "# src/mysql.php
<?php
\$hostname	= \"mysql\";
\$dbname		= \"helloworld\";
\$username	= \"helloworld\";
\$password	= \"helloworldpassword\";

try {
	\$conn = new PDO( \"mysql:host=\$hostname;dbname=\$dbname\", \$username, \$password );

	// Configure PDO error mode
	\$conn->setAttribute( PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION );

	echo \"Connected successfully\";
}
catch( PDOException \$e ) {
	echo \"Failed to connect: \" . \$e->getMessage();
}

// Perform database operations

// Close the connection
\$conn = null;" > src/mysql.php

# docker-compose.yml
echo "# docker-compose.yml
version: \"v2.20.2-desktop.1\"
services:
  nginx:
    container_name: nginx
    build: ./docker/nginx
    command: nginx -g \"daemon off;\"
    links:
      - php
    ports:
      - \"80:80\"
    volumes:
      - ./logs/nginx:/var/log/nginx
      - ./src:/var/www/html
  php:
    container_name: php
    build: ./docker/php
    links:
      - mysql
    ports:
      - \"9000:9000\"
    volumes:
      - ./src:/var/www/html
    working_dir: /var/www/html
  mysql:
    image: mysql:8.0.32
    container_name: mysql
    env_file:
      - ./env/mysql.env
    ports:
      - \"3306:3306\"
    volumes:
      - ./database/mysql:/var/lib/mysql
    command: '--default-authentication-plugin=mysql_native_password'
  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: pma
    links:
      - mysql
    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
      PMA_ARBITRARY: 1
    restart: always
    ports:
      - 8085:80" > docker-compose.yml

# Readme.md
echo "Script by Marbosoft

1. Run script
./create-docker-lamp.sh

2. Build Docker env
docker-compose build

3. Docker up
docker-compose up

4. Make sure the environment is raised regularly on http://localhost/

5. Check if mysql can be accessed from PHP on http://localhost/mysql.php

6. Delete all files from src directory

7. Download and extract Wordpress to src directory

5. Rename wp-config-sample.php to wp-config.php and change
<?php
....
....
define( 'DB_NAME', 'helloworld' );

/** Database username */
define( 'DB_USER', 'helloworld' );

/** Database password */
define( 'DB_PASSWORD', 'helloworldpassword' );

/** Database hostname */
define( 'DB_HOST', 'mysql' );
....
....

6. Also add following lines:
....
....
/* Add any custom values between this line and the \"stop editing\" line. */

define( 'FS_METHOD', 'direct' );
define( 'UPLOADS', 'wp-content/uploads' );

/* That's all, stop editing! Happy publishing. */
....
....

7. Change permissions
sudo chown -R www-data:www-data <path to src>/wp-content

8. Open Wordpress installation on http://localhost/

9. Install Wordpress

10. PHPMyAdmin address: http://localhost:8085/

11. To stop the docker click on CTRL + C; If you are a docker starter with docker-compose up -d, then use command docker-compose down

...
Enjoy the programming.

Bojan Marković
^^^^^^^^^^^^^^
Your Marbosoft" > Readme.md