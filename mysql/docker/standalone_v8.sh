#!/usr/bin/bash env
set -ue

# 自定义文件在 /etc/mysql/conf.d/
docker run -d \
--name mysql \
--hostname mysql \
-p 3306:3306 \
-e MYSQL_ROOT_PASSWORD=Admin123 \
-v $PWD/mysql:/var/lib/mysql \
--restart always  \
mysql:8.4
