#!/usr/bin/env bash
set -ueo pipefail

# SWAGGER_FILE 优先级比 URL 低
docker run -d \
--name swagger-editor \
--hostname swagger-editor \
-p 9080:9080 \
-e PORT=9080 \
-e URL="https://petstore3.swagger.io/api/v3/openapi.json" \
-v $PWD:/tmp -e SWAGGER_FILE=/tmp/swagger.json \
swaggerapi/swagger-editor:v5.0.1
