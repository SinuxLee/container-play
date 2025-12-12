#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name nats-server \
--restart=always \
-p 4222:4222 \
-v $PWD/nats/data:/data
nats:2.12  -js
