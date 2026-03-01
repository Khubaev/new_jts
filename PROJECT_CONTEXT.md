# Контекст проекта «Учёт заявок»

> Этот файл помогает быстро понять структуру проекта при ограниченном контексте.

## Обзор

Flutter-приложение для учёта заявок с Node.js бэкендом. Роли: Администратор, Директор, Пользователь.

## Структура

```
my_new_project/
├── lib/                    # Flutter
│   ├── main.dart           # Точка входа, MultiProvider (Auth + Requests)
│   ├── core/
│   │   ├── config/api_config.dart   # apiBaseUrl (localhost:3000 / 10.0.2.2 для Android)
│   │   ├── constants/app_constants.dart
│   │   └── theme/app_theme.dart
│   ├── models/
│   │   ├── request.dart    # Request + RequestStatus enum, поля: roomId, statusId, requestTypeId, photoBytes
│   │   └── user.dart       # AppUser + UserRole enum
│   ├── providers/
│   │   ├── auth_provider.dart    # login через API, token, usersForResponsible
│   │   └── requests_provider.dart # loadRequests, addRequest, updateStatus(id, statusId)
│   ├── services/
│   │   ├── api_client.dart       # HTTP + Bearer token
│   │   └── api_service.dart      # Все API вызовы
│   └── features/
│       ├── auth/screens/login_screen.dart
│       └── requests/
│           ├── screens/    # requests_list, request_detail, create_request, edit_request
│           └── widgets/request_card.dart
└── backend/                # Node.js + Express + SQLite
    ├── server.js           # Порт 3000
    ├── routes/             # auth, rooms, statuses, types, users, requests
    └── data/requests.db    # SQLite БД
```

## API (backend)

- **POST /api/auth/login** → `{ user, token }`
- **GET /api/requests?show_completed=true** — список заявок
- **POST /api/requests** — body: title, description, roomId, responsibleUserId, requestTypeId, photoBytes (base64[])
- **PATCH /api/requests/:id/status** — body: `{ statusId }`
- **GET /api/rooms**, **GET /api/statuses**, **GET /api/types**, **GET /api/users/for-responsible**

Все запросы (кроме login): заголовок `Authorization: Bearer <token>`. Токен — JWT (срок 24ч).

## Права доступа

| Действие | Постановщик | Ответственный | Админ/Директор |
|----------|-------------|---------------|----------------|
| Редактировать данные | ✅ | ❌ | ✅ |
| Менять статус | ✅ | ✅ | ✅ |
| Удалять | ✅ | ❌ | ✅ |

**Постановщик** — `requestorUserId`, создаётся при создании заявки (текущий пользователь).

## Важные детали

1. **Request model**: `statusId`, `roomId`, `requestTypeId` — ID из API; `photoBytes` — `List<Uint8List>`.
2. **api_config.dart**: для Android-эмулятора нужен `http://10.0.2.2:3000`, иначе `localhost:3000`.
3. **Статусы**: приходят с API (`provider.statuses`), при смене передаётся `statusId`.
4. **Комнаты и типы**: загружаются с API при создании/редактировании заявки.

## Запуск

```bash
# Бэкенд
cd backend && npm start

# Flutter
flutter run -d emulator-5554   # или -d chrome, -d windows
```

## Демо-логины

admin/admin123, director/director123, ivanov/user123, petrov/user123
