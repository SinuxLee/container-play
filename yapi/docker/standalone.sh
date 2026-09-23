#!/usr/bin/env bash
set -ueo pipefail

export YAPI_ADMIN_PASSWORD="${YAPI_ADMIN_PASSWORD:-Admin123}"
YAPI_ADMIN_ACCOUNT="${YAPI_ADMIN_ACCOUNT:-admin@docker.yapi}"
YAPI_DB_USER="${YAPI_DB_USER:-admin}"
export YAPI_DB_PASS="${YAPI_DB_PASS:-Admin123}"

docker run -d --name yapi \
--hostname yapi \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:3030:3000" \
-e "YAPI_ADMIN_ACCOUNT=$YAPI_ADMIN_ACCOUNT" \
-e YAPI_ADMIN_PASSWORD \
-e YAPI_DB_SERVERNAME=mongo \
-e YAPI_DB_PORT=27017 \
-e YAPI_DB_DATABASE=yapi \
-e "YAPI_DB_USER=$YAPI_DB_USER" \
-e YAPI_DB_PASS \
-e YAPI_DB_AUTH_SOURCE=admin \
--link mongo:mongo \
--restart always \
jayfong/yapi:1.10.2
