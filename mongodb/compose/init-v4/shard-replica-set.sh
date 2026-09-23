#!/usr/bin/env bash
set -euo pipefail

mongo --host mongodb-shard0:27018 --quiet --eval '
  var status;
  try { status = db.adminCommand({ replSetGetStatus: 1 }); }
  catch (error) { status = { ok: 0, code: error.code }; }
  if (status.ok !== 1) {
    if (status.code !== 94) throw new Error("replSetGetStatus failed: " + tojson(status));
    var result = rs.initiate({ _id: "shard0ReplSet", members: [{ _id: 0, host: "mongodb-shard0:27018" }] });
    if (result.ok !== 1) throw new Error("rs.initiate failed");
  }
'

for ((attempt = 1; attempt <= 60; attempt++)); do
  if mongo --host mongodb-shard0:27018 --quiet --eval 'if (!db.isMaster().ismaster) quit(1)' >/dev/null 2>&1; then
    exit 0
  fi
  sleep 2
done
echo "Shard replica set did not elect a primary" >&2
exit 1
