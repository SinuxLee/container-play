#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name=gitea \
--restart=unless-stopped \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:2222:22" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:3000:3000" \
-v $PWD/gitea:/data \
gitea/gitea:1.25
