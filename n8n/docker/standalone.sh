docker run -d \
--name n8n \
-p 5678:5678 \
-e GENERIC_TIMEZONE="Asia/Shanghai" \
-e TZ="Asia/Shanghai" \
-e DB_TYPE=postgresdb \
-e DB_POSTGRESDB_DATABASE=n8n \
-e DB_POSTGRESDB_HOST=ffa-db.diandian.info \
-e DB_POSTGRESDB_PORT=5432 \
-e DB_POSTGRESDB_USER=postgres \
-e DB_POSTGRESDB_SCHEMA=public \
-e DB_POSTGRESDB_PASSWORD=Admin123 \
-v $PWD/n8n:/home/node/.n8n \
n8nio/n8n:2.33.4
 