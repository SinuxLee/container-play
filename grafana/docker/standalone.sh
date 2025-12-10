#!/usr/bin/env bash

docker run -d \
--name=grafana \
-u root \
--restart=unless-stopped \
-p 3000:3000 \
--net="host" \
-v $PWD/grafana:/var/lib/grafana \
grafana/grafana:12.1
