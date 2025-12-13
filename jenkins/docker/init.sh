#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
-u root \
--name jenkins \
--hostname jenkins \
--restart=always  \
-p 8080:8080 \
-p 50000:50000 \
-v $(which docker):/usr/bin/docker \
-v /var/run/docker.sock:/var/run/docker.sock \
-v $PWD/jenkins:/var/jenkins_home \
jenkins/jenkins:lts

# 查看密码
# cat /var/jenkins_home/secrets/initialAdminPassword
