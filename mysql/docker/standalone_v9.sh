#!/usr/bin/env bash
set -ue

export MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-Admin123}"

# 自定义文件在 /etc/mysql/conf.d/
docker run -d \
--name mysql \
--hostname mysql \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:3306:3306" \
-e MYSQL_ROOT_PASSWORD \
-v "$PWD/mysql:/var/lib/mysql" \
--restart always  \
mysql:9.5
