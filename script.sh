#!/bin/bash

#Inserción de datos en el caso de que no se adjunte ningún csv
function insercion_datos () {

	read -p "Introduzca el número de Wordpress a crear: " num_word
	touch datos.csv
	cont_int=0
	while [[ $cont_int_datos -ne $num_word ]]
	do
		echo "Introduzca los siguientes datos"

		read -p "Nombre de la DB: " database

		read -p "Nombre del Wordpress: " container

		read -p "Nombre del usuario: " user

		read -p "Contraseña: " pass

		read -p "Correo del usuario: " mail

		echo $database";"$container";"$user";"$pass";"$mail >> datos.csv
		let cont_int_datos++
	done

}

function datos_csv (){
	error_cont=0
	for cont_id in `cat datos.csv `
	do
		database=""
		container=""
		user=""
		pass=""
		mail=""


		database=$(echo $cont_id  | awk -F";" '{print $1}');
		container=$(echo $cont_id  | awk -F";" '{print $2}');
		user=$(echo $cont_id  | awk -F";" '{print $1}');
		pass=$(echo $cont_id  | awk -F";" '{print $1}');
		mail=$(echo $cont_id  | awk -F";" '{print $1}');
		sitio=$container
		nombre=$user
		hash=OERdEA9ZeE50cuz3j164kJQ3LUPto1
		# La contraseña en un primer momento será admin, se cambiará más adelante
		url=8083

		let error_cont++
		if [[ $database == "" ]] || [[ $container == "" ]] || [[ $user == "" ]] || [[ $pass == "" ]] || [[ $mail == "" ]]
		then
			echo "Faltan datos"
			echo "Línea: " $error_cont
			if [[ $database == "" ]]
			then
				falta_datos="base datos | "
			fi
			if [[ $container == "" ]]
			then
				falta_datos=$(echo $falta_datos" container | ")
			fi
			if [[ $user == "" ]]
			then
				falta_datos=$(echo $falta_datos" usuario | ")
			fi
			if [[ $pass == "" ]]
			then
				falta_datos=$(echo $falta_datos " contraseña | ")
			fi
			if [[ $mail == "" ]]
			then
				falta_datos=$(echo $falta_datos " email | ")

			fi
			echo "Falta/n el/los dato/s: " $falta_datos
		else
			create_wp
		fi
	done
}

function create_wp {
#Creación DB MariaDB

	echo "Create database "$database";" > code.sql
	echo "GRANT ALL PRIVILEGES ON "$database".* TO 'wordpress'" >> code.sql
	mysql -u root -h 192.168.0.22 -pRootPassXx- < code.sql

#Creación entorno Wordpress

	#Volumen y datos
	docker volume create $container
	cp -r /var/lib/docker/volumes/wp1/_data /var/lib/docker/volumes/$container/_data

	#Container
	docker run -itd --name $container -p $url:80 -v $container:/var/www/html \
	-e WORDPRESS_DB_HOST=192.168.0.22:3306 -e WORDPRESS_DB_USER=wordpress -e WORDPRESS_DB_PASSWORD=MySQLPassPrueba -e WORDPRESS_DB_NAME=$database \
	wordpress \
	\

#Inserción datos MariaDB

	cat template.sql | sed 's/datos_db/'$database'/g' | sed 's/URL_PAG/'$url'/g' | sed 's/blogname_data/'$sitio'/g' | sed 's/admin_email@wp.es/'$mail'/g' | sed 's/HashContrasena/'$hash'/g' | sed 's/user_login_data/'$user'/g' | sed 's/first_name_data/'$nombre'/g' > sql_content.sql
	mysql -u root -h 192.168.0.22 -pRootPassXx- < sql_content.sql

contrasenna_encrypt
}

function contrasenna_encrypt () {

	echo "Use "$database";" > code.sql
	echo "UPDATE (wp_users) SET user_pass = MD5('$pass') WHERE ID = 1;" >> code.sql
	mysql -u root -h 192.168.0.22 -pRootPassXx- < code.sql

}

#Borrado de datos de otras sesiones innecesarios

if [ -e code.sql ]
then
	rm code.sql
fi

if [ -e sql_content.sql ]
then
	rm sql_content.sql
fi

#Checkeo de archivos necesarios

if [ -e template.sql ]
then
	echo "Fichero template.sql cargado"
else
	echo "No se puede encontrar el fichero de template de SQL"
	echo "Contacte con el administrador"
fi


# Consulta de datos

if [ -e datos.csv ]
then
	echo "Se ha encontrado un fichero de datos precargado"
	read -p "¿Desea hacer uso de este? [ SI | NO ] " eleccion_csv
	if [[ $eleccion_csv == "SI" ]] || [[ $eleccion_csv == "si" ]] || [[ $eleccion_csv == "Si" ]] || [[ $eleccion_csv == "sI" ]]
	then
		datos_csv

	elif [[ $eleccion_csv == "NO" ]] || [[ $eleccion_csv == "no" ]] || [[ $eleccion_csv == "No" ]] || [[ $eleccion_csv == "nO" ]]
	then
		echo "Se renombrará el CSV existente a old_datos.csv"
		mv datos.csv old_datos.csv
		echo "Deberá de introducir los datos manualmente"
		insercion_datos
		datos_csv
	else
		echo "Seleccione una de las posibles opciones correctas"
	fi
else
	echo "No se encuentra ningún fichero de datos"
	echo "Deberá de introducir los datos manualmente"

	insercion_datos
	datos_csv
fi
