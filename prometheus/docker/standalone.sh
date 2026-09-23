#!/usr/bin/env bash
set -ueo pipefail

mkdir -p "$PWD/prometheus/etc" "$PWD/prometheus/data"
rules_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/alert_rules.yml"
if [[ ! -f "$PWD/prometheus/etc/alert_rules.yml" ]]; then
  cp "$rules_file" "$PWD/prometheus/etc/alert_rules.yml"
fi
MONITORING_NETWORK="${MONITORING_NETWORK:-container-play-monitoring}"
docker network create "$MONITORING_NETWORK" >/dev/null 2>&1 || docker network inspect "$MONITORING_NETWORK" >/dev/null

cat > "$PWD/prometheus/etc/prometheus.yml" << 'EOF'
global:
  scrape_interval:     15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/alert_rules.yml

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['prometheus:9090']
  - job_name: 'node'
    static_configs:
    - targets: ['node-exporter:9100']
EOF

docker run -d \
--name=prometheus \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:9090:9090" \
--network "$MONITORING_NETWORK" \
--restart=unless-stopped \
-v "$PWD/prometheus/etc:/etc/prometheus:ro" \
-v "$PWD/prometheus/data:/prometheus" \
prom/prometheus:v3.8.0 \
--config.file=/etc/prometheus/prometheus.yml \
--storage.tsdb.path=/prometheus \
--storage.tsdb.retention.time=30d \
--web.enable-lifecycle

# check config
# docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# hot reload
# curl -i4 -X POST http://localhost:9090/-/reload
