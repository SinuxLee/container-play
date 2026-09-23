
- ES :9200
- Kibana :5601

这是本机开发示例：Elasticsearch 认证关闭，两个 Web 端口默认绑定 `127.0.0.1`，可通过 `HOST_BIND_ADDRESS` 覆盖。请勿在未启用认证时对外暴露。
Fluent Bit 从 Linux Docker 的 `/var/lib/docker/containers` 读取 JSON 日志；其他日志驱动或 Docker Desktop 需调整输入源。
