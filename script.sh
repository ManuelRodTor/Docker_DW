#!/bin/bash

#Inserción de datos en el caso de que no se adjunte ningún csv
function insercion_datos () {

	read -p "Introduzca el número de Wordpress a crear: " num_word
	touch datos.csv
	cont_int_datos=0
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
	generate_port
	cont_datos_csv=0

#			if [ $num_word -eq $cont_datos_csv ]
#			then
#				break
#			fi

			for cont_id in `cat datos.csv `
			do

				database=$(echo $cont_id  | awk -F";" '{print $1}');
				container=$(echo $cont_id  | awk -F";" '{print $2}');
				user=$(echo $cont_id  | awk -F";" '{print $3}');
				pass=$(echo $cont_id  | awk -F";" '{print $4}');
				mail=$(echo $cont_id  | awk -F";" '{print $5}');
				sitio=$container
				nombre=$user
				hash=OERdEA9ZeE50cuz3j164kJQ3LUPto1
				# La contraseña en un primer momento será admin, se cambiará más adelante
				let error_cont++
				#Este contador me sirve para lleavr un recuento del numero del container a crear
				url=$(cat puertos_libres | cut -f $error_cont -d";" | sed 's/ //g')
				funciona=0
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
					echo a
					funciona=1
					# Si funciona=1 --> Todo BN
					# Si funciona=0 --> No funciona
				fi
			done
			let cont_datos_csv++
			if [ $funciona -eq 1 ]
			then
				create_wp
			fi
}

function generate_port() {

	if [ -e /tmp/puertos_uso ]
	then
		rm /tmp/puertos_uso
	fi
	if [ -e /tmp/containers_name ]
	then
		rm /tmp/containers_name
	fi
	if [ -e /tmp/puertos_limpios  ]
	then
		rm /tmp/puertos_limpios
	fi
		docker ps -a | sed 's/ \{1,\}/ /g' >> /tmp/containers_name
		sed -i 1d /tmp/containers_name
		for containers_row in `sed 's/ /;/g' /tmp/containers_name`
		do
			container_name=$(echo $containers_row | rev | cut -d';' -f 1 | rev)
			for list_ports in `docker port $container_name | rev | cut -d':' -f 1 | rev`
			do
				if [ $list_ports -gt 8079 ] && [ $list_ports -lt 8201 ]
				then
					echo $list_ports >> /tmp/puertos_uso

				fi
			done
		done
	for posible_puerto in `seq 8080 8200`
	do
		echo $posible_puerto >> /tmp/puertos_uso
	done
	cat /tmp/puertos_uso | sort > /tmp/puertos_uso_ord
	rm /tmp/puertos_uso
	cat /tmp/puertos_uso_ord | sort > /tmp/puertos_uso
	rm /tmp/puertos_uso_ord

	if [ -e puertos_libres  ]
	then
		rm puertos_libres
	fi
		repeticiones_dup=$(cat /tmp/puertos_uso | uniq -d | wc -l |  cut -f "1" -d" " )
		cont_rep_dup=0
			cat /tmp/puertos_uso > /tmp/puertos_limpios
			for dup in $(cat /tmp/puertos_uso | uniq -d)
			do
				sed 's/'$dup'/--/' < /tmp/puertos_limpios > /tmp/puertos_xx
				rm /tmp/puertos_limpios
				cat /tmp/puertos_xx > /tmp/puertos_limpios
				rm /tmp/puertos_xx
			done
			#let cont_rep_dup++



	for puertos_libres_var in `cat /tmp/puertos_limpios `

	do
		if [[ ! $puertos_libres_var == "--" ]]
		then
			echo $puertos_libres_var | tr '\n' ';'  >> puertos_libres
		fi
	done
}
function limpiar(){

	for dup in $(cat /tmp/puertos_uso | uniq -d)
	do
		sed 's/'$dup'/--/' /tmp/puertos_uso | tr -s '\n'  > /tmp/puertos_limpios
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
		num_word=$(wc -l datos.csv | cut -f "1" -d" " | sed 's/ //g')
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
		generate_port
	fi
else
	echo "No se encuentra ningún fichero de datos"
	echo "Deberá de introducir los datos manualmente"

	insercion_datos
	datos_csv
fi
