#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name mongo-express \
--hostname mongo-express \
-p 8081:8081 \
--restart=unless-stopped \
--env ME_CONFIG_BASICAUTH_USERNAME="adminname" \
--env ME_CONFIG_BASICAUTH_PASSWORD="adminpass" \
--env ME_CONFIG_MONGODB_SERVER="10.83.22.143" \
--env ME_CONFIG_OPTIONS_NO_DELETE=true \
--env ME_CONFIG_MONGODB_ADMINUSERNAME='admin' \
--env ME_CONFIG_MONGODB_ADMINPASSWORD='123456' \
mongo-express:1.0.2
