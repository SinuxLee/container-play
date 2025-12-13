#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name alertmanager \
--hostname alertmanager \
-p 9093:9093 \
-v $PWD/alertmanager:/etc/alertmanager \
prom/alertmanager
