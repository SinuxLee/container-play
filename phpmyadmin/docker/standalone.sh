#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name phpmyadmin \
-e PMA_HOST=mysql \
-e PMA_PORT=3306 \
-p 13306:80 \
--restart always  \
phpmyadmin/phpmyadmin:5.2
