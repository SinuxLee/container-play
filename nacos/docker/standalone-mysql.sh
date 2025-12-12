#!/usr/bin/env bash
set -ueo pipefail

# 外部存储版
# CREATE DATABASE nacos;
# CREATE USER 'nacos'@'%' IDENTIFIED BY 'Admin123';
# GRANT ALL PRIVILEGES ON nacos.* TO 'nacos'@'%';
# FLUSH PRIVILEGES;

docker run -d \
--name nacos \
--restart=always \
-p 8848:8848 \
--link mysql:mysql \
-e MODE=standalone \
-e NACOS_AUTH_ENABLE=true \
-e NACOS_AUTH_TOKEN=I0ojgGQSba0WL5CLnP/NUUjN4XAX97yIugFq41HUY5o= \
-e NACOS_AUTH_IDENTITY_KEY=QK29DvUXgAG1 \
-e NACOS_AUTH_IDENTITY_VALUE=8jWWq1Q9KsZL \
-e SPRING_DATASOURCE_PLATFORM=mysql \
-e MYSQL_SERVICE_HOST=mysql \
-e MYSQL_SERVICE_USER=root \
-e MYSQL_SERVICE_PASSWORD=Admin123 \
-e MYSQL_SERVICE_DB_NAME=nacos \
nacos/nacos-server:v2.5.1
