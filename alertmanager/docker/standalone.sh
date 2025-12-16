#!/usr/bin/env bash
set -ueo pipefail

cat > $PWD/alertmanager/alertmanager.yml << 'EOF'
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF

docker run -d \
--name alertmanager \
--hostname alertmanager \
-p 9093:9093 \
-v $PWD/alertmanager:/etc/alertmanager \
prom/alertmanager:v0.29.0

# 查看集群状态
# amtool cluster --alertmanager.url http://localhost:9093
