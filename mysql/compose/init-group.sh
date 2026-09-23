#!/usr/bin/env bash
set -euo pipefail

export MYSQL_PWD="${MYSQL_ROOT_PASSWORD:?}"
repl_password="${MYSQL_REPLICATION_PASSWORD:?}"
if [[ ! "$repl_password" =~ ^[A-Za-z0-9._~!@#%+=:-]+$ ]]; then
  echo 'MYSQL_REPLICATION_PASSWORD supports letters, digits and ._~!@#%+=:- only' >&2
  exit 2
fi

for host in mysql-gr1 mysql-gr2 mysql-gr3; do
  if [[ "$(mysql -h "$host" -uroot -Nse "SELECT COUNT(*) FROM performance_schema.replication_group_members WHERE MEMBER_STATE='ONLINE' AND MEMBER_ID=@@server_uuid")" == 1 ]]; then
    continue
  fi
  mysql -h "$host" -uroot <<SQL
SET SQL_LOG_BIN=0;
CREATE USER IF NOT EXISTS 'replicator'@'%' IDENTIFIED BY '${repl_password}';
ALTER USER 'replicator'@'%' IDENTIFIED BY '${repl_password}';
GRANT REPLICATION SLAVE, CONNECTION_ADMIN, BACKUP_ADMIN ON *.* TO 'replicator'@'%';
SET SQL_LOG_BIN=1;
SQL
done

member_online() {
  local host="$1"
  [[ "$(mysql -h "$host" -uroot -Nse "SELECT COUNT(*) FROM performance_schema.replication_group_members WHERE MEMBER_STATE='ONLINE' AND MEMBER_ID=@@server_uuid")" == 1 ]]
}

wait_online() {
  local host="$1"
  for ((attempt = 1; attempt <= 60; attempt++)); do
    if member_online "$host"; then
      return 0
    fi
    sleep 2
  done
  echo "$host did not join Group Replication" >&2
  return 1
}

online_host=''
for host in mysql-gr1 mysql-gr2 mysql-gr3; do
  if member_online "$host"; then
    online_host="$host"
    break
  fi
done

if [[ -z "$online_host" ]]; then
  # A fully stopped group must restart from a member whose GTID set contains
  # every other member's set. Never blindly bootstrap a stale member.
  hosts=(mysql-gr1 mysql-gr2 mysql-gr3)
  executed=()
  for host in "${hosts[@]}"; do
    executed+=("$(mysql --batch --raw -h "$host" -uroot -Nse 'SELECT @@GLOBAL.gtid_executed' | tr -d '\r\n ')")
  done
  bootstrap_host=''
  for ((candidate_index = 0; candidate_index < ${#hosts[@]}; candidate_index++)); do
    covers_all=true
    for ((member_index = 0; member_index < ${#hosts[@]}; member_index++)); do
      if [[ "$(mysql -h "${hosts[$candidate_index]}" -uroot -Nse "SELECT GTID_SUBSET('${executed[$member_index]}','${executed[$candidate_index]}')")" != 1 ]]; then
        covers_all=false
        break
      fi
    done
    if [[ "$covers_all" == true ]]; then
      bootstrap_host="${hosts[$candidate_index]}"
      break
    fi
  done
  if [[ -z "$bootstrap_host" ]]; then
    echo 'No Group Replication member contains all GTIDs; manual recovery is required' >&2
    exit 1
  fi
  mysql -h "$bootstrap_host" -uroot -e 'SET GLOBAL group_replication_bootstrap_group=ON;'
  trap 'mysql -h "$bootstrap_host" -uroot -e "SET GLOBAL group_replication_bootstrap_group=OFF;"' EXIT
  mysql -h "$bootstrap_host" -uroot <<SQL
START GROUP_REPLICATION USER='replicator', PASSWORD='${repl_password}';
SQL
  mysql -h "$bootstrap_host" -uroot -e 'SET GLOBAL group_replication_bootstrap_group=OFF;'
  trap - EXIT
  online_host="$bootstrap_host"
fi
wait_online "$online_host"

for host in mysql-gr1 mysql-gr2 mysql-gr3; do
  if [[ "$host" == "$online_host" ]]; then
    continue
  fi
  if ! member_online "$host"; then
    mysql -h "$host" -uroot <<SQL
START GROUP_REPLICATION USER='replicator', PASSWORD='${repl_password}';
SQL
  fi
  wait_online "$host"
done

count="$(mysql -h mysql-gr1 -uroot -Nse "SELECT COUNT(*) FROM performance_schema.replication_group_members WHERE MEMBER_STATE='ONLINE'")"
if [[ "$count" != 3 ]]; then
  echo "Expected three ONLINE members, found $count" >&2
  exit 1
fi
