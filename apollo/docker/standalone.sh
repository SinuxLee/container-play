#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name apollo \
--hostname apollo \
--link mysql:apollo-db \
-p 8070:8070 \
-p 8080:8080 \
-p 8090:8090 \
-e JAVA_OPTS='-Xms100m -Xmx1000m -Xmn100m -Xss256k -XX:MetaspaceSize=10m -XX:MaxMetaspaceSize=250m' \
-e APOLLO_CONFIG_DB_USERNAME='root' \
-e APOLLO_CONFIG_DB_PASSWORD='Admin123' \
-e APOLLO_PORTAL_DB_USERNAME='root' \
-e APOLLO_PORTAL_DB_PASSWORD='Admin123' \
nobodyiam/apollo-quick-start:2.4.0

# web entry 8087, apollo/admin
