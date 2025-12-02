#!/usr/bin/env bash
set -ue

docker run -d \
--name svn \
-p 80:80 \
-p 3690:3690 \
-v $PWD/svn/repo:/home/svn \
-v $PWD/svn/config:/etc/subversion \
elleflorio/svn-server:latest
