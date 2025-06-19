#!/usr/bin/env bash
[[ -f mailcow.conf ]] && source mailcow.conf
[[ -f ../mailcow.conf ]] && source ../mailcow.conf

if [[ -z ${DBUSER} ]] || [[ -z ${DBPASS} ]] || [[ -z ${DBNAME} ]] || [[ -z ${MAILCOW_ADMIN_PASSWORD} ]]; then
	echo "Cannot find/read mailcow.conf or required variables are missing, make sure this script is run from within the mailcow folder and all values are set."
	exit 1
fi

echo -n "Checking MySQL service... "
if [[ -z $(docker ps -qf name=mysql-mailcow) ]]; then
	echo "failed"
	echo "MySQL (mysql-mailcow) is not up and running, exiting..."
	exit 1
fi

echo "OK"
echo -e "\nWorking, please wait..."
password=$(docker exec -it $(docker ps -qf name=dovecot-mailcow) doveadm pw -s SSHA256 -p "${MAILCOW_ADMIN_PASSWORD}" | tr -d '\r')
docker exec -it $(docker ps -qf name=mysql-mailcow) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "DELETE FROM admin WHERE username='admin';"
docker exec -it $(docker ps -qf name=mysql-mailcow) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "DELETE FROM domain_admins WHERE username='admin';"
docker exec -it $(docker ps -qf name=mysql-mailcow) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO admin (username, password, superadmin, active) VALUES ('admin', '${password}', 1, 1);"
docker exec -it $(docker ps -qf name=mysql-mailcow) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "DELETE FROM tfa WHERE username='admin';"
echo "
Reset credentials:
---
Username: admin
Password: ${MAILCOW_ADMIN_PASSWORD}
TFA: none
"