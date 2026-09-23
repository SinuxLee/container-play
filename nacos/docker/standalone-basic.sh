#!/usr/bin/env bash
set -ueo pipefail

export NACOS_AUTH_TOKEN="${NACOS_AUTH_TOKEN:-Y29udGFpbmVyLXBsYXktbG9jYWwtbmFjb3MtdG9rZW4=}"
export NACOS_AUTH_IDENTITY_KEY="${NACOS_AUTH_IDENTITY_KEY:-serverIdentity}"
export NACOS_AUTH_IDENTITY_VALUE="${NACOS_AUTH_IDENTITY_VALUE:-Admin123}"

# 基础版
docker run -d \
--name nacos \
--hostname nacos \
--restart=always \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8848:8848" \
-e MODE=standalone \
-e NACOS_AUTH_ENABLE=true \
-e NACOS_AUTH_IDENTITY_KEY \
-e NACOS_AUTH_IDENTITY_VALUE \
-e NACOS_AUTH_TOKEN \
nacos/nacos-server:v2.5.1
