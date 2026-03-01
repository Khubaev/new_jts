# Структура сервисов

`lib/services/`

## Файлы

| Файл | Назначение |
|------|------------|
| `api_client.dart` | HTTP-клиент с Bearer-токеном |
| `api_service.dart` | Методы API, парсинг JSON → модели |

---

## api_client.dart

### Назначение

Низкоуровневый HTTP-клиент. Формирует URL из `apiBaseUrl` + path, добавляет заголовки.

### Методы

| Метод | HTTP | Описание |
|-------|------|----------|
| `setToken(token)` | — | Устанавливает токен для заголовка Authorization |
| `get(path)` | GET | Возвращает `Future<http.Response>` |
| `post(path, [body])` | POST | body — `Map<String, dynamic>`, кодируется в JSON |
| `put(path, [body])` | PUT | |
| `patch(path, [body])` | PATCH | |
| `delete(path)` | DELETE | |

### Заголовки

- `Content-Type: application/json`
- `Accept: application/json`
- `Authorization: Bearer <token>` — если токен задан

### Зависимости

- `package:http` — http.get, http.post и т.д.
- `api_config.dart` — apiBaseUrl

---

## api_service.dart

### Назначение

Высокоуровневый слой над ApiClient. Парсит ответы в модели, выбрасывает `ApiException` при ошибках.

### Методы

| Метод | API | Возврат |
|-------|-----|---------|
| `setToken(token)` | — | Прокидывает в ApiClient |
| `login(login, password)` | POST /api/auth/login | `Future<LoginResult>` |
| `getRequests(showCompleted)` | GET /api/requests | `Future<List<Request>>` |
| `getRequest(id)` | GET /api/requests/:id | `Future<Request?>` |
| `createRequest(...)` | POST /api/requests | `Future<Request>` |
| `updateRequest(id, ...)` | PUT /api/requests/:id | `Future<void>` |
| `updateRequestStatus(id, statusId)` | PATCH /api/requests/:id/status | `Future<void>` |
| `updateRequestRating(id, rating)` | PATCH /api/requests/:id/rating | `Future<void>` |
| `deleteRequest(id)` | DELETE /api/requests/:id | `Future<void>` |
| `getUsersForResponsible()` | GET /api/users/for-responsible | `Future<List<AppUser>>` |
| `getRooms()` | GET /api/rooms | `Future<List<Map>>` |
| `getStatuses()` | GET /api/statuses | `Future<List<Map>>` |
| `getRequestTypes()` | GET /api/types | `Future<List<Map>>` |

### createRequest — параметры

- Обязательные: `title` (≤200), `description` (≤5000)
- Опциональные: `priority`, `roomId`, `responsibleUserId`, `requestTypeId`, `photoBytes` (≤10 шт., ≤5 MB, JPEG/PNG)
- `requestorUserId` — не передаётся; backend берёт из токена (текущий пользователь)
- `photoBytes` — `List<Uint8List>`, в JSON как массив base64. Backend: ≤10 шт., ≤5 MB каждое, JPEG/PNG

### updateRequest — параметры

Все опциональные: `title`, `description`, `priority`, `roomId`, `responsibleUserId`, `requestTypeId`, `photoBytes`. Те же лимиты, что в createRequest.

### Маппинг API → модели

| API поле | Модель |
|----------|--------|
| `status.code` | RequestStatus (new, in_progress, completed, cancelled) |
| `user.role` | UserRole (administrator, director, user) |
| `photoBase64[]` | `List<Uint8List>` (base64Decode) |

### Вспомогательные классы

| Класс | Описание |
|-------|----------|
| `LoginResult` | `user: AppUser`, `token: String` |
| `ApiException` | `message: String`, implements Exception |

### Обработка ошибок

- `_checkResponse(res, statusOk)` — при statusCode != ok выбрасывает ApiException
- 401 → `ApiException(body['error'] или 'Требуется авторизация')`
- 429 (login) → `ApiException('Слишком много попыток. Подождите 15 минут.')`
- Другие коды → `body['error']` или `'Ошибка сервера'`
- `statusOk`: 200 по умолчанию, 201 для POST create, 204 для DELETE

### Зависимости

- `ApiClient`
- `Request`, `RequestStatus` — models/request.dart
- `AppUser`, `UserRole` — models/user.dart
- `dart:convert` — jsonDecode, base64Encode, base64Decode

---

## Использование

| Кто использует | Что вызывает |
|---------------|--------------|
| AuthProvider | login, getUsersForResponsible, setToken |
| RequestsProvider | setToken, getRequests, getRequest, createRequest, updateRequest, updateRequestStatus, updateRequestRating, deleteRequest, getRooms, getStatuses, getRequestTypes |

**Важно:** ApiService создаётся внутри AuthProvider и RequestsProvider как `final _api = ApiService()`. Токен передаётся через `setToken()` после логина.
