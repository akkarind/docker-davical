#!/bin/bash

#SET THE TIMEZONE
apk add --update tzdata
cp /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
echo $TIME_ZONE > /etc/timezone

set -e

# Handle provided certificate files or create self signed certificate
mkdir -p /etc/lighttpd/ssl/
if [ -f /usr/local/share/certdata/$CERT_FILE ] && [ -f /usr/local/share/certdata/$PRIV_FILE ]
	then
		cat /usr/local/share/certdata/$CERT_FILE /usr/local/share/certdata/$PRIV_FILE > /etc/lighttpd/ssl/localhost.pem 
		cp /usr/local/share/certdata/$CERT_FILE /etc/lighttpd/ssl/$CERT_FILE
		cp /usr/local/share/certdata/$PRIV_FILE /etc/lighttpd/ssl/$PRIV_FILE
		cp /usr/local/share/certdata/$CHAIN_FILE /etc/lighttpd/ssl/$CHAIN_FILE
		chmod 400 /etc/lighttpd/ssl/*.pem
elif [ ! -f /etc/lighttpd/ssl/localhost.pem ]
	then
		openssl req -x509 -newkey rsa:4096 -keyout /tmp/key.pem -out /tmp/cert.pem -days 365 -subj '/CN=localhost' -nodes -sha256
		cat /tmp/key.pem /tmp/cert.pem > /etc/lighttpd/ssl/localhost.pem
		rm /tmp/key.pem /tmp/cert.pem
		chmod 400 /etc/lighttpd/ssl/localhost.pem
fi

#PREPARE THE PERMISSIONS FOR VOLUMES
mkdir 	-p /config
chown -R root:root /config
chmod -R 755 /config
mv -n	/davical.php /config/davical.php
mv -n	/supervisord.conf /config/supervisord.conf
mv -n	/rsyslog.conf /config/rsyslog.conf
chown -R root:root /config
chmod -R 755 /config
chown root:lighttpd /config/davical.php
chmod u+rwx,g+rx /config/davical.php

#SET THE DATABASE ONLY AT THE FIRST RUN
chown -R postgres:postgres /var/lib/postgresql
if [ ! -e /var/lib/postgresql/data/pg_hba.conf ]; then
	su - postgres -c "initdb -D data"
	echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf
	echo "log_destination = 'syslog'" >> /var/lib/postgresql/data/postgresql.conf
	echo "syslog_facility = 'LOCAL1'" >> /var/lib/postgresql/data/postgresql.conf
	echo "timezone = $TIME_ZONE" >> /var/lib/postgresql/data/postgresql.conf
	sed -i "/# Put your actual configuration here/a local   davical    davical_app   trust\nlocal   davical    davical_dba   trust" /var/lib/postgresql/data/pg_hba.conf
	mkdir /var/lib/postgresql/data/backups
	chown -R postgres:postgres /var/lib/postgresql/data/backups
fi

set -x
#LAUNCH THE INIT PROCESS
exec /usr/bin/supervisord

