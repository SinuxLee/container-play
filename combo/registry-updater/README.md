# 本地镜像仓库与清理示例

`docker-compose.yaml` 将 Registry 和 UI 绑定在本机。UI 使用内置反向代理访问 Registry。
Watchtower 位于 `auto-update` profile，默认不运行；启用后只更新带 opt-in 标签的 UI。

```bash
docker compose up -d registry registry-ui
docker compose --profile auto-update up -d
```

清理脚本独立运行，默认只预览。仓库名通过 `REGISTRY_REPO` 指定；如 Registry 需要 Basic 认证，同时设置 `REGISTRY_USERNAME` 和 `REGISTRY_PASSWORD`。

```bash
REGISTRY_REPO=my/app python3 auto_clean_image.py
REGISTRY_REPO=my/app python3 auto_clean_image.py --apply
```

脚本保留最新 10 个数字版本标签，并保护所有非数字标签及与保留标签共享 digest 的 manifest。调整数量可设置 `REGISTRY_KEEP` 或传 `--keep`。请确认预览结果后再运行 `--apply`。删除 manifest 后，磁盘空间回收仍需按照 [Distribution 的垃圾回收流程](https://distribution.github.io/distribution/about/garbage-collection/)执行。
