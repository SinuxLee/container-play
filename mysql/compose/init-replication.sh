#!/usr/bin/env bash
set -euo pipefail

export MYSQL_PWD="${MYSQL_ROOT_PASSWORD:?}"
repl_password="${MYSQL_REPLICATION_PASSWORD:?}"
if [[ ! "$repl_password" =~ ^[A-Za-z0-9._~!@#%+=:-]+$ ]]; then
  echo 'MYSQL_REPLICATION_PASSWORD supports letters, digits and ._~!@#%+=:- only' >&2
  exit 2
fi

mysql -h mysql-primary -uroot <<SQL
SET SQL_LOG_BIN=0;
CREATE USER IF NOT EXISTS 'replicator'@'%' IDENTIFIED BY '${repl_password}';
ALTER USER 'replicator'@'%' IDENTIFIED BY '${repl_password}';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
SET SQL_LOG_BIN=1;
SQL

source_host="$(mysql -h mysql-replica -uroot -Nse "SELECT IFNULL(HOST, '') FROM performance_schema.replication_connection_configuration WHERE CHANNEL_NAME='' LIMIT 1")"
if [[ -z "$source_host" ]]; then
  mysql -h mysql-replica -uroot <<SQL
CHANGE REPLICATION SOURCE TO SOURCE_HOST='mysql-primary', SOURCE_PORT=3306,
  SOURCE_USER='replicator', SOURCE_PASSWORD='${repl_password}',
  SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY=1;
START REPLICA;
SQL
elif [[ "$source_host" == mysql-primary ]]; then
  mysql -h mysql-replica -uroot -e 'START REPLICA;'
else
  echo "Replica is already configured for unexpected source: $source_host" >&2
  exit 1
fi

for ((attempt = 1; attempt <= 60; attempt++)); do
  status="$(mysql -h mysql-replica -uroot -e 'SHOW REPLICA STATUS\G')"
  if [[ "$status" == *'Replica_IO_Running: Yes'* && "$status" == *'Replica_SQL_Running: Yes'* ]]; then
    break
  fi
  if ((attempt == 60)); then
    echo 'MySQL replica did not become healthy' >&2
    exit 1
  fi
  sleep 2
done

if [[ "${MYSQL_CONFIGURE_PROXY:-false}" == true ]]; then
  app_password="${MYSQL_APP_PASSWORD:?}"
  if [[ ! "$app_password" =~ ^[A-Za-z0-9._~!@#%+=:-]+$ ]]; then
    echo 'MYSQL_APP_PASSWORD supports letters, digits and ._~!@#%+=:- only' >&2
    exit 2
  fi
  mysql -h mysql-primary -uroot <<SQL
CREATE DATABASE IF NOT EXISTS demo;
CREATE USER IF NOT EXISTS 'demo'@'%' IDENTIFIED WITH mysql_native_password BY '${app_password}';
ALTER USER 'demo'@'%' IDENTIFIED WITH mysql_native_password BY '${app_password}';
GRANT ALL PRIVILEGES ON demo.* TO 'demo'@'%';
CREATE USER IF NOT EXISTS 'monitor'@'%' IDENTIFIED WITH mysql_native_password BY '${app_password}';
ALTER USER 'monitor'@'%' IDENTIFIED WITH mysql_native_password BY '${app_password}';
GRANT USAGE, REPLICATION CLIENT ON *.* TO 'monitor'@'%';
SQL
fi
