#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
compose=(docker compose -f "$script_dir/docker-compose-v4-replica-set.yaml")
up=("${compose[@]}")
manage=("${compose[@]}")

usage() {
  printf '用法: %s [up|down|clean|ps|logs|config|help] [Compose 选项]\n' "$(basename "$0")"
  printf '%s\n' 'up 默认后台启动；down 保留数据卷；clean 删除数据卷'
  printf '%s\n' 'ps 查看状态；logs -f 跟踪日志；config --quiet 校验配置'
}

action="${1:-up}"
if (($# > 0)); then shift; fi
case "$action" in
  up)
    "${up[@]}" up -d "$@" ;;
  down) "${manage[@]}" down "$@" ;;
  clean)
    if (($# > 0)); then echo "clean 不接受额外参数" >&2; exit 2; fi
    printf '将删除此 Compose 项目的容器和数据卷：%s\n' "$script_dir/docker-compose-v4-replica-set.yaml" >&2
    "${manage[@]}" down --volumes ;;
  ps) "${manage[@]}" ps "$@" ;;
  logs) "${manage[@]}" logs --tail=100 "$@" ;;
  config) "${manage[@]}" config "$@" ;;
  help|-h|--help) usage ;;
  *) printf '未知操作: %s\n' "$action" >&2; usage >&2; exit 2 ;;
esac
