#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name=httpbin \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8080:8080" \
grafana/k6-httpbin:v0.9.0

# curl -i localhost:8080/anything/haha
