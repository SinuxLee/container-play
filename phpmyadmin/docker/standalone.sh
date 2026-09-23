#!/usr/bin/env bash
set -ueo pipefail

PMA_HOST="${PMA_HOST:-mysql}"
if [[ "$PMA_HOST" == mysql ]]; then
  set -- --link mysql:mysql
else
  set --
fi

docker run -d \
--name phpmyadmin \
--hostname phpmyadmin \
-e "PMA_HOST=$PMA_HOST" \
-e PMA_PORT=3306 \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:13306:80" \
"$@" \
--restart always  \
phpmyadmin/phpmyadmin:5.2
