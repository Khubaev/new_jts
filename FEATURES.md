# Структура features

`lib/features/`

> Подробное описание экранов заявок см. в [REQUESTS_SCREENS.md](REQUESTS_SCREENS.md).

## Дерево файлов

```
features/
├── auth/
│   └── screens/
│       └── login_screen.dart
└── requests/
    ├── screens/
    │   ├── requests_list_screen.dart
    │   ├── request_detail_screen.dart
    │   ├── create_request_screen.dart
    │   └── edit_request_screen.dart
    └── widgets/
        └── request_card.dart
```

---

## auth

**login_screen.dart** — StatefulWidget. Form логин/пароль, вызов `auth.login()`. При успехе main.dart переключает на RequestsListScreen.

---

## requests

| Экран | Назначение |
|-------|------------|
| requests_list_screen | Список заявок, FAB «Новая заявка» |
| request_detail_screen | Просмотр, смена статуса, редактирование, удаление |
| create_request_screen | Создание заявки (форма) |
| edit_request_screen | Редактирование заявки |

**request_card.dart** — StatelessWidget. Параметры: `request`, `requestorName`, `responsibleName`, `onTap`.

---

## Навигация

```
main.dart
  ├── !auth → LoginScreen
  └── auth  → RequestsListScreen
                  ├── [tap card] → RequestDetailScreen(requestId)
                  │                     └── [edit] → EditRequestScreen(requestId)
                  └── [FAB]       → CreateRequestScreen
```

---

## Зависимости

| Feature | Providers | Models | Services |
|---------|-----------|--------|----------|
| auth | AuthProvider | — | — |
| requests | AuthProvider, RequestsProvider | Request | ApiService |
