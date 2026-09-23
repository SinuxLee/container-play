#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name nats \
--hostname nats \
--restart=always \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:4222:4222" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8222:8222" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:6222:6222" \
-v $PWD/nats/data:/data \
nats:2.12 -js -sd /data -m 8222
