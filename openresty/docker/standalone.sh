#!/usr/bin/env bash

mkdir -p openresty/{conf,conf.d,html,logs,lua} && cd openresty

docker run --name openresty-temp -d openresty/openresty:rocky \
  && docker cp openresty-temp:/usr/local/openresty/nginx/conf ./ \
  && docker cp openresty-temp:/usr/local/openresty/nginx/conf.d ./conf.d \
  && docker cp openresty-temp:/usr/local/openresty/nginx/html ./ \
  && docker cp openresty-temp:/usr/local/openresty/nginx/lua ./ \
  && docker rm -f openresty-temp

docker run -d  \
 --name openresty \
-p 8080:8080 \
-p 9090:9090 \
-v $PWD/conf:/usr/local/openresty/nginx/conf \
-v $PWD/html:/usr/local/openresty/nginx/html \
-v $PWD/logs:/usr/local/openresty/nginx/logs \
-v $PWD/conf.d:/usr/local/openresty/nginx/conf.d \
-v $PWD/lua:/usr/local/openresty/nginx/lua \
--restart=always \
openresty/openresty:rocky
