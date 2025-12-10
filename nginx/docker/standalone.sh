#!/usr/bin/env bash

mkdir -p nginx/{conf,conf.d,html,logs}

cat > nginx/conf/nginx.conf << 'EOF'
worker_processes  1;

pid        /var/run/nginx.pid;
error_log  /var/log/nginx/error.log info;

events {
    worker_connections 10000;
    accept_mutex on;
}

http {
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen 80;
        server_name  _;

        root /usr/share/nginx/html;
        index index.html;
    }

    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > nginx/html/index.html << 'EOF'
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>Nginx in Docker</title></head>
  <body>It works.</body>
</html>
EOF

docker run \
--name nginx \
-d -p 8088:80 \
--env TZ='Asia/Shanghai' \
-v "$PWD/nginx/conf/nginx.conf:/etc/nginx/nginx.conf:ro" \
-v "$PWD/nginx/conf.d:/etc/nginx/conf.d" \
-v "$PWD/nginx/html:/usr/share/nginx/html" \
-v "$PWD/nginx/logs:/var/log/nginx" \
nginx:1.29
