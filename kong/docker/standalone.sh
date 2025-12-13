#!/usr/bin/env bash
set -ueo pipefail

echo > $PWD/kong.yaml << 'EOF'
_format_version: "3.0"
_transform: true

services:
  - name: anything
    url: http://httpbin.org
    routes:
      - name: anything
        paths:
          - /anything
EOF

docker run -d \
--name kong \
--hostname kong \
-p 8000:8000 \
-p 8443:8443 \
-p 8001:8001 \
-p 8444:8444 \
-e KONG_DATABASE=off \
-e KONG_PROXY_ACCESS_LOG=/dev/stdout \
-e KONG_ADMIN_ACCESS_LOG=/dev/stdout \
-e KONG_PROXY_ERROR_LOG=/dev/stderr \
-e KONG_ADMIN_ERROR_LOG=/dev/stderr \
-e KONG_ADMIN_LISTEN=0.0.0.0:8001,0.0.0.0:8444 ssl \
-e KONG_DECLARATIVE_CONFIG=/usr/local/kong/declarative/kong.yml \
-v $PWD/kong/kong.yml:/usr/local/kong/declarative/kong.yml \
kong:3.9.1

# export config
# curl -s http://localhost:8001/config | tee kong.yaml
