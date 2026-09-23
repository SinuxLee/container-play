#!/usr/bin/env bash
set -euo pipefail

mongosh --host mongodb-cfg:27019 --quiet --eval '
  try {
    rs.status();
  } catch (error) {
    rs.initiate({ _id: "cfgReplSet", configsvr: true, members: [{ _id: 0, host: "mongodb-cfg:27019" }] });
  }
'

for ((attempt = 1; attempt <= 60; attempt++)); do
  if mongosh --host mongodb-cfg:27019 --quiet --eval 'if (!db.hello().isWritablePrimary) quit(1)' >/dev/null 2>&1; then
    exit 0
  fi
  sleep 2
done
echo "Config server replica set did not elect a primary" >&2
exit 1
