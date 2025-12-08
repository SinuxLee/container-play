### 安装
```bash
# 安装 docker-compose v2 ,新版本变成 Docker CLI 插件啦
yum install -y docker-compose-plugin

# 需要使用这种方式调用，docker-compose 方式被废弃了
docker compose -v
```

### 使用案例
```bash
# 退出时清理容器在磁盘持久化的数据
docker compose down --volumes
```