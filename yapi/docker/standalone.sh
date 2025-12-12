#!/usr/bin/env bash
set -ueo pipefail

docker run -d --name yapi \
-p 3030:3000 \
-e YAPI_ADMIN_ACCOUNT=admin \
-e YAPI_ADMIN_PASSWORD=Admin123 \
-e YAPI_DB_SERVERNAME=mongo \
-e YAPI_DB_PORT=27017 \
-e YAPI_DB_DATABASE=yapi \
--link mongo:mongo \
--restart always \
jayfong/yapi:1.10.2
