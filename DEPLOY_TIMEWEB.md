# Запуск приложения на Timeweb Cloud

Пошаговая инструкция для облачного сервера Ubuntu.

---

## Шаг 1. Доступ в интернет (если ещё не настроен)

```bash
# Узнайте IP шлюза в панели: Сети → Роутеры → Приватные сети
sudo ip route add default via 192.168.0.1 dev eth1   # замените на свой шлюз

# Проверка
ping -c 2 8.8.8.8
```

Чтобы маршрут сохранялся после перезагрузки:

```bash
sudo nano /etc/netplan/60-custom.yaml
```

```yaml
network:
  version: 2
  ethernets:
    eth1:
      routes:
        - to: 0.0.0.0/0
          via: 192.168.0.1
```

```bash
sudo chmod 600 /etc/netplan/60-custom.yaml
sudo netplan apply
```

---

## Шаг 2. Установка Node.js

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v   # должно показать v20.x
```

---

## Шаг 3. Загрузка проекта на сервер

### Вариант А: Git (если интернет работает)

```bash
cd ~
git clone https://github.com/Khubaev/new_jts.git
```

### Вариант Б: Ручная загрузка

1. На ПК: https://github.com/Khubaev/new_jts → Code → Download ZIP  
2. Загрузите `new_jts-main.zip` на сервер через SCP/SFTP или панель Timeweb  
3. На сервере:

```bash
cd ~
unzip new_jts-main.zip
mv new_jts-main new_jts
```

---

## Шаг 4. Запуск backend

```bash
cd ~/new_jts/backend
npm install

# Production: обязательно задать JWT_SECRET (минимум 32 символа)
# export JWT_SECRET=ваш-случайный-секрет-минимум-32-символа
# или создать .env из backend/.env.example
node scripts/init-db.js   # один раз — создаёт БД и демо-пользователей
node server.js
```

Должно появиться: `Server running on http://0.0.0.0:3000`

Проверка в другом терминале или с ПК:

```bash
curl http://ВАШ_ПУБЛИЧНЫЙ_IP:3000/api/health
# Ответ: {"ok":true}
```

---

## Шаг 5. Запуск в фоне (PM2)

```bash
sudo npm install -g pm2
cd ~/new_jts/backend
pm2 start server.js --name requests-api
pm2 save
pm2 startup   # выполните команду, которую выведет pm2
```

Полезные команды:

```bash
pm2 status      # статус
pm2 logs        # логи
pm2 restart requests-api
```

---

## Шаг 6. Открыть порт 3000

### В панели Timeweb

Сети → Firewall → создать правило: разрешить входящий TCP порт 3000.

### Или через UFW на сервере

```bash
sudo ufw allow 3000
sudo ufw enable
```

---

## Шаг 7. Настроить приложение на телефоне

**Важно:** Без этого приложение не подключится к серверу.

1. Узнайте **публичный IP** сервера в панели Timeweb  
2. На ПК откройте `lib/core/config/api_config.dart`  
3. Измените:

```dart
const _apiMode = 'remote';
const String _apiHostRemote = 'ВАШ_ПУБЛИЧНЫЙ_IP';  // например '123.45.67.89'
```

4. Соберите APK заново:

```bash
cd c:\myJts\my_new_project
flutter build apk
```

5. Установите новый `build/app/outputs/flutter-apk/app-release.apk` на телефон (переустановите поверх старого)

---

## Итог

| Что | Где |
|-----|-----|
| Backend | `http://ВАШ_IP:3000` |
| Демо-логины | admin/admin123, ivanov/user123 |
| Проверка | `curl http://ВАШ_IP:3000/api/health` |

---

## Если логин не работает

1. **На экране входа** внизу отображается адрес сервера — сверьте с нужным IP
2. **Проверьте логин через curl** (на ПК или сервере):
   ```bash
   curl -X POST http://ВАШ_IP:3000/api/auth/login -H "Content-Type: application/json" -d "{\"login\":\"admin\",\"password\":\"admin123\"}"
   ```
   Ожидается: `{"user":{...},"token":"..."}`. Если `{"error":"..."}` — неверные данные или backend не инициализирован.
3. **Пересоберите APK** после изменений в `api_config.dart`
4. **Текст ошибки** в приложении теперь показывает причину (сеть, неверный пароль и т.п.)
