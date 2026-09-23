
- Prometheus :9090
- Alertmanager :9093
- Grafana :3000（用户 admin；`GRAFANA_ADMIN_PASSWORD` 默认 `Admin123`，可覆盖）

启动：`docker compose up -d`。端口默认仅绑定本机；`HOST_BIND_ADDRESS` 可覆盖宿主机监听地址，对外提供服务前请覆盖演示密码。
Alertmanager 的 default receiver 尚未配置通知渠道，需要按部署环境补充。
Node Exporter 与 Prometheus 在同一 Docker 网络，通过 `node-exporter:9100` 采集；桥接网络下的部分网络指标可能反映容器命名空间，Docker Desktop 的宿主机指标范围也可能不同。
Grafana 会预置 `http://prometheus:9090` 数据源。
