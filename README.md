# Container Play

这是一个容器化软件的快速部署集合，包含各种常用软件的 Docker 运行脚本。

## 目录说明

### 📚 文档
- **doc/** - Docker 相关的文档和使用指南

### 🔧 开发工具
- **gitea/** - 轻量级的自托管 Git 服务平台，类似 GitHub
- **golang/** - Go 语言开发环境容器化配置
- **svn/** - Subversion 版本控制系统

### 📊 监控与可视化
- **grafana/** - 开源的数据可视化和监控平台
- **prometheus/** - 开源的系统监控和告警工具
- **node-exporter/** - Prometheus 的硬件和系统指标导出器

### 🗄️ 数据库
- **mysql/** - 流行的开源关系型数据库管理系统
- **mongodb/** - 面向文档的 NoSQL 数据库
- **redis/** - 高性能的内存键值数据库
- **pika/** - 兼容 Redis 协议的持久化存储数据库
- **kvrocks/** - 基于 RocksDB 的分布式键值存储，兼容 Redis 协议

### 🌐 Web 服务
- **nginx/** - 高性能的 HTTP 服务器和反向代理服务器
- **openresty/** - 基于 Nginx 和 LuaJIT 的 Web 平台
- **phpmyadmin/** - MySQL 的 Web 管理界面工具

### 🔄 中间件
- **kafka/** - 分布式事件流平台和消息队列系统
- **nats/** - 高性能的云原生消息系统
- **nacos/** - 动态服务发现、配置管理和服务管理平台

### 🚀 应用平台
- **parseplatform/** - 开源的后端即服务(BaaS)平台
- **gridstudio/** - 基于浏览器的数据科学和机器学习集成环境

## 使用方式

每个子目录下的 `docker/` 文件夹中包含了对应软件的 Docker 运行脚本，通常以 `standalone.sh` 命名。

示例：
```bash
# 运行 Redis
./redis/docker/standalone_v7.sh

# 运行 MySQL
./mysql/docker/standalone_v8.sh

# 运行 Grafana
./grafana/docker/standalone.sh
```

## 注意事项

- 运行脚本前请确保已安装 Docker
- 部分服务可能需要配置环境变量或挂载配置文件
- 单机示例可不设置环境变量直接启动；默认密码 `Admin123` 仅供本机开发使用
- `HOST_BIND_ADDRESS` 控制单机脚本和 Compose 对宿主机发布端口的监听地址，默认 `127.0.0.1`；例如 `HOST_BIND_ADDRESS=0.0.0.0 ./grafana/docker/standalone.sh`
- 可在运行前通过环境变量覆盖默认值，例如 `MYSQL_ROOT_PASSWORD="$(openssl rand -hex 24)" ./mysql/docker/standalone_v8.sh`
- 如果数据目录已经初始化，修改环境变量不会自动更改数据库中已有的密码
- 详细的配置说明请参考各子目录中的 README.md 文件

常用脚本可覆盖的环境变量：

| 服务 | 可覆盖变量与默认行为 |
| --- | --- |
| MySQL / PostgreSQL / MongoDB 4 与 7 单节点 | `MYSQL_ROOT_PASSWORD` / `POSTGRES_PASSWORD` / `MONGO_INITDB_ROOT_PASSWORD`：默认密码均为 `Admin123` |
| Redis / Pika / Grafana | `REDIS_PASSWORD` / `PIKA_PASSWORD` / `GRAFANA_ADMIN_PASSWORD`：默认密码均为 `Admin123` |
| Consul | `CONSUL_MANAGEMENT_TOKEN`：未设置时生成 UUID 并保存到 `consul/.management-token`，后续运行复用 |
| Nacos | `NACOS_AUTH_TOKEN`、`NACOS_AUTH_IDENTITY_KEY` 有本地演示默认值；`NACOS_AUTH_IDENTITY_VALUE` 和 MySQL 版的 `MYSQL_SERVICE_PASSWORD` 默认为 `Admin123` |
| Parse / Apollo / YApi | `PARSE_MASTER_KEY`、`APOLLO_DB_PASSWORD`、`YAPI_ADMIN_PASSWORD`、`YAPI_DB_PASS` 默认使用 `Admin123`；`PARSE_APP_ID` 仍默认 `container-play-local`；`PARSE_DATABASE_URI` 默认连接本仓库的 MongoDB 4 容器；YApi 管理员账号默认为 `admin@docker.yapi` |
| Alertmanager | `ALERT_WEBHOOK_URL`：未设置时使用空接收器，设置后启用 webhook |
| Mongo Express | `ME_CONFIG_BASICAUTH_USERNAME`、`ME_CONFIG_MONGODB_SERVER`、`ME_CONFIG_MONGODB_ADMINUSERNAME` 默认分别为 `admin`、`mongo`、`admin`；两个密码变量默认 `Admin123` |

Nacos MySQL 版仍需先创建 `nacos` 数据库及账号；Apollo、YApi、Parse、Mongo Express 仍需各自依赖的数据库先可用。需要从其他机器访问时，应先替换演示凭据，再明确调整端口监听地址。
CloudBeaver 若检测到已运行的 `mysql` 容器，会自动连接到同一 Docker 桥接网络并提供 `mysql` 主机名；也可通过 `CLOUDBEAVER_LINK_MYSQL=true/false` 显式选择。

### 监控组件的单机脚本

从仓库根目录依次运行：

```bash
./alertmanager/docker/standalone.sh
./node-exporter/docker/standalone.sh
./prometheus/docker/standalone.sh
./grafana/docker/standalone.sh
```

这些脚本共用 `container-play-monitoring` Docker 网络，容器通过名称相互访问。可用 `MONITORING_NETWORK` 为所有脚本指定另一网络名。Prometheus 默认抓取 Node Exporter、将告警发送给 Alertmanager，并包含 `InstanceDown` 规则；Grafana 默认预置 Prometheus 数据源。可选的 `prometheus-alert/docker/standalone.sh` 也加入该网络，但需自行设置 `ALERT_WEBHOOK_URL` 才能接收通知。未设置该变量时，Alertmanager 接收告警但不向外发送通知。Node Exporter 在桥接网络下的部分网络指标可能反映容器命名空间，Docker Desktop 的宿主机指标范围也可能不同。

## 尚未实现的集群脚本

以下脚本明确以非零状态退出，避免被误认为已成功部署：

| 软件 | 尚未实现的脚本 |
| --- | --- |
| MySQL | `group_replication_v8.sh`、`master_master_v8.sh`、`master_slave_v8.sh`、`proxy_cluster_v8.sh` |
| Redis | `master_slave_v8.sh`、`sentinel_v8.sh` |
| MongoDB 4 | `multi_shard_cluster_v4.sh`、`replica_set_v4.sh`、`single_shard_cluster_v4.sh` |
| Kafka | `standalone_kraft.sh` |

MongoDB 7 的单分片 Compose 和认证单节点示例见 `mongodb/README.md`；MongoDB 6 Compose 保留供已有数据迁移参考。

### docker-compose
本仓库使用 `docker compose` 命令和当前的 [Compose Specification](https://docs.docker.com/reference/compose-file/)。
Compose 文件不需要顶层 `version` 字段；可用 `docker compose -f <配置文件> config --quiet` 做离线配置检查。
