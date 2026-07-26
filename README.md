# Спринт 4. Шардирование, репликация и кеширование

В проекте реализованы:

- шардирование MongoDB;
- репликация шардов;
- кеширование запросов в Redis;
- архитектурные решения по масштабированию MongoDB и миграции данных в Cassandra.

## Материалы для проверки

### Задания 1–6

Финальная реализация заданий 2–4 находится в каталоге:

- [sharding-repl-cache](./sharding-repl-cache)

Итоговая архитектурная схема по заданиям 1, 5 и 6:

- [docs/final/architecture.drawio](./docs/final/architecture.drawio)

### Задания 7–10

Единый архитектурный документ:

- [docs/final/architecture-tasks-7-10.md](./docs/final/architecture-tasks-7-10.md)

## Запуск финального стенда

Полная инструкция по запуску и проверке стенда:

- [sharding-repl-cache/README.md](./sharding-repl-cache/README.md)

## Структура репозитория

```text
.
├── mongo-sharding/
├── mongo-sharding-repl/
├── sharding-repl-cache/
├── docs/
│   ├── task1/
│   ├── task5/
│   ├── task6/
│   ├── task7/
│   ├── task8/
│   ├── task9/
│   ├── task10/
│   └── final/
│       ├── architecture.drawio
│       └── architecture-tasks-7-10.md
└── README.md
```

Каталоги содержат последовательные этапы выполнения работы:

- `mongo-sharding` — реализация шардирования MongoDB;
- `mongo-sharding-repl` — добавление репликации;
- `sharding-repl-cache` — финальная реализация с шардированием, репликацией и Redis;
- `docs/task1`, `docs/task5`, `docs/task6` — схемы отдельных этапов;
- `docs/task7`, `docs/task8`, `docs/task9`, `docs/task10` — отдельные архитектурные задания;
- `docs/final` — итоговые материалы для проверки.
