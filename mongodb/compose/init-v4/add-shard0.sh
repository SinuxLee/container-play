#!/usr/bin/env bash
set -euo pipefail

ready=false
for ((attempt = 1; attempt <= 60; attempt++)); do
  if mongo --host mongodb-mongos:27017 --quiet --eval 'db.adminCommand({ping:1})' >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done
if [[ "$ready" != true ]]; then
  echo "mongos did not become ready" >&2
  exit 1
fi

mongo --host mongodb-mongos:27017 --quiet --eval '
  var result = db.adminCommand({ listShards: 1 });
  if (result.ok !== 1) throw new Error("listShards failed");
  if (!result.shards.some(function(shard) { return shard._id === "shard0ReplSet"; })) {
    result = db.adminCommand({ addShard: "shard0ReplSet/mongodb-shard0:27018" });
    if (result.ok !== 1) throw new Error("addShard failed");
  }
'
