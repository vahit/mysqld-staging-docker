#!/bin/bash
set -exo pipefail

# defaults value for variables.
EMPTY_DB=${EMPTY_DB:-"TRUE"}
MYSQL_PASSWORD=${MYSQL_ROOT_PASSWORD:-"123456"}
MYSQL_USER=${USER:-"root"}
HOST=${HOST:-"127.0.0.1"}
PORT=${PORT:-"3306"}
ONLY_SCHEMA=${ONLY_SCHEMA:-"FALSE"}
SOURCE_DB_USER=${SOURCE_DB_USER:-"root"}
SOURCE_DB_PASS=${SOURCE_DB_PASS:-"123456"}
SOURCE_DB=${SOURCE_DB:-""}
SOURCE_DB_HOST=${SOURCE_DB_HOST:-""}
DEFAULT_QUERIES=${DEFAULT_QUERIES:-""}
SLEEP_TIME=${SLEEP_TIME:-30}

echo "------- start mysqld ..."
/usr/local/bin/docker-entrypoint.sh mysqld &

echo "------- wait for mysql startup (${SLEEP_TIME} secs)"
sleep ${SLEEP_TIME}
echo "------- mysqld: started."

if [[ ${EMPTY_DB} == "true" || ${EMPTY_DB} == "TRUE" || ${EMPTY_DB} == "True" ]]; then
    echo "------- creating ${SOURCE_DB} DB"
    mysql --protocol=TCP --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --host=${HOST} --port=${PORT} --execute="CREATE DATABASE ${SOURCE_DB};"
    echo "------- ${SOURCE_DB} database created."
else
    if [[ ${ONLY_SCHEMA} == "true" || ${ONLY_SCHEMA} == "TRUE" || ${ONLY_SCHEMA} == "True" ]]; then
        echo "------- export from schematic of production DB, it may be take some minutes ..."
        mysqldump --user=${SOURCE_DB_USER} --password=${SOURCE_DB_PASS} --host=${SOURCE_DB_HOST} --no-data --databases ${SOURCE_DB} --skip-lock-tables --result-file=${SOURCE_DB}-db.sql
    else
        echo "------- export from production DB, it may be take some minutes ..."
        mysqldump --user=${SOURCE_DB_USER} --password=${SOURCE_DB_PASS} --host=${SOURCE_DB_HOST} ${SOURCE_DB} --skip-lock-tables --result-file=${SOURCE_DB}-db.sql
    fi
    echo "------- exporting done."

    echo "------- creating ${SOURCE_DB} DB"
    mysql --protocol=TCP --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --host=${HOST} --port=${PORT} --execute="CREATE DATABASE ${SOURCE_DB};"
    echo "------- ${SOURCE_DB} database created."
    mysql --protocol=TCP --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --host=${HOST} --port=${PORT} --database="${SOURCE_DB}" < ${SOURCE_DB}-db.sql
    echo "------- ${SOURCE_DB} imported."

    rm ./${SOURCE_DB}-db.sql
fi

echo "------- wait until mysqld stop/crush ..."
wait
