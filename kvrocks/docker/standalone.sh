#!/bin/bash

# copy default config from container
if [[ ! -f "$CONF_DIR/kvrocks.conf" ]]; then
  docker run -d --rm \
  --name kvrocks \
  -u root \
  -v $PWD/kvrocks:/data \
  apache/kvrocks:2.14.0

  docker cp kvrocks:/var/lib/kvrocks/kvrocks.conf ./kvrocks/ && docker rm -f kvrocks
fi

docker run -d \
--name kvrocks \
--hostname kvrocks \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:6666:6666" \
-u root \
--restart always \
-v $PWD/kvrocks:/var/lib/kvrocks \
apache/kvrocks:2.14.0
