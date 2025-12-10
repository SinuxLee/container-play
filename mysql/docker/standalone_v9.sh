#!/usr/bin/bash env

# 自定义文件在 /etc/mysql/conf.d/
docker run -d \
--name mysql \
-p 3306:3306 \
-e MYSQL_ROOT_PASSWORD=Admin123 \
-v $PWD/mysql:/var/lib/mysql \
--restart always  \
mysql:9.5
