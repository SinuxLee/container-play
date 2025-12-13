#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name=httpbin \
-p 8080:8080 \
grafana/k6-httpbin:v0.9.0

# curl -i localhost:8080/anything/haha
