#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name cloudbeaver \
--hostname cloudbeaver \
-p 8978:8978 \
--restart=always \
--network host \
-v $PWD/cloudbeaver:/opt/cloudbeaver/workspace \
dbeaver/cloudbeaver:25.3
