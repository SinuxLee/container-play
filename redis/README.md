# Redis 8 主从与 Sentinel 示例

从仓库根目录运行主从脚本：

```bash
./redis/compose/master_slave_v8.sh
```

需要 Sentinel 时可直接运行下列脚本，它会一并启动主从节点和三个 Sentinel：

```bash
./redis/compose/sentinel_v8.sh
```

两者共用 `container-play-redis8` Compose 项目及网络。主节点在宿主机 `127.0.0.1:6379`，副本在 `127.0.0.1:6380`；`HOST_BIND_ADDRESS` 可覆盖监听地址。所有 Redis 节点使用 `REDIS_PASSWORD`，默认 `Admin123`。主副本都设置 `requirepass` 和 `masterauth`，以便 Sentinel 故障转移后角色互换。与其他占用 6379 端口的 Redis 示例不要同时启动。

检查复制状态：

```bash
docker compose -f redis/compose/docker-compose-v8.yaml exec redis-master sh -c 'REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli INFO replication'
docker compose -f redis/compose/docker-compose-v8.yaml exec redis-replica sh -c 'REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli INFO replication'
```

Sentinel 监听 `mymaster`，使用 2 票 quorum。其地址仅在同一 Docker 网络内有效：`redis-sentinel-1:26379`、`redis-sentinel-2:26379`、`redis-sentinel-3:26379`。应用容器需要加入 `container-play-redis8_default` 网络，并通过 Sentinel 发现当前主节点；宿主机直接连接固定的 6379/6380 端口不会随故障转移自动改连主节点。

检查 Sentinel：

```bash
docker compose -f redis/compose/docker-compose-v8.yaml --profile sentinel exec redis-sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
docker compose -f redis/compose/docker-compose-v8.yaml --profile sentinel exec redis-sentinel-1 redis-cli -p 26379 SENTINEL CKQUORUM mymaster
```

Sentinel 配置保存在各自的命名卷中，故障转移后不能在重启时覆盖。如覆盖 `REDIS_PASSWORD`，两次运行脚本都需使用相同的值；首次初始化后更改密码还需同步更新已保存的 Sentinel 认证配置。默认密码只适合本机演示。两个脚本可重复执行，Compose 会复用已有项目。入口默认执行 `up`，也支持 `down`、`clean`、`ps`、`logs -f` 和 `config --quiet`。例如 `./redis/compose/sentinel_v8.sh down` 会停止整个项目并保留数据；`clean` 还会删除主从与 Sentinel 的命名卷。两个入口共用项目，任一入口的 `down` 或 `clean` 都作用于整个项目。三个 Sentinel 都在同一宿主机上，不提供宿主机故障容错。

配置依据：[Redis 复制文档](https://redis.io/docs/latest/operate/oss_and_stack/management/replication/)和[Redis Sentinel 文档](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/)。
