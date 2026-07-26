# Задание 7. Проектирование схем коллекций для шардирования данных

## 1. Итоговое решение

| Коллекция  | Стратегия                                     | Shard key                               |
|------------|-----------------------------------------------|-----------------------------------------|
| `products` | Геошардинг + хэшированное шардирование        | `{ geo_zone: 1, product_id: "hashed" }` |
| `orders`   | Геошардинг + хэшированное шардирование        | `{ geo_zone: 1, user_id: "hashed" }`    |
| `carts`    | Хэшированное шардирование по составному ключу | `{ user_id: "hashed", session_id: 1 }`  |

---

## 2. Коллекция `products`

### 2.1. Схема документа

```
{
  _id: ObjectId,
  product_id: ObjectId,
  geo_zone: String,
  name: String,
  category: String,
  price: Decimal128,
  stock: NumberInt,
  attributes: {
    color: String,
    size: String
  }
}
```

Один документ хранит товар и его остаток в конкретной геозоне.

### 2.2. Кандидаты на shard key

- `product_id`;
- `geo_zone + product_id`.

### 2.3. Выбранное шардирование

Используется геошардинг в сочетании с хэшированным шардированием. `geo_zone` локализует данные по регионам, а хэшированный `product_id` равномерно распределяет товары внутри геозоны.

### 2.4. Shard key

```
{ geo_zone: 1, product_id: "hashed" }
```

```
sh.shardCollection(
  "mobile_world.products",
  { geo_zone: 1, product_id: "hashed" }
)
```

### 2.5. Основные операции

#### Обновление остатка

Ключ поиска:

```
{
  geo_zone,
  product_id
}
```

```
db.products.updateOne(
  {
    geo_zone: "ekaterinburg",
    product_id: ObjectId("65f000000000000000000001"),
    stock: { $gte: 1 }
  },
  {
    $inc: { stock: -1 }
  }
)
```

#### Поиск товаров по категории и диапазону цен

Ключ поиска:

```
{
  geo_zone,
  category,
  price
}
```

```
db.products.find({
  geo_zone: "ekaterinburg",
  category: "electronics",
  price: {
    $gte: Decimal128("10000.00"),
    $lte: Decimal128("100000.00")
  }
})
```

#### Получение описания товара

Ключ поиска:

```
{
  geo_zone,
  product_id
}
```

```
db.products.findOne({
  geo_zone: "ekaterinburg",
  product_id: ObjectId("65f000000000000000000001")
})
```

### 2.6. Индексы

```
db.products.createIndex({
  geo_zone: 1,
  category: 1,
  price: 1
})
```

Назначение: поиск товаров в геозоне по категории и диапазону цен.

---

## 3. Коллекция `orders`

### 3.1. Схема документа

```
{
  _id: ObjectId,
  user_id: ObjectId,
  created_at: Date,
  items: [
    {
      product_id: ObjectId,
      price: Decimal128
    }
  ],
  status: String,
  total_amount: Decimal128,
  geo_zone: String
}
```

### 3.2. Кандидаты на shard key

- `user_id`;
- `geo_zone + user_id`.

### 3.3. Выбранное шардирование

Используется геошардинг в сочетании с хэшированным шардированием. `geo_zone` локализует заказы по регионам, а хэшированный `user_id` равномерно распределяет пользователей внутри геозоны.

### 3.4. Shard key

```
{ geo_zone: 1, user_id: "hashed" }
```

```
sh.shardCollection(
  "mobile_world.orders",
  { geo_zone: 1, user_id: "hashed" }
)
```

### 3.5. Основные операции

#### Создание заказа

Ключ распределения:

```
{
  geo_zone,
  user_id
}
```

```
db.orders.insertOne({
  user_id: ObjectId("64f000000000000000000001"),
  created_at: new Date(),
  items: [
    {
      product_id: ObjectId("65f000000000000000000001"),
      price: Decimal128("79990.00")
    }
  ],
  status: "created",
  total_amount: Decimal128("79990.00"),
  geo_zone: "moscow"
})
```

#### Поиск истории заказов пользователя

Ключ поиска:

```
{
  geo_zone,
  user_id
}
```

```
db.orders.find({
  geo_zone: "moscow",
  user_id: ObjectId("64f000000000000000000001")
})
.sort({
  created_at: -1
})
```

#### Получение статуса заказа

Ключ поиска:

```
{
  geo_zone,
  user_id,
  _id
}
```

```
db.orders.findOne(
  {
    geo_zone: "moscow",
    user_id: ObjectId("64f000000000000000000001"),
    _id: ObjectId("66b000000000000000000001")
  },
  {
    status: 1
  }
)
```

### 3.6. Индексы

```
db.orders.createIndex({
  geo_zone: 1,
  user_id: 1,
  created_at: -1
})
```

Назначение: поиск истории заказов пользователя с сортировкой по дате.

---

## 4. Коллекция `carts`

### 4.1. Схема документа

```
{
  _id: ObjectId,
  user_id: ObjectId | null,
  session_id: String | null,
  items: [
    {
      product_id: ObjectId,
      quantity: NumberInt
    }
  ],
  status: "active" | "ordered" | "abandoned",
  created_at: Date,
  updated_at: Date,
  expires_at: Date
}
```

### 4.2. Кандидаты на shard key

- `user_id`;
- `session_id`;
- `user_id + session_id`.

### 4.3. Выбранное шардирование

Используется хэшированное шардирование по составному ключу из `user_id` и `session_id`. Ключ поддерживает поиск как пользовательских, так и гостевых корзин без добавления отдельного технического поля.

### 4.4. Shard key

```
{ user_id: "hashed", session_id: 1 }
```

```
sh.shardCollection(
  "mobile_world.carts",
  { user_id: "hashed", session_id: 1 }
)
```

### 4.5. Основные операции

#### Создание пользовательской корзины

Ключ распределения:

```
{
  user_id,
  session_id: null
}
```

```
db.carts.insertOne({
  user_id: ObjectId("64f000000000000000000001"),
  session_id: null,
  items: [],
  status: "active",
  created_at: new Date(),
  updated_at: new Date(),
  expires_at: ISODate("2026-08-24T10:00:00Z")
})
```

#### Создание гостевой корзины

Ключ распределения:

```
{
  user_id: null,
  session_id
}
```

```
db.carts.insertOne({
  user_id: null,
  session_id: "guest-session-123",
  items: [],
  status: "active",
  created_at: new Date(),
  updated_at: new Date(),
  expires_at: ISODate("2026-08-01T10:00:00Z")
})
```

#### Получение активной пользовательской корзины

Ключ поиска:

```
{
  user_id,
  session_id: null,
  status: "active"
}
```

```
db.carts.findOne({
  user_id: ObjectId("64f000000000000000000001"),
  session_id: null,
  status: "active"
})
```

#### Получение активной гостевой корзины

Ключ поиска:

```
{
  user_id: null,
  session_id,
  status: "active"
}
```

```
db.carts.findOne({
  user_id: null,
  session_id: "guest-session-123",
  status: "active"
})
```

#### Добавление товара

```
db.carts.updateOne(
  {
    user_id: ObjectId("64f000000000000000000001"),
    session_id: null,
    status: "active"
  },
  {
    $push: {
      items: {
        product_id: ObjectId("65f000000000000000000001"),
        quantity: NumberInt(1)
      }
    },
    $set: {
      updated_at: new Date()
    }
  }
)
```

#### Замена количества товара

```
db.carts.updateOne(
  {
    user_id: ObjectId("64f000000000000000000001"),
    session_id: null,
    status: "active",
    "items.product_id": ObjectId("65f000000000000000000001")
  },
  {
    $set: {
      "items.$.quantity": NumberInt(3),
      updated_at: new Date()
    }
  }
)
```

#### Удаление товара

```
db.carts.updateOne(
  {
    user_id: ObjectId("64f000000000000000000001"),
    session_id: null,
    status: "active"
  },
  {
    $pull: {
      items: {
        product_id: ObjectId("65f000000000000000000001")
      }
    },
    $set: {
      updated_at: new Date()
    }
  }
)
```

#### Слияние гостевой и пользовательской корзин

Гостевая корзина:

```
{
  user_id: null,
  session_id,
  status: "active"
}
```

Пользовательская корзина:

```
{
  user_id,
  session_id: null,
  status: "active"
}
```

После переноса товаров гостевая корзина помечается как `abandoned`:

```
db.carts.updateOne(
  {
    user_id: null,
    session_id: "guest-session-123",
    status: "active"
  },
  {
    $set: {
      status: "abandoned",
      updated_at: new Date()
    }
  }
)
```

#### Отметка корзины как заказанной

```
db.carts.updateOne(
  {
    user_id: ObjectId("64f000000000000000000001"),
    session_id: null,
    status: "active"
  },
  {
    $set: {
      status: "ordered",
      updated_at: new Date()
    }
  }
)
```

### 4.6. Индексы

```
db.carts.createIndex({
  user_id: 1,
  session_id: 1,
  status: 1
})
```

Назначение: получение активной пользовательской или гостевой корзины.

```
db.carts.createIndex(
  { expires_at: 1 },
  { expireAfterSeconds: 0 }
)
```

Назначение: автоматическое удаление устаревших корзин.

---

## 5. Вывод

Для коллекций `products` и `orders` выбрано сочетание географического и хэшированного шардирования. Поле `geo_zone` группирует данные по регионам, а хэшированный идентификатор равномерно распределяет нагрузку внутри каждой геозоны.

Для коллекции `carts` используется составной shard key `{ user_id: "hashed", session_id: 1 }`, который позволяет работать как с пользовательскими, так и с гостевыми корзинами. `user_id` обеспечивает равномерное распределение пользовательских корзин, а `session_id` различает гостевые корзины, у которых `user_id` равен `null`.
