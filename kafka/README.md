# Kafka 2.6 与 Kafka UI

从仓库根目录运行 `./kafka/docker/standalone_v2.sh`。脚本使用 ZooKeeper 模式，三个容器加入同一个 `container-play-kafka` Docker 网络；可用 `KAFKA_NETWORK` 覆盖网络名。

| 客户端 | 连接地址 | 用途 |
| --- | --- | --- |
| Kafka UI 及同网络容器 | `kafka:29092` | Broker 的 `INTERNAL` listener，UI 通过它获取可继续访问的 broker 元数据 |
| 当前宿主机 | `127.0.0.1:9092` | Broker 的 `EXTERNAL` listener，默认仅本机可访问 |
| 其他机器 | `KAFKA_EXTERNAL_HOST:9092` | 需设置可从客户端访问的 `KAFKA_EXTERNAL_HOST`，并设置相应的 `HOST_BIND_ADDRESS` |

例如要从局域网访问：

```bash
HOST_BIND_ADDRESS=0.0.0.0 KAFKA_EXTERNAL_HOST=192.168.1.20 ./kafka/docker/standalone_v2.sh
```

`KAFKA_EXTERNAL_HOST` 是 broker 返回给客户端的地址，不能填写 `0.0.0.0`。ZooKeeper 的 2181 和 broker 内部的 29092 不向宿主机发布；Kafka UI 默认在 `127.0.0.1:8080`，宿主机 Kafka 客户端默认连接 `127.0.0.1:9092`。在启动前需要确保这些端口未被其他示例占用。

该配置参照 [Kafka 2.6 的 `advertised.listeners` 说明](https://kafka.apache.org/26/generated/kafka_config.html) 和 [Kafka UI 的多 listener 示例](https://github.com/provectus/kafka-ui/blob/master/documentation/compose/kafka-ui.yaml)。

## Kafka 3.9 KRaft 与 Kafka UI

`./kafka/compose/standalone_kraft.sh` 使用 Apache 官方 `apache/kafka:3.9.1` 镜像启动单节点 KRaft broker 和 Kafka UI，无需 ZooKeeper。两者共用 `container-play-kafka-kraft` 网络：UI 连接 `kafka:29092`，宿主机客户端默认连接 `127.0.0.1:9092`，UI 默认发布在 `127.0.0.1:8080`。与上面的 Kafka 2.6 示例占用相同的宿主机端口，不能同时启动。

`HOST_BIND_ADDRESS` 控制宿主机监听地址，`KAFKA_EXTERNAL_HOST` 控制 broker 返回给外部客户端的地址。例如从局域网访问：

```bash
HOST_BIND_ADDRESS=0.0.0.0 KAFKA_EXTERNAL_HOST=192.168.1.20 ./kafka/compose/standalone_kraft.sh
```

KRaft 示例使用镜像内的 `/tmp/kraft-combined-logs`，适合一次性本地演示；移除容器会丢失该 broker 数据。配置参照 [Apache Kafka 3.9 官方 Docker 示例](https://github.com/apache/kafka/blob/trunk/docker/examples/docker-compose-files/single-node/plaintext/docker-compose.yml)和 [Kafka UI 内网地址示例](https://github.com/provectus/kafka-ui/blob/master/documentation/compose/kafka-ui.yaml)。

入口默认执行 `up`，也支持 `down`、`clean`、`ps`、`logs -f` 和 `config --quiet`。例如 `./kafka/compose/standalone_kraft.sh logs -f` 跟踪日志，`./kafka/compose/standalone_kraft.sh down` 停止服务。这个示例没有持久化卷，因此 `down` 和 `clean` 都会丢失 broker 数据；`clean` 额外执行 Compose 的卷清理。
