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

docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
    _id: "shard1",
    members: [
        {_id: 0, host: "shard1:27018"}
    ]
})
EOF

###
# Инициализируем второй шард
###

docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate({
    _id: "shard2",
    members: [
        {_id: 0, host: "shard2:27019"}
    ]
})
EOF

sleep 5

###
# Добавляем шарды и включаем шардирование
###

docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard("shard1/shard1:27018")
sh.addShard("shard2/shard2:27019")

sh.enableSharding("somedb")

use somedb
db.createCollection("helloDoc")

sh.shardCollection(
    "somedb.helloDoc",
    {_id: "hashed"}
)
EOF