#!/usr/bin/env bash
set -ue

# 先启动 zookeeper
docker run -d --name zookeeper \
-p 2181:2181 \
--restart=unless-stopped \
-e ALLOW_ANONYMOUS_LOGIN=yes \
bitnamilegacy/zookeeper:3.6

# 再启动 kafka
# ADVERTISED_LISTENERS 表示上报给 zookeeper 的服务地址
docker run -d --name kafka \
--restart=unless-stopped \
--link zookeeper:zookeeper \
-v $PWD/kafka:/bitnami/kafka \
-p 9092:9092 \
-p 9093:9093 \
-e KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181 \
-e KAFKA_BROKER_ID=1 \
-e KAFKA_CFG_PROCESS_ROLES=controller,broker \
-e KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE=true \
-e KAFKA_CFG_AUTO_LEADER_REBALANCE_ENABLE=true \
-e KAFKA_CFG_KRAFT_STORAGE_FORMAT=true \
-e ALLOW_PLAINTEXT_LISTENER=yes \
-e KAFKA_CFG_LISTENERS=INTERNAL://:9092,EXTERNAL://:9093 \
-e KAFKA_CFG_ADVERTISED_LISTENERS=INTERNAL://localhost:9092,EXTERNAL://host.docker.internal:9093 \
-e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT \
-e KAFKA_CFG_INTER_BROKER_LISTENER_NAME=INTERNAL \
bitnamilegacy/kafka:2.6.0 # 阿里云非 serverless 仅支持 2.x

# 可视化客户端
# 可以在 container 内使用 host.docker.internal:PORT 来访问宿主机服务
docker run -d \
-p 8080:8080 \
--restart=unless-stopped \
-e KAFKA_CLUSTERS_0_NAME=local \
-e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=host.docker.internal:9093 \
-e DYNAMIC_CONFIG_ENABLED=true \
--name kafka-ui \
provectuslabs/kafka-ui
