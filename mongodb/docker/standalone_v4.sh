#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name mongo \
--hostname mongo \
-p 27017:27017 \
-m 1024M \
--cpus=2 \
--cpuset-cpus="0,1" \
-e TZ="Asia/Shanghai" \
-e MONGO_INITDB_ROOT_USERNAME=admin \
-e MONGO_INITDB_ROOT_PASSWORD=Admin123 \
-v $PWD/mongo:/data/db \
-v /etc/localtime:/etc/localtime:ro \
--restart=always  \
mongo:4.4 --auth
