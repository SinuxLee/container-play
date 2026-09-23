#!/usr/bin/env bash
set -ueo pipefail

GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-Admin123}"
MONITORING_NETWORK="${MONITORING_NETWORK:-container-play-monitoring}"
docker network create "$MONITORING_NETWORK" >/dev/null 2>&1 || docker network inspect "$MONITORING_NETWORK" >/dev/null

docker run -d \
--name=grafana \
--restart=unless-stopped \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:3000:3000" \
--network "$MONITORING_NETWORK" \
-e "GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD" \
-v grafana_data:/var/lib/grafana \
-v "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../provisioning:/etc/grafana/provisioning:ro" \
grafana/grafana:12.1
