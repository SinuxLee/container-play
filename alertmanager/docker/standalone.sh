#!/usr/bin/env bash
set -ueo pipefail

if [[ -n "${ALERT_WEBHOOK_URL:-}" ]]; then
  case "$ALERT_WEBHOOK_URL" in
    http://*|https://*) ;;
    *) echo "ALERT_WEBHOOK_URL must be an http(s) URL" >&2; exit 2 ;;
  esac

  if [[ "$ALERT_WEBHOOK_URL" == *"'"* || "$ALERT_WEBHOOK_URL" == *$'\n'* ]]; then
    echo "ALERT_WEBHOOK_URL contains characters that cannot be written safely to YAML" >&2
    exit 2
  fi
fi

mkdir -p "$PWD/alertmanager"
umask 077
MONITORING_NETWORK="${MONITORING_NETWORK:-container-play-monitoring}"
docker network create "$MONITORING_NETWORK" >/dev/null 2>&1 || docker network inspect "$MONITORING_NETWORK" >/dev/null

cat > "$PWD/alertmanager/alertmanager.yml" << EOF
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
receivers:
- name: 'default'
EOF

if [[ -n "${ALERT_WEBHOOK_URL:-}" ]]; then
  cat >> "$PWD/alertmanager/alertmanager.yml" << EOF
  webhook_configs:
  - url: '$ALERT_WEBHOOK_URL'
EOF
fi

cat >> "$PWD/alertmanager/alertmanager.yml" << 'EOF'
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
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:9093:9093" \
--network "$MONITORING_NETWORK" \
--restart=unless-stopped \
-v "$PWD/alertmanager:/etc/alertmanager:ro" \
prom/alertmanager:v0.29.0

# 查看集群状态
# amtool cluster --alertmanager.url http://localhost:9093
