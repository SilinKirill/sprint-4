#!/bin/bash

###
# Инициализируем конфигурационный сервер
###

docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate({
    _id: "config_server",
    configsvr: true,
    members: [
        {_id: 0, host: "configSrv:27017"}
    ]
})
EOF

sleep 5

###
# Инициализируем первый шард
###

docker compose exec -T shard1-1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
    _id: "shard1",
    members: [
        {_id: 0, host: "shard1-1:27018", priority: 2},
        {_id: 1, host: "shard1-2:27021", priority: 1},
        {_id: 2, host: "shard1-3:27022", priority: 1}
    ]
})
EOF

###
# Инициализируем второй шард
###

docker compose exec -T shard2-1 mongosh --port 27019 --quiet <<EOF
rs.initiate({
    _id: "shard2",
    members: [
        {_id: 0, host: "shard2-1:27019", priority: 2},
        {_id: 1, host: "shard2-2:27023", priority: 1},
        {_id: 2, host: "shard2-3:27024", priority: 1}
    ]
})
EOF

sleep 10

###
# Добавляем шарды и включаем шардирование
###

docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard(
    "shard1/shard1-1:27018,shard1-2:27021,shard1-3:27022"
)

sh.addShard(
    "shard2/shard2-1:27019,shard2-2:27023,shard2-3:27024"
)

sh.enableSharding("somedb")

use somedb
db.createCollection("helloDoc")

sh.shardCollection(
    "somedb.helloDoc",
    {_id: "hashed"}
)
EOF