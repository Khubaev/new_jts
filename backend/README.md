# Backend API для приложения учёта заявок

## Установка

```bash
cd backend
npm install
```

## Инициализация БД

```bash
npm run init-db
```

Создаёт базу SQLite в `data/requests.db` и заполняет начальными данными:
- Роли: Администратор, Директор, Пользователь
- Статусы: Новая, В работе, Выполнена, Отменена
- Типы заявок: Ремонт, Установка ПО, Настройка и др.
- Комнаты: 101, 205, 310, 102, 201
- Пользователи: admin/admin123, director/director123, ivanov/user123, petrov/user123

## Запуск

```bash
npm start
```

Сервер: http://localhost:3000

## API

### Авторизация (без токена)

- `POST /api/auth/login` — логин
  - Body: `{ "login": "admin", "password": "admin123" }`
  - Ответ: `{ "user": {...}, "token": "..." }`

### Защищённые маршруты (заголовок: `Authorization: Bearer <token>`)

#### Комнаты
- `GET /api/rooms` — список комнат
- `POST /api/rooms` — создать (admin/director)
- `PUT /api/rooms/:id` — обновить
- `DELETE /api/rooms/:id` — удалить

#### Статусы
- `GET /api/statuses` — список статусов
- `POST /api/statuses` — создать (admin/director)
- `PUT /api/statuses/:id` — обновить
- `DELETE /api/statuses/:id` — удалить

#### Типы заявок
- `GET /api/types` — список типов

#### Пользователи
- `GET /api/users` — все пользователи (admin/director)
- `GET /api/users/for-responsible` — пользователи для выбора ответственного
- `POST /api/users` — создать (admin/director)

#### Заявки
- `GET /api/requests?show_completed=true` — список заявок
- `GET /api/requests/:id` — заявка по ID
- `POST /api/requests` — создать
- `PUT /api/requests/:id` — обновить (постановщик)
- `PATCH /api/requests/:id/status` — изменить статус (постановщик/ответственный)
- `PATCH /api/requests/:id/rating` — оценить (admin/director)
- `DELETE /api/requests/:id` — удалить (постановщик)

## Структура БД

- **roles** — роли пользователей
- **rooms** — номера комнат
- **request_statuses** — статусы заявок
- **request_types** — типы заявок
- **users** — пользователи
- **requests** — заявки
- **request_photos** — фотографии к заявкам (base64)
