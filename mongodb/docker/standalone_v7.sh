#!/usr/bin/env bash
set -ueo pipefail

export MONGO_INITDB_ROOT_USERNAME="${MONGO_INITDB_ROOT_USERNAME:-admin}"
export MONGO_INITDB_ROOT_PASSWORD="${MONGO_INITDB_ROOT_PASSWORD:-Admin123}"

docker run -d \
--name mongo7 \
--hostname mongo7 \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:${MONGODB_HOST_PORT:-27017}:27017" \
-v "$PWD/mongo7:/data/db" \
-e MONGO_INITDB_ROOT_USERNAME \
-e MONGO_INITDB_ROOT_PASSWORD \
--restart=unless-stopped \
mongo:7.0 --auth
