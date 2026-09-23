# MySQL 示例

从仓库根目录运行脚本。四种集群脚本均使用 `mysql:8.0`，数据写入各自 Compose 项目的命名卷；`standalone_v8.sh` 是单独的 MySQL 8.4 单节点脚本，不与这些卷共用。主从示例的默认 3306 与单节点脚本冲突，应先停止其中一个或修改 `MYSQL_PRIMARY_HOST_PORT`。所有发布端口默认只监听 `127.0.0.1`，可用 `HOST_BIND_ADDRESS` 覆盖。默认 root、复制用户和应用用户密码都是 `Admin123`，仅用于本机实验；可分别覆盖 `MYSQL_ROOT_PASSWORD`、`MYSQL_REPLICATION_PASSWORD`、`MYSQL_APP_PASSWORD`。复制和应用密码为了安全嵌入初始化 SQL，只接受字母、数字以及 `._~!@#%+=:-`。

## 主从复制

```bash
./mysql/compose/master_slave_v8.sh
docker compose -f mysql/compose/docker-compose-replication.yaml exec mysql-replica mysql -uroot -p -e 'SHOW REPLICA STATUS\G'
```

主库默认在 `127.0.0.1:3306`，只读副本在 `127.0.0.1:3307`。复制使用 GTID 自动定位。副本设置 `read_only` 与 `super_read_only`，写入应连接主库。初始化服务检查两条复制线程为 `Yes` 才成功。端口可通过 `MYSQL_PRIMARY_HOST_PORT`、`MYSQL_REPLICA_HOST_PORT` 修改。

## 双主异步复制

```bash
./mysql/compose/master_master_v8.sh
docker compose -f mysql/compose/docker-compose-dual.yaml exec mysql-a mysql -uroot -p -e 'SHOW REPLICA STATUS\G'
docker compose -f mysql/compose/docker-compose-dual.yaml exec mysql-b mysql -uroot -p -e 'SHOW REPLICA STATUS\G'
```

两个节点默认分别在 3310、3311；可用 `MYSQL_DUAL_A_HOST_PORT`、`MYSQL_DUAL_B_HOST_PORT` 调整。双向 GTID 复制配置了奇偶自增偏移，用于降低自动生成主键冲突的概率。它仍是**异步复制**，同一行的并发写入可能冲突，不能当作强一致的多主数据库；本例适合观察复制行为，不适合直接承担生产写流量。

## Group Replication 单主组

```bash
./mysql/compose/group_replication_v8.sh
docker compose -f mysql/compose/docker-compose-group.yaml exec mysql-gr1 mysql -uroot -p -e 'SELECT MEMBER_HOST,MEMBER_STATE,MEMBER_ROLE FROM performance_schema.replication_group_members'
```

三个成员默认分别发布到 3321、3322、3323，可用 `MYSQL_GR1_HOST_PORT`、`MYSQL_GR2_HOST_PORT`、`MYSQL_GR3_HOST_PORT` 调整。初始化服务在全新项目上引导第一节点，并依次加入另外两节点；全部停止后重启时，再运行脚本，它会比较各成员的 GTID 集合，仅从包含全部已执行事务的成员重新引导，无法确定时会报错供人工恢复。服务要求三者均达到 `ONLINE`。实际主节点由 `MEMBER_ROLE=PRIMARY` 标识；发生选主后不要假设 3321 始终可写。三个容器仍在同一宿主机，只供本地演示。

## ProxySQL + 主从

```bash
./mysql/compose/proxy_cluster_v8.sh
mysql -h 127.0.0.1 -P 6033 -u demo -p demo
```

这个脚本启动**同一个**主从 Compose 项目，额外启用 ProxySQL 及配置服务；不要把它与双主或组复制脚本当成同一个集群。代理默认发布在 6033，可用 `MYSQL_PROXY_HOST_PORT` 改。应用账号为 `demo`，密码由 `MYSQL_APP_PASSWORD` 控制。普通写请求走主库，`SELECT` 走副本，`SELECT ... FOR UPDATE` 走主库。异步副本有延迟，刚写入就读取时可能暂时看不到。ProxySQL 管理端口 6032 只在 Compose 网络内部开放，不发布到宿主机。

四个 Compose 入口默认执行 `up`，也支持 `down`、`clean`、`ps`、`logs -f` 和 `config --quiet`。例如 `./mysql/compose/proxy_cluster_v8.sh down` 停止整个主从与代理项目并保留数据；`clean` 还会删除命名卷。主从与代理入口共用项目，任一入口的 `down` 或 `clean` 都作用于整个项目。数据卷已有账号时，改环境变量不会自动改 root 密码；新密码应在空卷首次初始化时提供。

实现遵循 [MySQL GTID 自动定位](https://dev.mysql.com/doc/refman/8.0/en/replication-gtids-auto-positioning.html)、[Group Replication 配置与引导](https://dev.mysql.com/doc/refman/8.0/en/group-replication-configuring-instances.html)及 [ProxySQL 配置说明](https://proxysql.com/documentation/getting-started)。
