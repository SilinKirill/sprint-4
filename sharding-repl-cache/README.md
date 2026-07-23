# pymongo-api

## Как запустить

Перейдите в каталог проекта

```shell
cd sharding-repl-cache
```

Запускаем MongoDB, Redis и приложение

```shell
docker compose up -d
```

Инициализируем конфигурационный сервер, набор реплик каждого шарда и шардирование базы данных

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

### Проверяем работу Redis

```shell
docker compose exec -T redis redis-cli ping
```

Ожидаемый результат: `PONG`

### Проверяем кеширование

Выполните запрос несколько раз

```shell
curl -o /dev/null -s -w '%{time_total}\n' http://localhost:8080/helloDoc/users
```

Первый запрос получает данные из MongoDB и сохраняет результат в Redis. Второй и последующие запросы получают данные из кеша и должны выполняться менее чем за `0.1` секунды.

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