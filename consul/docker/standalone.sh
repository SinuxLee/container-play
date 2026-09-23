#!/usr/bin/env bash
set -ueo pipefail

# gen token: openssl rand -hex 16
# consul acl bootstrap | tee token.info
token_file="$PWD/consul/.management-token"
if [[ -z "${CONSUL_MANAGEMENT_TOKEN:-}" ]]; then
  if [[ -f "$token_file" ]]; then
    CONSUL_MANAGEMENT_TOKEN="$(<"$token_file")"
  else
    if command -v uuidgen >/dev/null; then
      CONSUL_MANAGEMENT_TOKEN="$(uuidgen)"
    else
      random_hex="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
      CONSUL_MANAGEMENT_TOKEN="${random_hex:0:8}-${random_hex:8:4}-4${random_hex:13:3}-a${random_hex:17:3}-${random_hex:20:12}"
    fi
    mkdir -p "$PWD/consul"
    (umask 077; printf '%s\n' "$CONSUL_MANAGEMENT_TOKEN" > "$token_file")
  fi
fi
if [[ ! "$CONSUL_MANAGEMENT_TOKEN" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
  echo "CONSUL_MANAGEMENT_TOKEN must be a UUID" >&2
  exit 2
fi

mkdir -p "$PWD/consul/data"
export CONSUL_LOCAL_CONFIG="{\"acl\":{\"enabled\":true,\"default_policy\":\"deny\",\"enable_token_persistence\":true,\"tokens\":{\"initial_management\":\"$CONSUL_MANAGEMENT_TOKEN\"}}}"

# bind_addr 集群内部通信用 IP
# client_addr 客户端可以连接的 IP

docker run -d --name consul \
--hostname consul \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8500:8500" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8600:8600" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8600:8600/udp" \
-v "$PWD/consul/data:/consul/data" \
-e CONSUL_LOCAL_CONFIG \
--restart=always \
hashicorp/consul:1.19 \
agent -server -ui -bootstrap-expect=1 \
-client=0.0.0.0 \
-config-dir=/consul/config

# http API
# curl -i -H "X-Consul-Token: $CONSUL_MANAGEMENT_TOKEN" http://127.0.0.1:8500/v1/agent/self

# CLI Client
# export CONSUL_HTTP_ADDR=http://127.0.0.1:8500
# export CONSUL_HTTP_TOKEN="$CONSUL_MANAGEMENT_TOKEN"
# consul members

# DNS
# dig @127.0.0.1 -p 8600 consul.service.consul
# nslookup gameweb.service.consul 127.0.0.1:8600
