#!/usr/bin/env bash
set -ueo pipefail

# 仅限本机访问
docker run -d \
--name redis-cluster \
-e "IP=0.0.0.0" \
-p 7000-7005:7000-7005 \
-v $PWD/redis-cluster:/redis-data \
--restart=always  \
grokzen/redis-cluster:7.2.5
