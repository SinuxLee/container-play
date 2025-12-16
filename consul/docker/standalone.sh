#!/usr/bin/env bash
set -ueo pipefail

# gen token: openssl rand -hex 16
# consul acl bootstrap | tee token.info
cat > $PWD/consul/config/acl.hc << 'EOF'
acl {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true

  tokens {
    initial_management = "8916f9b8-35a2-92f8-2d6e-a56ef7df879b"
  }
}
EOF

# bind_addr 集群内部通信用 IP
# client_addr 客户端可以连接的 IP

docker run -d --name consul \
--hostname consul \
-p 8500:8500 \
-p 127.0.0.1:8600:8600 \
-p 127.0.0.1:8600:8600/udp \
-v $PWD/consul/data:/consul/data \
-v $PWD/consul/config:/consul/config \
--restart=always \
hashicorp/consul:1.19 \
agent -server -ui -bootstrap-expect=1 \
-client=0.0.0.0 \
-config-dir=/consul/config

# http API
# curl -i -H "X-Consul-Token: REPLACE_WITH_A_LONG_RANDOM_TOKEN" http://127.0.0.1:8500/v1/agent/self

# CLI Client
# export CONSUL_HTTP_ADDR=http://127.0.0.1:8500
# export CONSUL_HTTP_TOKEN=REPLACE_WITH_A_LONG_RANDOM_TOKEN
# consul members

# DNS
# dig @127.0.0.1 -p 8600 consul.service.consul
# nslookup gameweb.service.consul 127.0.0.1:8600
