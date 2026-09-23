#!/usr/bin/env bash
set -ueo pipefail

export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-Admin123}"

docker run -d \
--name postgres \
--hostname postgres \
--restart=unless-stopped \
-p "${HOST_BIND_ADDRESS:-127.0.0.1}:5432:5432" \
-e POSTGRES_PASSWORD \
-v "$PWD/postgres:/var/lib/postgresql" \
postgres:18.1
