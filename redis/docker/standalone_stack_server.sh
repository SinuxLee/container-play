#!/usr/bin/env bash
set -ueo pipefail

REDIS_PASSWORD="${REDIS_PASSWORD:-Admin123}"

docker run -d \
--name redis-stack \
--hostname redis-stack \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:6379:6379" \
-v "$PWD/redis-stack:/data" \
redis/redis-stack-server:7.4.0-v8 --requirepass "$REDIS_PASSWORD"
