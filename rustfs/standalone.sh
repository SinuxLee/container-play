#!/usr/bin/env bash
set -ueo pipefail

mkdir -p rustfs/{data,logs}

docker run -d \
--name rustfs \
--hostname rustfs \
--restart=always \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:9000:9000" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:9001:9001" \
-v $(pwd)/rustfs/data:/data \
-v $(pwd)/rustfs/logs:/logs \
rustfs/rustfs:1.0.0

# 默认账号：rustfsadmin / rustfsadmin
# S3 API地址：http://localhost:9000
# Web控制台：http://localhost:9001
# 如需开启 https, 则 mkdir -p certs && chown -R 10001:10001 certs
