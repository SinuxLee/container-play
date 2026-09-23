#!/usr/bin/env bash
set -ueo pipefail

REDIS_PASSWORD="${REDIS_PASSWORD:-Admin123}"

docker run -d \
--name redis \
--hostname redis \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:6379:6379" \
-v "$PWD/redis:/data" \
--restart=always  \
redis:7.4 --requirepass "$REDIS_PASSWORD"

docker run -d \
--name redisinsight \
--hostname redisinsight \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8001:8001" \
--link redis:redis \
redislabs/redisinsight:2.70
