#!/usr/bin/env bash
set -ue

# 创建服务
docker run -d \
--name svn \
-p 80:80 \
-p 3690:3690 \
-v $PWD/svn/repo:/home/svn \
-v $PWD/svn/config:/etc/subversion \
elleflorio/svn-server:latest

# 启动 svnwebui
docker run -d \
--name svnwebui \
--privileged=true \
-p 6060:6060 \
-p 3690:3690 \
-e BOOT_OPTIONS="--server.port=6060" \
-v $PWD/svnWebUI:/home/svnWebUI \
cym1102/svnwebui:1.8.7

# 进入 http://localhost:6060/ 设置管理员密码
