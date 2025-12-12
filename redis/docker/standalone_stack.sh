#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name redis-stack \
--hostname redis-stack \
-p 6379:6379 \
-p 8001:8001 \
-v $PWD/redis-stack:/data \
redis/redis-stack:7.4.0-v8 --requirepass "Admin123"
