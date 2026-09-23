#!/usr/bin/env bash
set -euo pipefail

export MYSQL_PWD="${MYSQL_ROOT_PASSWORD:?}"
repl_password="${MYSQL_REPLICATION_PASSWORD:?}"
if [[ ! "$repl_password" =~ ^[A-Za-z0-9._~!@#%+=:-]+$ ]]; then
  echo 'MYSQL_REPLICATION_PASSWORD supports letters, digits and ._~!@#%+=:- only' >&2
  exit 2
fi

for host in mysql-a mysql-b; do
  mysql -h "$host" -uroot <<SQL
SET SQL_LOG_BIN=0;
CREATE USER IF NOT EXISTS 'replicator'@'%' IDENTIFIED BY '${repl_password}';
ALTER USER 'replicator'@'%' IDENTIFIED BY '${repl_password}';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
SET SQL_LOG_BIN=1;
SQL
done

for pair in mysql-a:mysql-b mysql-b:mysql-a; do
  target="${pair%%:*}"
  source="${pair##*:}"
  configured="$(mysql -h "$target" -uroot -Nse "SELECT IFNULL(HOST, '') FROM performance_schema.replication_connection_configuration WHERE CHANNEL_NAME='' LIMIT 1")"
  if [[ -z "$configured" ]]; then
    mysql -h "$target" -uroot <<SQL
CHANGE REPLICATION SOURCE TO SOURCE_HOST='${source}', SOURCE_PORT=3306,
  SOURCE_USER='replicator', SOURCE_PASSWORD='${repl_password}',
  SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY=1;
START REPLICA;
SQL
  elif [[ "$configured" == "$source" ]]; then
    mysql -h "$target" -uroot -e 'START REPLICA;'
  else
    echo "$target is already configured for unexpected source: $configured" >&2
    exit 1
  fi
done

for host in mysql-a mysql-b; do
  for ((attempt = 1; attempt <= 60; attempt++)); do
    status="$(mysql -h "$host" -uroot -e 'SHOW REPLICA STATUS\G')"
    if [[ "$status" == *'Replica_IO_Running: Yes'* && "$status" == *'Replica_SQL_Running: Yes'* ]]; then
      break
    fi
    if ((attempt == 60)); then
      echo "$host replication did not become healthy" >&2
      exit 1
    fi
    sleep 2
  done
done
