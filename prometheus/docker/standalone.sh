#!/usr/bin/env bash
set -ueo pipefail

mkdir -p prometheus/{etc,data}

cat > $PWD/prometheus/etc/prometheus.yml << 'EOF'
global:
  scrape_interval:     15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - 10.0.84.106:9093

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['10.0.84.106:9090']

  - job_name: 'grafana'
    static_configs:
    - targets: ['10.0.84.106:3000']
EOF

docker run -d \
--name=prometheus \
-p 9090:9090 \
--restart=unless-stopped \
-v $PWD/prometheus/etc:/etc/prometheus \
-v $PWD/prometheus/data:/prometheus \
prom/prometheus:v3.8.0 \
--config.file=/etc/prometheus/prometheus.yml \
--storage.tsdb.path=/prometheus \
--storage.tsdb.retention.time=30d \
--web.enable-lifecycle

# check config
# docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# hot reload
# curl -i4 -X POST http://localhost:9090/-/reload
