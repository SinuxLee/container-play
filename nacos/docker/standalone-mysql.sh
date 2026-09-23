#!/usr/bin/env bash
set -ueo pipefail

export NACOS_AUTH_TOKEN="${NACOS_AUTH_TOKEN:-Y29udGFpbmVyLXBsYXktbG9jYWwtbmFjb3MtdG9rZW4=}"
export NACOS_AUTH_IDENTITY_KEY="${NACOS_AUTH_IDENTITY_KEY:-serverIdentity}"
export NACOS_AUTH_IDENTITY_VALUE="${NACOS_AUTH_IDENTITY_VALUE:-Admin123}"
export MYSQL_SERVICE_PASSWORD="${MYSQL_SERVICE_PASSWORD:-Admin123}"
MYSQL_SERVICE_USER="${MYSQL_SERVICE_USER:-nacos}"

# 外部存储版
# CREATE DATABASE nacos;
# CREATE USER 'nacos'@'%' IDENTIFIED BY 'Admin123';
# GRANT ALL PRIVILEGES ON nacos.* TO 'nacos'@'%';
# FLUSH PRIVILEGES;

docker run -d \
--name nacos \
--hostname nacos \
--restart=always \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8848:8848" \
--link mysql:mysql \
-e MODE=standalone \
-e NACOS_AUTH_ENABLE=true \
-e NACOS_AUTH_TOKEN \
-e NACOS_AUTH_IDENTITY_KEY \
-e NACOS_AUTH_IDENTITY_VALUE \
-e SPRING_DATASOURCE_PLATFORM=mysql \
-e MYSQL_SERVICE_HOST=mysql \
-e "MYSQL_SERVICE_USER=$MYSQL_SERVICE_USER" \
-e MYSQL_SERVICE_PASSWORD \
-e MYSQL_SERVICE_DB_NAME=nacos \
nacos/nacos-server:v2.5.1
