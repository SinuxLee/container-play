#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name webdis \
--hostname webdis \
-p 7379:7379 \
-e LOCAL_REDIS=true \
-e WEBSOCKETS=true \
anapsix/webdis

# curl http://127.0.0.1:7379/SET/hello/world
# curl http://127.0.0.1:7379/GET/hello
