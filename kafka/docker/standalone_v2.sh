#!/usr/bin/env bash
set -ueo pipefail

HOST_BIND_ADDRESS="${HOST_BIND_ADDRESS:-127.0.0.1}"
KAFKA_EXTERNAL_HOST="${KAFKA_EXTERNAL_HOST:-$HOST_BIND_ADDRESS}"
KAFKA_NETWORK="${KAFKA_NETWORK:-container-play-kafka}"
if [[ "$KAFKA_EXTERNAL_HOST" == 0.0.0.0 || "$KAFKA_EXTERNAL_HOST" == '::' ]]; then
  echo 'Set KAFKA_EXTERNAL_HOST to an address clients can reach; 0.0.0.0 cannot be advertised' >&2
  exit 2
fi

docker network create "$KAFKA_NETWORK" >/dev/null 2>&1 || docker network inspect "$KAFKA_NETWORK" >/dev/null

# 先启动 zookeeper
docker run -d --name zookeeper \
--hostname zookeeper \
--network "$KAFKA_NETWORK" \
--restart=unless-stopped \
-e ALLOW_ANONYMOUS_LOGIN=yes \
bitnamilegacy/zookeeper:3.6

# Broker advertises a Docker DNS name to the UI and a host address to local clients.
docker run -d --name kafka \
--hostname kafka \
--network "$KAFKA_NETWORK" \
--restart=unless-stopped \
-v "$PWD/kafka:/bitnami/kafka" \
-p "$HOST_BIND_ADDRESS:9092:9092" \
-e KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181 \
-e KAFKA_CFG_BROKER_ID=1 \
-e KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE=true \
-e KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
-e KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 \
-e KAFKA_CFG_TRANSACTION_STATE_LOG_MIN_ISR=1 \
-e ALLOW_PLAINTEXT_LISTENER=yes \
-e KAFKA_CFG_LISTENERS=INTERNAL://:29092,EXTERNAL://:9092 \
-e "KAFKA_CFG_ADVERTISED_LISTENERS=INTERNAL://kafka:29092,EXTERNAL://$KAFKA_EXTERNAL_HOST:9092" \
-e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT \
-e KAFKA_CFG_INTER_BROKER_LISTENER_NAME=INTERNAL \
bitnamilegacy/kafka:2.6.0 # 阿里云非 serverless 仅支持 2.x

# Kafka UI connects through the INTERNAL listener on the shared Docker network.
docker run -d \
--name kafka-ui \
--hostname kafka-ui \
-p "$HOST_BIND_ADDRESS:8080:8080" \
--network "$KAFKA_NETWORK" \
--restart=unless-stopped \
-e KAFKA_CLUSTERS_0_NAME=local \
-e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=kafka:29092 \
-e DYNAMIC_CONFIG_ENABLED=true \
provectuslabs/kafka-ui
