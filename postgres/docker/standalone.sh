#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name postgres \
--hostname postgres \
--restart=unless-stopped \
-p 5432:5432 \
-e POSTGRES_PASSWORD=Admin123 \
-v $PWD/postgres:/var/lib/postgresql \
postgres:18.1
