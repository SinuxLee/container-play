#!/usr/bin/env bash
set -ueo pipefail

APOLLO_DB_PASSWORD="${APOLLO_DB_PASSWORD:-Admin123}"

docker run -d \
--name apollo \
--hostname apollo \
--link mysql:apollo-db \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8070:8070" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8080:8080" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8090:8090" \
-e JAVA_OPTS='-Xms100m -Xmx1000m -Xmn100m -Xss256k -XX:MetaspaceSize=10m -XX:MaxMetaspaceSize=250m' \
-e APOLLO_CONFIG_DB_USERNAME='root' \
-e "APOLLO_CONFIG_DB_PASSWORD=$APOLLO_DB_PASSWORD" \
-e APOLLO_PORTAL_DB_USERNAME='root' \
-e "APOLLO_PORTAL_DB_PASSWORD=$APOLLO_DB_PASSWORD" \
nobodyiam/apollo-quick-start:2.4.0

# web entry 8087, apollo/admin
