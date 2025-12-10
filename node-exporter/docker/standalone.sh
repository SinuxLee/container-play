#!/usr/bin/env bash

# default use port 9100
docker run -d \
--name=node-exporter \
--net=host \
--pid=host \
--restart=unless-stopped \
-v "/:/host:ro,rslave" \
prom/node-exporter:v1.10.2 \
--path.rootfs=/host \
--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|run)($|/)"
