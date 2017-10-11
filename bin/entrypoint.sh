#!/bin/bash
set -eo pipefail

echo "------- start mysqld ..."
/usr/local/bin/docker-entrypoint.sh mysqld &
sleep 30
echo "------- mysqld: started."

echo "------- export from production DB, it may be take some minutes ..."
mysqldump --user=$SOURCE_DB_USER --password=$SOURCE_DB_PASS --host=$SOURCE_DB_HOST $SOURCE_DB --skip-lock-tables --result-file=${SOURCE_DB}-db.sql
echo "------- exporting done."

echo "------- trying to import DB"
mysql --protocol=TCP --user=root --password=$MYSQL_ROOT_PASSWORD --host=127.0.0.1 --port=3306 --execute="CREATE DATABASE jabeh;"
mysql --protocol=TCP --user=root --password=$MYSQL_ROOT_PASSWORD --host=127.0.0.1 --port=3306 --database=jabeh < ${SOURCE_DB}-db.sql
echo "------- importing done."

rm ./${SOURCE_DB}-db.sql

echo "------- killall mysqld"
killall mysqld
sleep 10
echo "------- and run it agian"
/usr/local/bin/docker-entrypoint.sh mysqld
