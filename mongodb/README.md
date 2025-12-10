
### 安装
```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down --volumes
```

### 账户管理
```bash
docker exec -it mongo mongo admin

# 创建一个名为 admin，密码为 123456 的用户。
db.createUser({ user:'admin', pwd:'123456', roles:[ { role:'userAdminAnyDatabase', db: 'admin'}]});

# 尝试使用上面创建的用户信息进行连接。
db.auth('admin', '123456')

# 创建超级用户
db.createUser({ user: "root" , pwd: "root", roles: ["root"]})
```

### 版本升级
mongodb 从4.0 -> 4.4 升级：需要先升级到 4.2 才能继续升 4.4
```js
// 启用 4.2 特新
db.adminCommand({ setFeatureCompatibilityVersion: "4.2" })
```

### 基本测试命令
```bash
# 登录服务
mongo -uroot -padmin
use test

# 插入数据
var i = 1000; while(i--) {db.user.insert({name:"libz",age:30})};

# 启用库分片, 同一个库的不同 collection 会分布到不同shard上，但是一个 collection 只会存在于一个 shard 上。
sh.enableSharding("test")
db.user.stats().sharded

# 启用表分片, 这张表会出现在所有 shard 上
db.user.ensureIndex({_id: "hashed"}) # 必须先创建此索引
sh.shardCollection("test.user",{ _id: "hashed" })

# 查看数据分布
db.user.getShardDistribution();
sh.status();
```

### MCP
```json
{
  "mcpServers": {
    "mongodb": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "MDB_MCP_CONNECTION_STRING",
        "mcp/mongodb"
      ],
      "env": {
        "MDB_MCP_CONNECTION_STRING": "mongodb+srv://username:password@cluster.mongodb.net/myDatabase"
      }
    }
  }
}
```