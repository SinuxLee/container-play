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
- 详细的配置说明请参考各子目录中的 README.md 文件
