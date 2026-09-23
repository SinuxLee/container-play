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
