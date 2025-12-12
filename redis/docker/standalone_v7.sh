#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name redis \
--hostname redis \
-v $PWD/redis:/data \
--restart=always  \
redis:7.4 --requirepass "Admin123"

docker run -d \
 --name redisinsight \
-p 8001:8001 \
--link redis:redis \
redislabs/redisinsight:2.70
