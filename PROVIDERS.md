# Структура провайдеров

`lib/providers/`

## Файлы

| Файл | Назначение |
|------|------------|
| `auth_provider.dart` | Авторизация, текущий пользователь, токен |
| `requests_provider.dart` | Заявки, справочники, CRUD |

Оба наследуют `ChangeNotifier` (пакет `provider`).

---

## auth_provider.dart

### Состояние

| Поле | Тип | Описание |
|------|-----|----------|
| `_currentUser` | AppUser? | Текущий пользователь |
| `_token` | String? | JWT-токен для API |
| `_usersForResponsible` | List\<AppUser\> | Пользователи для выбора ответственного |

### Геттеры

| Геттер | Возврат |
|--------|---------|
| `currentUser` | AppUser? |
| `token` | String? |
| `isAuthenticated` | bool |
| `usersForResponsible` | List\<AppUser\> (unmodifiable) |

### Методы

| Метод | Описание |
|-------|----------|
| `login(login, password)` | POST /api/auth/login, сохраняет user и token, загружает usersForResponsible. Возвращает `Future<bool>`. |
| `logout()` | Очищает user, token, вызывает notifyListeners |
| `setTokenForApi(token)` | Устанавливает токен в ApiService |
| `getUserById(id)` | Ищет в currentUser и usersForResponsible |

### Зависимости

- `ApiService` — login, getUsersForResponsible
- `AppUser`, `UserRole` — models/user.dart

### Использование

- `main.dart` — проверка isAuthenticated, выбор экрана
- `LoginScreen` — login()
- `RequestsListScreen` — token, currentUser
- `CreateRequestScreen`, `EditRequestScreen` — usersForResponsible, currentUser
- `RequestDetailScreen` — currentUser (проверки прав)

---

## requests_provider.dart

### Состояние

| Поле | Тип | Описание |
|------|-----|----------|
| `_requests` | List\<Request\> | Список заявок |
| `_statuses` | List\<Map\> | Справочник статусов (id, name, code, color) |
| `_showCompleted` | bool | Показывать выполненные заявки |
| `_loading` | bool | Идёт загрузка |
| `_error` | String? | Текст ошибки API |

### Геттеры

| Геттер | Возврат |
|--------|---------|
| `loading` | bool |
| `error` | String? |
| `showCompleted` | bool |
| `statuses` | List\<Map\> (unmodifiable) |

### Методы

| Метод | Описание |
|-------|----------|
| `setToken(token)` | Передаёт токен в ApiService |
| `toggleShowCompleted()` | Переключает _showCompleted |
| `getFilteredRequests(currentUser)` | Фильтрует по showCompleted и роли (user видит только свои) |
| `getById(id)` | Request? из _requests |
| `loadRequests()` | GET statuses + requests, обновляет _requests, _statuses |
| `fetchRequest(id)` | GET /api/requests/:id (с фото), обновляет в _requests |
| `addRequest(...)` | POST /api/requests, добавляет в _requests |
| `updateRequest(id, request)` | PUT /api/requests/:id |
| `updateStatus(id, statusId)` | PATCH /api/requests/:id/status |
| `updateRating(id, rating)` | PATCH /api/requests/:id/rating |
| `deleteRequest(id)` | DELETE /api/requests/:id |
| `getStatuses()` | GET /api/statuses |
| `getRooms()` | GET /api/rooms |
| `getRequestTypes()` | GET /api/types |

### addRequest — параметры

- `title`, `description`, `requestorUserId` — обязательные
- `priority`, `roomId`, `responsibleUserId`, `requestTypeId`, `photoBytes` — опциональные

### Логика getFilteredRequests

1. Если `!showCompleted` — исключить `RequestStatus.completed`
2. Если `!currentUser.role.canSeeAllRequests` — оставить только заявки, где `responsibleUserId == user.id` или `requestorUserId == user.id`
3. Сортировка по `createdAt` DESC

### Зависимости

- `ApiService` — все API-вызовы
- `Request`, `RequestStatus` — models/request.dart
- `AppUser` — models/user.dart

### Использование

- `main.dart` — ChangeNotifierProvider
- `RequestsListScreen` — setToken, loadRequests, getFilteredRequests, toggleShowCompleted
- `RequestDetailScreen` — getById, fetchRequest, updateStatus, updateRating, deleteRequest, statuses
- `CreateRequestScreen` — getRooms, getRequestTypes, addRequest
- `EditRequestScreen` — getById, fetchRequest, getRooms, getRequestTypes, updateRequest

---

## Связь провайдеров

```
main.dart
  └── MultiProvider
        ├── AuthProvider    ← первым (при логине передаёт token в RequestsProvider)
        └── RequestsProvider

RequestsListScreen._init():
  requests.setToken(auth.token)
  requests.loadRequests()
```

**Важно:** `RequestsProvider.setToken()` вызывается после логина в `RequestsListScreen._init()`, т.к. токен появляется в AuthProvider после успешного login.
