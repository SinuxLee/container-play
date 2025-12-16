#!/usr/bin/env bash
set -ueo pipefail

docker run -d \
--name prometheusalert \
--hostname prometheusalert \
-p 8080:8080 \
-v $PWD/prometheusalert:/app/conf \
feiyu563/prometheus-alert:v4.9.2
