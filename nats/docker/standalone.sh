#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name nats \
--hostname nats \
--restart=always \
-p 4222:4222 \
-p 8222:8222 \
-p 6222:6222 \
-v $PWD/nats/data:/data \
nats:2.12 -js -sd /data -m 8222
