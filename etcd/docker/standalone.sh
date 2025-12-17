#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name etcd \
--hostname etcd \
--restart=always \
-p 2379:2379 \
-p 2380:2380 \
-v $PWD/etcd:/bitnami/etcd/data \
--env ALLOW_NONE_AUTHENTICATION=yes \
--env ETCD_ENABLE_V2=true \
--env ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379" \
--env ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379" \
bitnamilegacy/etcd:3.5.0


# 可视化
docker run -d \
--name etcdkeeper \
--hostname etcdkeeper \
--restart=always \
-p 8080:8080 \
--link etcd:etcd \
evildecay/etcdkeeper
