#!/usr/bin/env bash
set -euo pipefail

app_password="${MYSQL_APP_PASSWORD:?}"
if [[ ! "$app_password" =~ ^[A-Za-z0-9._~!@#%+=:-]+$ ]]; then
  echo 'MYSQL_APP_PASSWORD supports letters, digits and ._~!@#%+=:- only' >&2
  exit 2
fi

export MYSQL_PWD=Admin123
ready=false
for ((attempt = 1; attempt <= 60; attempt++)); do
  if mysql --protocol=tcp -h proxysql -P6032 -u ops -Nse 'SELECT 1' >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done
if [[ "$ready" != true ]]; then
  echo 'ProxySQL admin interface did not become ready' >&2
  exit 1
fi

mysql --protocol=tcp -h proxysql -P6032 -u ops <<SQL
DELETE FROM mysql_query_rules WHERE rule_id IN (10, 20);
DELETE FROM mysql_replication_hostgroups WHERE writer_hostgroup=10 OR reader_hostgroup=20;
DELETE FROM mysql_servers WHERE hostgroup_id IN (10, 20);
INSERT INTO mysql_servers(hostgroup_id,hostname,port) VALUES (10,'mysql-primary',3306),(20,'mysql-replica',3306);
INSERT INTO mysql_replication_hostgroups(writer_hostgroup,reader_hostgroup,comment) VALUES (10,20,'container-play async replication');
DELETE FROM mysql_users WHERE username='demo';
INSERT INTO mysql_users(username,password,default_hostgroup,active) VALUES ('demo','${app_password}',10,1);
INSERT INTO mysql_query_rules(rule_id,active,match_digest,destination_hostgroup,apply) VALUES
  (10,1,'^SELECT.*FOR UPDATE',10,1),
  (20,1,'^SELECT',20,1);
UPDATE global_variables SET variable_value='monitor' WHERE variable_name='mysql-monitor_username';
UPDATE global_variables SET variable_value='${app_password}' WHERE variable_name='mysql-monitor_password';
LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;
SAVE MYSQL VARIABLES TO DISK;
SQL
