#!/usr/bin/env bash
set -ueo pipefail

# parse-server
docker run -d \
--name parse-server \
-p 1337:1337 \
-e TZ="Asia/Shanghai" \
# -v $PWD/parse-server:/parse-server \
--link mongo:mongo \
parseplatform/parse-server:8.5.0 \
--appId APPLICATION_ID \
--masterKey MASTER_KEY \
--databaseURI mongodb://mongo/test

# parse-dashboard
docker run -d \
--name parse-dashboard \
-e TZ="Asia/Shanghai" \
-p 4040:4040 \
--link parse-server:parse-server \
parseplatform/parse-dashboard:8.1.0 --dev \
--appId APPLICATION_ID \
--masterKey MASTER_KEY \
--serverURL http://parse-server:1337/parse

# test
curl -X POST \
-H "X-Parse-Application-Id: APPLICATION_ID" \
-H "Content-Type: application/json" \
-d '{"score":1337,"playerName":"Sean Plott","cheatMode":false}' \
http://localhost:1337/parse/classes/GameScore
