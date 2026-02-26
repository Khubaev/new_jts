# Структура моделей

`lib/models/`

## Файлы

| Файл | Содержимое |
|------|------------|
| `request.dart` | Request, RequestStatus enum + extension |
| `user.dart` | AppUser, UserRole enum + extension |

---

## request.dart

### RequestStatus (enum)

| Значение | label | color | icon |
|-----------|-------|-------|------|
| `newRequest` | Новая | blue | fiber_new |
| `inProgress` | В работе | orange | hourglass_empty |
| `completed` | Выполнена | green | check_circle |
| `cancelled` | Отменена | grey | cancel |

**Extension:** `RequestStatusExtension` — `label`, `color`, `icon`.

---

### Request (class)

**Обязательные поля:**
| Поле | Тип | Описание |
|------|-----|----------|
| `id` | String | UUID |
| `title` | String | Заголовок |
| `description` | String | Описание |
| `status` | RequestStatus | Статус (enum) |
| `createdAt` | DateTime | Дата создания |

**Опциональные поля:**
| Поле | Тип | Описание |
|------|-----|----------|
| `statusId` | String? | ID статуса в API (для PATCH) |
| `updatedAt` | DateTime? | Дата обновления |
| `priority` | String? | Низкий, Средний, Высокий, Критический |
| `roomNumber` | String? | Номер комнаты (отображаемый) |
| `roomId` | String? | ID комнаты в API |
| `requestorUserId` | String? | ID постановщика |
| `requestorName` | String? | Имя постановщика |
| `responsibleUserId` | String? | ID ответственного |
| `responsibleName` | String? | Имя ответственного |
| `rating` | int? | Оценка 1–5 |
| `requestType` | String? | Название типа (отображаемое) |
| `requestTypeId` | String? | ID типа в API |
| `photoBytes` | List\<Uint8List\> | Фото (base64 → bytes) |

**Метод:** `copyWith(...)` — все поля опциональны.

**Импорт:** `dart:typed_data` (Uint8List), `package:flutter/material.dart` (Color, IconData).

---

## user.dart

### UserRole (enum)

| Значение | label |
|----------|-------|
| `administrator` | Администратор |
| `director` | Директор |
| `user` | Пользователь |

**Extension:** `UserRoleExtension`
- `label` — отображаемое название
- `canSeeAllRequests` — true для administrator и director

---

### AppUser (class)

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | String | ID пользователя |
| `login` | String | Логин для входа |
| `name` | String | Отображаемое имя |
| `role` | UserRole | Роль |

**Конструктор:** `const AppUser({required id, login, name, role})`.

---

## Связь с API

| Модель | API источник |
|--------|--------------|
| Request | GET/POST /api/requests, GET /api/requests/:id |
| AppUser | POST /api/auth/login (user), GET /api/users/for-responsible |
| RequestStatus | Маппинг по `status.code` из API (new, in_progress, completed, cancelled) |
| UserRole | Маппинг по `user.role` из API (administrator, director, user) |

---

## Использование

- **Request** — экраны заявок, `RequestsProvider`, `ApiService`
- **AppUser** — `AuthProvider`, экраны (текущий пользователь, выбор ответственного)
- **RequestStatus** — отображение статуса, фильтрация (скрыть выполненные)
- **UserRole** — проверки прав (`canSeeAllRequests`, `_canEditData`, `_canChangeStatus`)
