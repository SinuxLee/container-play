#!/usr/bin/env bash
set -ueo pipefail

# https://github.com/ricklamers/gridstudio
docker run  -d \
--name=gridstudio \
-p 8080:8080 
-p 4430:4430 
-v $PWD/gridstudio/source:/home/source 
-v $PWD/gridstudio/userdata:/home/userdata 
ricklamers/gridstudio:release
