#!/usr/bin/env bash
set -ueo pipefail

config_file="${KONG_CONFIG_FILE:-$PWD/kong.yaml}"
if [[ "$config_file" != /* ]]; then
  config_file="$PWD/$config_file"
fi
if [[ ! -f "$config_file" ]]; then
cat > "$config_file" << 'EOF'
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
fi

docker run -d \
--name kong \
--hostname kong \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8000:8000" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8443:8443" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8001:8001" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8444:8444" \
-e KONG_DATABASE=off \
-e KONG_PROXY_ACCESS_LOG=/dev/stdout \
-e KONG_ADMIN_ACCESS_LOG=/dev/stdout \
-e KONG_PROXY_ERROR_LOG=/dev/stderr \
-e KONG_ADMIN_ERROR_LOG=/dev/stderr \
-e "KONG_ADMIN_LISTEN=0.0.0.0:8001,0.0.0.0:8444 ssl" \
-e KONG_DECLARATIVE_CONFIG=/usr/local/kong/declarative/kong.yml \
-v "$config_file:/usr/local/kong/declarative/kong.yml:ro" \
kong:3.9.1

# export config
# curl -s http://localhost:8001/config | tee kong.yaml
