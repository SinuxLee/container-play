#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name swagger-ui \
--hostname swagger-ui \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:80:8080" \
swaggerapi/swagger-ui:v5.31.0
