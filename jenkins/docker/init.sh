#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name jenkins \
--hostname jenkins \
--restart=always  \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:8080:8080" \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:50000:50000" \
-v jenkins_home:/var/jenkins_home \
jenkins/jenkins:lts

# 查看密码
# docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
