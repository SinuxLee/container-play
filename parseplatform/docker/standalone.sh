#!/usr/bin/env bash
set -euo pipefail

PARSE_APP_ID="${PARSE_APP_ID:-container-play-local}"
PARSE_MASTER_KEY="${PARSE_MASTER_KEY:-Admin123}"
if [[ -z "${PARSE_DATABASE_URI:-}" ]]; then
  PARSE_DATABASE_URI='mongodb://admin:Admin123@mongo:27017/test?authSource=admin'
  PARSE_LINK_MONGO="${PARSE_LINK_MONGO:-true}"
else
  PARSE_LINK_MONGO="${PARSE_LINK_MONGO:-false}"
fi
# The default URI uses the local container named mongo; external URIs need no link.
if [[ "$PARSE_LINK_MONGO" == true ]]; then
  set -- --link mongo:mongo
else
  set --
fi

docker run -d \
  --name parse-server \
  --hostname parse-server \
  -p "${HOST_BIND_ADDRESS:-127.0.0.1}:1337:1337" \
  -e TZ=Asia/Shanghai \
  "$@" \
  parseplatform/parse-server:8.5.0 \
  --appId "$PARSE_APP_ID" \
  --masterKey "$PARSE_MASTER_KEY" \
  --databaseURI "$PARSE_DATABASE_URI"

docker run -d \
  --name parse-dashboard \
  --hostname parse-dashboard \
  -e TZ=Asia/Shanghai \
  -p "${HOST_BIND_ADDRESS:-127.0.0.1}:4040:4040" \
  --link parse-server:parse-server \
  parseplatform/parse-dashboard:8.1.0 --dev \
  --appId "$PARSE_APP_ID" \
  --masterKey "$PARSE_MASTER_KEY" \
  --serverURL http://parse-server:1337/parse

# Example request after the server is ready:
# curl -X POST -H "X-Parse-Application-Id: $PARSE_APP_ID" \
#   -H "Content-Type: application/json" \
#   -d '{"score":1337,"playerName":"Sean Plott","cheatMode":false}' \
#   http://127.0.0.1:1337/parse/classes/GameScore
