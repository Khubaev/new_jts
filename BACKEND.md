# Backend

Node.js + Express + SQLite. Порт по умолчанию: 3000.

## Структура

```
backend/
├── server.js           # Точка входа, CORS, rate limit, JSON limit 12mb
├── config.js           # JWT_SECRET, лимиты, валидация
├── db.js               # Подключение к SQLite (data/requests.db)
├── middleware/
│   ├── auth.js         # JWT → req.user
│   └── validate.js     # Валидация заявок (title, description, фото)
├── routes/
│   ├── index.js        # Агрегация маршрутов
│   ├── auth.js         # POST /login
│   ├── rooms.js        # CRUD комнат
│   ├── statuses.js     # CRUD статусов
│   ├── types.js        # GET типов заявок
│   ├── users.js        # GET /, /for-responsible, POST
│   └── requests.js     # CRUD заявок, PATCH status/rating
├── scripts/
│   └── init-db.js      # Создание БД и начальных данных
└── data/
    └── requests.db     # SQLite (создаётся при первом запуске)
```

## Маршруты (server.js)

| Путь | Auth | Роутер |
|------|------|--------|
| /api/auth | нет | auth |
| /api/rooms | да | rooms |
| /api/statuses | да | statuses |
| /api/types | да | types |
| /api/users | да | users |
| /api/requests | да | requests |
| /api/health | нет | встроенный |

## Middleware auth

- Читает `Authorization: Bearer <token>`
- Токен — JWT (подпись, срок 24ч)
- Проверяет подпись, извлекает userId, загружает user из БД, кладёт в `req.user`
- При ошибке → 401 («Неверный токен» или «Токен истёк. Войдите снова.»)

## Middleware validate

- `validateRequestCreate` — POST /api/requests: title≤200, description≤5000, roomId/requestTypeId/responsibleUserId в справочниках, фото JPEG/PNG≤5MB, ≤10 шт.
- `validateRequestUpdate` — PUT /api/requests/:id: те же ограничения

## Конфигурация (config.js, .env)

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| JWT_SECRET | change-me-in-production | Секрет для подписи JWT |
| JWT_EXPIRES_IN | 24h | Срок действия токена |
| BODY_LIMIT | 12mb | Лимит тела запроса |
| CORS_ORIGINS | — | Список origins через запятую (если задан — ограничение CORS) |

## Rate limiting

- `/api/auth/login` — 5 попыток за 15 минут, при превышении → 429

## База данных

**Путь:** `backend/data/requests.db`

### Таблицы

| Таблица | Описание |
|---------|----------|
| roles | Роли: administrator, director, user |
| rooms | Комнаты (number, description) |
| request_statuses | Статусы: new, in_progress, completed, cancelled |
| request_types | Типы заявок (Ремонт, Установка ПО и т.д.) |
| users | Пользователи (login, password_hash, name, role_id) |
| requests | Заявки (title, description, status_id, room_id, requestor_id, responsible_id и т.д.) |
| request_photos | Фото заявок (request_id, data_base64, sort_order) |

### Индексы

- `idx_requests_status`, `idx_requests_requestor`, `idx_requests_responsible`, `idx_requests_created`

### Начальные данные (init-db.js)

- Роли, статусы, типы заявок, комнаты
- Пользователи (если пусто): admin/admin123, director/director123, ivanov/user123, petrov/user123

## Инициализация БД

```bash
cd backend
node scripts/init-db.js
```

БД создаётся при первом запуске, если `data/requests.db` отсутствует. Для полной переинициализации — удалить `data/requests.db` и запустить `init-db.js`.

## Запуск

```bash
cd backend
npm install
node scripts/init-db.js   # один раз
npm start
```

**Production:** задайте `JWT_SECRET` в `.env` или переменных окружения (минимум 32 символа).

См. также [API.md](API.md) для описания эндпоинтов.
