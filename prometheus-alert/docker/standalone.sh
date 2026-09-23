#!/usr/bin/env bash
set -ueo pipefail

MONITORING_NETWORK="${MONITORING_NETWORK:-container-play-monitoring}"
docker network create "$MONITORING_NETWORK" >/dev/null 2>&1 || docker network inspect "$MONITORING_NETWORK" >/dev/null

docker run -d \
--name prometheusalert \
--hostname prometheusalert \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8080:8080" \
--network "$MONITORING_NETWORK" \
-v $PWD/prometheusalert:/app/conf \
feiyu563/prometheus-alert:v4.9.2
