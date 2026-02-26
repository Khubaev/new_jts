# Учёт заявок

Flutter-приложение для учёта заявок с Node.js бэкендом (Express + SQLite).

## Быстрый старт

```bash
# Бэкенд
cd backend && npm start

# Flutter
flutter run -d chrome   # или -d windows, -d emulator-5554
```

**Демо-логины:** admin/admin123, director/director123, ivanov/user123, petrov/user123

## Документация

| Файл | Описание |
|------|----------|
| [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) | Обзор проекта, структура, API, права, запуск |
| [API.md](API.md) | REST API — эндпоинты, body, коды ответов |
| [BACKEND.md](BACKEND.md) | Backend — структура, routes, БД |
| [MODELS.md](MODELS.md) | Модели Request, AppUser, RequestStatus, UserRole |
| [SERVICES.md](SERVICES.md) | ApiClient, ApiService |
| [PROVIDERS.md](PROVIDERS.md) | AuthProvider, RequestsProvider |
| [FEATURES.md](FEATURES.md) | Структура features (auth, requests) |
| [REQUESTS_SCREENS.md](REQUESTS_SCREENS.md) | Подробное описание экранов заявок |

## Структура

```
my_new_project/
├── lib/           # Flutter
├── backend/       # Node.js + Express + SQLite
└── *.md           # Документация
```
