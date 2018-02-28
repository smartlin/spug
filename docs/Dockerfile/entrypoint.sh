#!/bin/sh
#
set -e

REQUIRE_INIT_OPS=false

# env check
if [ -z $REGISTRY_SERVER ]; then
    echo 'Please set REGISTRY_SERVER by -e REGISTRY_SERVER=<docker registry server>'
    exit 1
fi

# init db
if [ ! -d /var/lib/mysql/mysql ]; then
    echo 'Initializing db, please wait ...'
    REQUIRE_INIT_OPS=true
    /bin/sh /scripts/init_db.sh
fi

# init nginx
if [ ! -d /run/nginx ]; then
    mkdir -p /run/nginx
    chown -R nginx.nginx /run/nginx
fi

# init config
if [ ! -f /init_config.lock ]; then
    /bin/sh /scripts/init_config.sh
    touch /init_config.lock
fi


cd /spug/spug_api
nginx
nohup /usr/bin/mysqld_safe --datadir=/var/lib/mysql --user=root &
sleep 2
if [ $REQUIRE_INIT_OPS == true ]; then
    /usr/bin/python3 /scripts/init_spug.py
fi 
gunicorn --threads=32 main:app -b 0.0.0.0:3000
