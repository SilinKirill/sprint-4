# pymongo-api

## Как запустить

Перейдите в каталог проекта

```shell
cd mongo-sharding-repl
```

Запускаем MongoDB и приложение

```shell
docker compose up -d
```

Инициализируем конфигурационный сервер, шарды и шардирование базы данных

```shell
./scripts/init-sharding.sh
```

Заполняем MongoDB данными

```shell
./scripts/mongo-init.sh
```

## Как проверить

### Проверяем состояние шардированного кластера

```shell
docker compose exec -T mongos_router mongosh --port 27020 --quiet --eval 'sh.status()'
```

### Проверяем состояние реплик первого шарда

```shell
docker compose exec -T shard1-1 mongosh --port 27018 --quiet --eval 'rs.status()'
```

### Проверяем состояние реплик второго шарда

```shell
docker compose exec -T shard2-1 mongosh --port 27019 --quiet --eval 'rs.status()'
```

В каждом replica set должно быть три участника: один PRIMARY и два SECONDARY.

### Проверяем общее количество документов в базе

```shell
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
```

### Проверяем количество документов на репликах первого шарда

```shell
docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
```

```shell
docker compose exec -T shard1-2 mongosh --port 27021 --quiet <<EOF
rs.secondaryOk()
use somedb
db.helloDoc.countDocuments()
EOF
```

```shell
docker compose exec -T shard1-3 mongosh --port 27022 --quiet <<EOF
rs.secondaryOk()
use somedb
db.helloDoc.countDocuments()
EOF
```

### Проверяем количество документов на репликах второго шарда

```shell
docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
```

```shell
docker compose exec -T shard2-2 mongosh --port 27023 --quiet <<EOF
rs.secondaryOk()
use somedb
db.helloDoc.countDocuments()
EOF
```

```shell
docker compose exec -T shard2-3 mongosh --port 27024 --quiet <<EOF
rs.secondaryOk()
use somedb
db.helloDoc.countDocuments()
EOF
```

### Если вы запускаете проект на локальной машине

Откройте в браузере http://localhost:8080

### Если вы запускаете проект на предоставленной виртуальной машине

Узнать белый IP виртуальной машины

```shell
curl --silent http://ifconfig.me
```

Откройте в браузере http://<ip виртуальной машины>:8080

## Доступные эндпоинты

Список доступных эндпоинтов, swagger http://<ip виртуальной машины>:8080/docs