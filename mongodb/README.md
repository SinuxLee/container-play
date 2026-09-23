# MongoDB 示例

## MongoDB 7.0 单分片集群

从仓库根目录运行：

```bash
docker compose --env-file mongodb/compose/mongo.env -f mongodb/compose/docker-compose-v7-single-shard.yaml up -d
docker compose --env-file mongodb/compose/mongo.env -f mongodb/compose/docker-compose-v7-single-shard.yaml ps
```

Compose 会启动单节点配置服务器副本集、单节点分片副本集和 mongos，并通过一次性初始化服务注册分片。`mongo.env` 通过 `--env-file` 实际参与 Compose 插值，控制 `MONGODB_IMAGE_TAG`、`HOST_BIND_ADDRESS` 和 `MONGODB_HOST_PORT`；也可用同名外部环境变量覆盖。仅 mongos 的 27017 容器端口发布到宿主机，默认地址是 `127.0.0.1:27017`。这是**无认证的本地演示**，不要直接改成公网监听。旧文件中的密码和副本集密钥变量已移除，因为仅把它们传给容器并不会启用 MongoDB 认证。若需要带账号密码的本机实例，使用下文的 MongoDB 7 单节点脚本。

此 7.0 示例的 Compose 项目名为 `container-play-mongodb7`，数据保存在它自己的 `cfg_data` 和 `shard0_data` 命名卷中，不会直接复用原 6.0 示例的数据卷；两个示例若同时运行，需要给其中一个指定不同的宿主机端口。`docker-compose-v6-single-shard.yaml` 保留供已有 6.0 环境查看和迁移。**启动新示例不会自动迁移已有数据**：如需升级原集群，先备份并按 [MongoDB 官方 6.0→7.0 分片集群升级顺序](https://www.mongodb.com/docs/manual/release-notes/7.0-upgrade-sharded-cluster/)处理配置服务器、分片和 mongos，再确认 feature compatibility version；7.0 的 FCV 命令需要 `confirm: true`。不要直接把旧卷挂到这个新项目。

检查分片注册情况：

```bash
docker compose --env-file mongodb/compose/mongo.env -f mongodb/compose/docker-compose-v7-single-shard.yaml exec mongodb-mongos mongosh --eval 'sh.status()'
```

清理容器时保留数据用 `down`；确认不再需要数据后才用 `down --volumes`。7.0 的 `--configsvr --replSet`、`--shardsvr --replSet` 和 mongos 的 `--configdb` 启动参数仍见于 [官方 7.0 升级文档](https://www.mongodb.com/docs/manual/release-notes/7.0-upgrade-sharded-cluster/)。

需要修改连接端口时，可在命令前设置 `MONGODB_HOST_PORT=27018`；外部环境变量会覆盖 `mongo.env` 中的值。保留 `MONGODB_IMAGE_TAG` 在 7.0 系列，不要靠改成其他主版本来升级已有数据卷。

### 测试和诊断命令

对 MongoDB 7 分片示例，先进入 mongos：

```bash
docker compose --env-file mongodb/compose/mongo.env -f mongodb/compose/docker-compose-v7-single-shard.yaml exec mongodb-mongos mongosh
```

```javascript
use test
db.user.insertMany([{ name: 'libz', age: 30 }, { name: 'demo', age: 31 }])
db.user.createIndex({ _id: 'hashed' })
sh.shardCollection('test.user', { _id: 'hashed' })
db.user.getShardDistribution()
sh.status()
db.serverStatus()
db.stats()
db.user.stats()
```

MongoDB 7 对集合分片不要求先调用 `sh.enableSharding('test')`；非空集合需要先具备支持分片键的索引。参见 [MongoDB 分片命令说明](https://www.mongodb.com/docs/manual/reference/method/sh.shardcollection/)。副本集状态应在对应成员上检查，例如：

```bash
docker compose --env-file mongodb/compose/mongo.env -f mongodb/compose/docker-compose-v7-single-shard.yaml exec mongodb-shard0 mongosh --port 27018 --eval 'rs.status()'
```

## MongoDB 7.0 认证单节点

如果需要账号密码而不需要分片，从仓库根目录运行 `./mongodb/docker/standalone_v7.sh`。它使用官方镜像的 `MONGO_INITDB_ROOT_USERNAME` 和 `MONGO_INITDB_ROOT_PASSWORD` 初始化管理员，默认分别为 `admin` 和 `Admin123`，可在启动前通过环境变量覆盖；数据保存在仓库根目录的 `mongo7/`。已有数据目录不会因修改环境变量而重置密码。连接示例：

```bash
docker exec -it mongo7 mongosh admin -u admin -p --authenticationDatabase admin
```

这个单节点脚本和分片 Compose 默认都占用宿主机 27017；并行使用时给其中一个设置 `MONGODB_HOST_PORT`。旧 MongoDB 4 数据目录不能直接交给 7.0 脚本使用。

若同时使用仓库的 Mongo Express，在单节点启动后运行 `ME_CONFIG_MONGODB_SERVER=mongo7 ./mongo-express/docker/standalone.sh`，它会连接 `mongo7:27017`，默认管理员凭据也为 `admin` / `Admin123`。覆盖单节点的账号或密码时，也要设置对应的 `ME_CONFIG_MONGODB_ADMINUSERNAME` / `ME_CONFIG_MONGODB_ADMINPASSWORD`。

## MongoDB 4.4 副本集和分片集群

从仓库根目录运行下列任一脚本。它们使用 `mongo:4.4.25` 和旧版 `mongo` shell，专供本机学习；与下文的 MongoDB 4 认证单节点是相互独立的**无认证**部署。

```bash
./mongodb/compose/replica_set_v4.sh         # 三成员副本集 rsV4
./mongodb/compose/single_shard_cluster_v4.sh # 单分片 + mongos
./mongodb/compose/multi_shard_cluster_v4.sh  # 两分片 + mongos
```

副本集 Compose 项目名为 `container-play-mongo4-rs`，分片集群为 `container-play-mongo4-shards`，卷互不复用，也不复用 7.0 卷。单分片和双分片脚本操作的是**同一个**分片集群项目；后者添加第二个分片。默认都将 27017 绑定在本机，不能同时使用默认端口。可通过 `HOST_BIND_ADDRESS` 和分片集群专用的 `MONGODB_V4_HOST_PORT` 改变宿主机监听地址与端口，例如 `MONGODB_V4_HOST_PORT=27018 ./mongodb/compose/multi_shard_cluster_v4.sh`。改为非本机地址前应先配置认证与网络访问控制。

副本集成员通过 Compose 网络中的 `mongo-rs1`、`mongo-rs2`、`mongo-rs3` 相互发现。宿主机仅发布第一个成员，若从宿主机连接，应使用 `directConnection=true`；要验证整个副本集，请在 Compose 网络内运行：

```bash
docker compose -f mongodb/compose/docker-compose-v4-replica-set.yaml exec mongo-rs1 mongo --eval 'rs.status()'
docker compose -f mongodb/compose/docker-compose-v4-sharded.yaml exec mongodb-mongos mongo --eval 'sh.status()'
docker compose -f mongodb/compose/docker-compose-v4-sharded.yaml --profile multi exec mongodb-mongos mongo --eval 'sh.status()'
```

三个集群入口默认执行 `up`，也支持 `down`、`clean`、`ps`、`logs -f` 和 `config --quiet`。例如 `./mongodb/compose/multi_shard_cluster_v4.sh down` 停止分片项目并保留数据；`clean` 还会删除命名卷。单分片与双分片入口共用项目，任一入口的 `down` 或 `clean` 都作用于整个分片项目。MongoDB 4.4 已属于旧版示例，升级至 7.0 时须按官方升级路径逐级处理和备份，不能直接把这些卷挂到 7.0 容器。参考 [MongoDB 分片集群部署说明](https://www.mongodb.com/docs/manual/tutorial/deploy-shard-cluster/) 和 [MongoDB 版本升级路径](https://www.mongodb.com/docs/mongodb-versions/)。

## MongoDB 4 单节点（旧版示例）

`mongodb/docker/standalone_v4.sh` 是独立示例，`MONGO_INITDB_ROOT_PASSWORD` 默认 `Admin123`，也可通过环境变量覆盖。它和上面的分片集群占用相同的本机端口，请勿同时启动。

### 启停

从仓库根目录运行 `./mongodb/docker/standalone_v4.sh`。停止容器可用 `docker stop mongo`；需要移除容器时再用 `docker rm mongo`。数据保存在仓库根目录的 `mongo/`，移除容器不会删除该目录。原文中的 `docker-compose down --volumes` 会删除 Compose 命名卷，不适合用作日常停止命令。

### 账户管理

独立脚本会在空数据目录首次初始化时创建 `admin` 用户，密码取 `MONGO_INITDB_ROOT_PASSWORD`。若数据目录已经初始化，更改环境变量不会更新已有密码。连接并创建业务用户的示例：

```bash
docker exec -it mongo mongo admin -u admin -p 'Admin123' --authenticationDatabase admin
```

```javascript
use test
db.createUser({ user: 'appuser', pwd: 'Admin123', roles: [{ role: 'readWrite', db: 'test' }] })
db.getUsers()
db.auth('appuser', 'Admin123')
```

### 版本升级

原有笔记提醒：MongoDB 4.0 升级到 4.4 需要先经过 4.2。升级前备份数据并按对应版本的官方步骤处理 feature compatibility version；在**已经升级并验证的 4.2 实例**上，原笔记中的命令是：

```javascript
db.adminCommand({ setFeatureCompatibilityVersion: '4.2' })
```

不要只改镜像标签就跳过中间版本或直接复用旧数据目录。请参照 [MongoDB 版本升级路径](https://www.mongodb.com/docs/mongodb-versions/) 核对当前版本的具体步骤。

## MCP 示例

原 README 中的 MongoDB MCP 配置示例保留如下；连接串需替换为实际地址和凭据：

```json
{
  "mcpServers": {
    "mongodb": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "MDB_MCP_CONNECTION_STRING", "mcp/mongodb"],
      "env": {
        "MDB_MCP_CONNECTION_STRING": "mongodb+srv://username:password@cluster.mongodb.net/myDatabase"
      }
    }
  }
}
```
