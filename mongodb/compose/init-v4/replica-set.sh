#!/usr/bin/env bash
set -euo pipefail

mongo --host mongo-rs1:27017 --quiet --eval '
  var status;
  try { status = db.adminCommand({ replSetGetStatus: 1 }); }
  catch (error) { status = { ok: 0, code: error.code }; }
  if (status.ok !== 1) {
    if (status.code !== 94) throw new Error("replSetGetStatus failed: " + tojson(status));
    var result = rs.initiate({
      _id: "rsV4",
      members: [
        { _id: 0, host: "mongo-rs1:27017" },
        { _id: 1, host: "mongo-rs2:27017" },
        { _id: 2, host: "mongo-rs3:27017" }
      ]
    });
    if (result.ok !== 1) throw new Error("rs.initiate failed");
  }
'

for ((attempt = 1; attempt <= 60; attempt++)); do
  if mongo --host mongo-rs1:27017 --quiet --eval 'if (!rs.status().members.some(function(member) { return member.stateStr === "PRIMARY"; })) quit(1)' >/dev/null 2>&1; then
    exit 0
  fi
  sleep 2
done
echo 'MongoDB 4 replica set did not elect a primary' >&2
exit 1
