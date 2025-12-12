#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name=gitea \
--restart=unless-stopped \
-p 2222:22 \
-p 3000:3000 \
-v $PWD/gitea:/data \
gitea/gitea:1.25
