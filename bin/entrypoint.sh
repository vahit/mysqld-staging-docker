#!/bin/bash
set -eo pipefail

echo "------- start mysqld ..."
/usr/local/bin/docker-entrypoint.sh mysqld &
sleep 30
echo "------- mysqld: started."

if [[ ${EMPTY_DB} == "true" || ${EMPTY_DB} == "TRUE" || ${EMPTY_DB} == "True" ]]; then
    echo "------- creating ${SOURCE_DB} DB"
    mysql --protocol=TCP --user=root --password=${MYSQL_ROOT_PASSWORD} --host=127.0.0.1 --port=3306 --execute="CREATE DATABASE ${SOURCE_DB};"
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
    mysql --protocol=TCP --user=root --password=${MYSQL_ROOT_PASSWORD} --host=127.0.0.1 --port=3306 --execute="CREATE DATABASE ${SOURCE_DB};"
    echo "------- ${SOURCE_DB} database created."
    mysql --protocol=TCP --user=root --password=${MYSQL_ROOT_PASSWORD} --host=127.0.0.1 --port=3306 --database="${SOURCE_DB}" < ${SOURCE_DB}-db.sql
    echo "------- ${SOURCE_DB} imported."

    rm ./${SOURCE_DB}-db.sql
fi

DEFAULT_QUERY=$(env | grep -i "^default_query")
if [[ ! -z ${DEFAULT_QUERY} ]]; then
    for EACH_QUERY in ${DEFAULT_QUERY}; do
        COMMAND_OUTPUT=$(mysql --protocol=TCP --user=root --password=${MYSQL_ROOT_PASSWORD} --host=127.0.0.1 --port=3306 --execute="${EACH_QUERY}" 2>&1)
        echo "------- Query result"
        echo "${COMMAND_OUTPUT}"
    done

echo "------- wait until mysqld stop/crush ..."
wait
