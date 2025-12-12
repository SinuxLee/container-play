#!/usr/bin/env bash
set -ueo pipefail

# 基础版
docker run -d \
--name nacos \
--restart=always \
-p 8848:8848 \
-e MODE=standalone \
-e NACOS_AUTH_ENABLE=true \
-e NACOS_AUTH_IDENTITY_KEY=QK29DvUXgAG1 \
-e NACOS_AUTH_IDENTITY_VALUE=8jWWq1Q9KsZL \
-e NACOS_AUTH_TOKEN=I0ojgGQSba0WL5CLnP/NUUjN4XAX97yIugFq41HUY5o= \
nacos/nacos-server:v2.5.1
