#!/usr/bin/env bash
set -euo pipefail

ready=false
for ((attempt = 1; attempt <= 60; attempt++)); do
  if mongosh --host mongodb-mongos:27017 --quiet --eval 'db.adminCommand({ping:1})' >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done
if [[ "$ready" != true ]]; then
  echo "mongos did not become ready" >&2
  exit 1
fi

mongosh --host mongodb-mongos:27017 --quiet --eval '
  const shards = db.adminCommand({ listShards: 1 }).shards;
  if (!shards.some(shard => shard._id === "shard0ReplSet")) {
    sh.addShard("shard0ReplSet/mongodb-shard0:27018");
  }
'
