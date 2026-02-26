# Структура экранов заявок

`lib/features/requests/screens/`

## Файлы

| Файл | Тип | Назначение |
|------|-----|------------|
| `requests_list_screen.dart` | StatefulWidget | Список заявок (главный экран после входа) |
| `request_detail_screen.dart` | StatefulWidget | Просмотр и действия с одной заявкой |
| `create_request_screen.dart` | StatefulWidget | Создание новой заявки |
| `edit_request_screen.dart` | StatefulWidget | Редактирование заявки |

---

## requests_list_screen.dart

**Вход:** после успешного логина.

**Инициализация:** `_init()` — `requests.setToken(auth.token)`, `requests.loadRequests()`.

**Зависимости:**
- `AuthProvider` — текущий пользователь, token
- `RequestsProvider` — заявки, `getFilteredRequests(user)`, `loadRequests()`, `toggleShowCompleted()`

**UI:**
- AppBar: переключатель «показать выполненные», кнопка обновления, выход
- Список `RequestCard` → по нажатию `RequestDetailScreen(requestId)`
- FAB «Новая заявка» → `CreateRequestScreen`

**Навигация:**
- `RequestDetailScreen(requestId: request.id)`
- `CreateRequestScreen()`

---

## request_detail_screen.dart

**Вход:** `RequestDetailScreen(requestId: String)`.

**Инициализация:** `fetchRequest(requestId)` — подгрузка заявки с фото.

**Параметр:** `widget.requestId`.

**Права (методы):**
- `_canEditData(user, request)` — постановщик или админ/директор
- `_canChangeStatus(user, request)` — постановщик, ответственный или админ/директор
- `_canDelete(user, request)` — постановщик или админ/директор

**Зависимости:**
- `AuthProvider` — текущий пользователь
- `RequestsProvider` — `getById`, `fetchRequest`, `updateStatus(id, statusId)`, `updateRating`, `deleteRequest`, `statuses`

**UI:**
- AppBar: меню статусов (PopupMenuButton по `provider.statuses`), кнопка редактирования, удаления
- Карточки реквизитов в 2 колонки: Приоритет, Комната, Тип, Постановщик, Ответственный, Оценка, Даты
- Описание, фотографии, оценка (для админа/директора)

**Навигация:**
- `EditRequestScreen(requestId: widget.requestId)`

---

## create_request_screen.dart

**Вход:** FAB «Новая заявка» на списке.

**Инициализация:** `_loadData()` — `getRooms()`, `getRequestTypes()`.

**Поля формы:**
- `_titleController`, `_descriptionController` — текст
- `_selectedRoomId` — из API rooms
- `_selectedResponsible` — из `auth.usersForResponsible`
- `_selectedTypeId` — из API types
- `_selectedPriority` — Низкий, Средний, Высокий, Критический
- `_photoBytes` — `List<Uint8List>`, `image_picker.pickMultiImage()`

**Зависимости:**
- `AuthProvider` — `currentUser`, `usersForResponsible`
- `RequestsProvider` — `getRooms()`, `getRequestTypes()`, `addRequest()`
- `ApiService` — для `ApiException`

**Отправка:** `addRequest(title, description, requestorUserId: currentUser.id, roomId, responsibleUserId, requestTypeId, photoBytes)`.

---

## edit_request_screen.dart

**Вход:** кнопка редактирования в `RequestDetailScreen`.

**Параметр:** `widget.requestId`.

**Инициализация:** `_loadData()` — `getById` или `fetchRequest`, `getRooms()`, `getRequestTypes()`, заполнение формы.

**Поля формы:** те же, что в create, плюс предзаполнение из заявки.

**Зависимости:**
- `AuthProvider` — `usersForResponsible`
- `RequestsProvider` — `getById`, `fetchRequest`, `getRooms()`, `getRequestTypes()`, `updateRequest()`
- `ApiService` — для `ApiException`

**Отправка:** `updateRequest(id, request.copyWith(...))` — title, description, priority, roomId, responsibleUserId, requestTypeId, photoBytes.

---

## Связи между экранами

```
RequestsListScreen
    ├── [tap card] → RequestDetailScreen(requestId)
    └── [FAB]      → CreateRequestScreen
                         └── [submit] → pop, список обновляется

RequestDetailScreen
    └── [edit]     → EditRequestScreen(requestId)
                         └── [submit] → pop, детали обновляются
```

---

## Общие виджеты

- `RequestCard` — `lib/features/requests/widgets/request_card.dart`
  - Параметры: `request`, `requestorName`, `responsibleName`, `onTap`
