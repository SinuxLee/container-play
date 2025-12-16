#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name swagger-ui \
--hostname swagger-ui \
-p 80:8080 \
swaggerapi/swagger-ui:v5.31.0
