#!/bin/bash
if [ -e code.sql ]
then
	rm code.sql sql_content.sql
fi

echo "Creación de Base de datos"
read -p "Nombre de la DB: " database

read -p "Nombre del container: " container
#Datos prueba:

	url=8081
	sitio=sitiox
	mail=sitiox@wp.es
	user=manuel
	nombre=manuel
	hash="2xaDDfiVneFxM8xPZ1jgDjCp9wuos1"

#Creación DB MariaDB

	echo "Create database "$database";" >> code.sql
	echo "GRANT ALL PRIVILEGES ON "$database".* TO 'wordpress'" >> code.sql
	mysql -u root -h 192.168.0.22 -pRootPassXx- < code.sql

#Creación entorno Wordpress

	#Volumen y datos
	docker volume create $container
	cp -r /var/lib/docker/volumes/wp1/_data /var/lib/docker/volumes/$container/_data

	#Container
	docker run -itd --name $container -p 8081:80 -v $container:/var/www/html \
	-e WORDPRESS_DB_HOST=192.168.0.22:3306 -e WORDPRESS_DB_USER=wordpress -e WORDPRESS_DB_PASSWORD=MySQLPassPrueba -e WORDPRESS_DB_NAME=$database \
	wordpress \
	\

#Inserción datos MariaDB

	cat template.sql | sed 's/datos_db/'$database'/g' | sed 's/URL_PAG/'$url'/g' | sed 's/blogname_data/'$sitio'/g' | sed 's/admin_email@wp.es/'$mail'/g' | sed 's/HashContrasena/'$hash'/g' | sed 's/user_login_data/'$user'/g' | sed 's/first_name_data/'$nombre'/g' > sql_content.sql
	mysql -u root -h 192.168.0.22 -pRootPassXx- < sql_content.sql
