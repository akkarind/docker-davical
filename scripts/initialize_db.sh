#!/usr/bin/env bash

#CHECK IF THE DAVICAL DATABASE EXISTS, OTHERWISE INITIALIZE IT
INITIALIZED_DB=$(su postgres -c "psql -l" | grep -c davical)
if [[ $INITIALIZED_DB == 0 ]]; then
	su postgres -c '/var/www/davical/dba/create-database.sh davical d4v1c4l'
fi
unset INITIALIZED_DB

#UPDATE ALWAYS THE DATABASE
/var/www/davical/dba/update-davical-database

