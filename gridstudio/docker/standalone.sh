#!/usr/bin/env bash
set -ueo pipefail

# https://github.com/ricklamers/gridstudio
docker run  -d \
--name=gridstudio \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8080:8080" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:4430:4430" \
-v "$PWD/gridstudio/source:/home/source" \
-v "$PWD/gridstudio/userdata:/home/userdata" \
ricklamers/gridstudio:release
