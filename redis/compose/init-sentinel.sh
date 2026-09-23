#!/bin/sh
set -eu

config_path="${SENTINEL_CONFIG_PATH:-/data/sentinel.conf}"

if [ ! -f "$config_path" ]; then
  if [ "$(printf '%s' "$REDIS_PASSWORD" | wc -l)" -gt 0 ]; then
    echo 'REDIS_PASSWORD must not contain a newline' >&2
    exit 2
  fi
  escaped_password=$(printf '%s' "$REDIS_PASSWORD" | sed 's/\\/\\\\/g; s/"/\\"/g')
  cat > "$config_path" <<EOF
port 26379
bind 0.0.0.0
dir /data
sentinel resolve-hostnames yes
sentinel announce-hostnames yes
sentinel monitor mymaster redis-master 6379 2
sentinel auth-pass mymaster "$escaped_password"
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
EOF
fi

exec redis-server "$config_path" --sentinel
