#!/usr/bin/env bash
set -ueo pipefail

link_mysql="${CLOUDBEAVER_LINK_MYSQL:-auto}"
if [[ "$link_mysql" == true ]] ||
   { [[ "$link_mysql" == auto ]] && [[ "$(docker inspect --format '{{.State.Running}}' mysql 2>/dev/null)" == true ]]; }; then
  set -- --link mysql:mysql
else
  set --
fi

docker run -d \
--name cloudbeaver \
--hostname cloudbeaver \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8978:8978" \
"$@" \
--restart=always \
-v $PWD/cloudbeaver:/opt/cloudbeaver/workspace \
dbeaver/cloudbeaver:25.3
