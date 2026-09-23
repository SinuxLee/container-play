#!/usr/bin/env bash
set -ueo pipefail

# The monitoring containers reach this exporter as node-exporter:9100.
MONITORING_NETWORK="${MONITORING_NETWORK:-container-play-monitoring}"
docker network create "$MONITORING_NETWORK" >/dev/null 2>&1 || docker network inspect "$MONITORING_NETWORK" >/dev/null

docker run -d \
--name=node-exporter \
--network "$MONITORING_NETWORK" \
--pid=host \
--publish "${HOST_BIND_ADDRESS:-127.0.0.1}:9100:9100" \
--restart=unless-stopped \
-v "/:/host:ro,rslave" \
prom/node-exporter:v1.10.2 \
--path.rootfs=/host \
--collector.filesystem.mount-points-exclude="^/(sys|proc|dev|host|run)($|/)"
