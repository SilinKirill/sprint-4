# pymongo-api

## Как запустить

Перейдите в каталог проекта

```shell
cd mongo-sharding
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

### Проверяем общее количество документов в базе

```shell
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
```

### Проверяем количество документов на первом шарде

```shell
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
```

### Проверяем количество документов на втором шарде

```shell
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
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