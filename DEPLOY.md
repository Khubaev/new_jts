# Запуск на удалённом сервере

## 1. Backend на сервере

### Требования

- Linux (Ubuntu, Debian и т.п.)
- Node.js 18+
- SSH-доступ

### Установка

```bash
# Подключитесь к серверу
ssh user@your-server-ip

# Установите Node.js (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Создайте папку
mkdir -p ~/app/backend

# С локального ПК (Windows) скопируйте файлы backend:
# scp -r c:\myJts\my_new_project\backend\* user@YOUR_SERVER_IP:~/app/backend/
#
# Или через Git: на сервере выполните
# git clone https://github.com/Khubaev/new_jts.git ~/app
# cd ~/app/backend
```

### Запуск

```bash
cd ~/app/backend
npm install
node scripts/init-db.js   # инициализация БД (один раз)
node server.js
```

Сервер слушает порт 3000. Для работы в фоне используйте **PM2**:

```bash
sudo npm install -g pm2
cd ~/app/backend
pm2 start server.js --name requests-api
pm2 save
pm2 startup   # автозапуск при перезагрузке
```

### Открыть порт

```bash
# UFW (Ubuntu)
sudo ufw allow 3000
sudo ufw enable
```

---

## 2. URL для приложения

После запуска backend доступен по адресу:

- `http://YOUR_SERVER_IP:3000` — без домена
- или `https://api.yourdomain.com` — если настроен Nginx + SSL

Откройте `lib/core/config/api_config.dart` и укажите этот URL:

```dart
/// Режим: 'local' — локально, 'remote' — удалённый сервер
const _apiMode = 'remote';

const String _apiHostLocal = '192.168.1.100';  // для телефона в Wi‑Fi
const String _apiHostRemote = '123.45.67.89';   // IP или домен сервера
const int _apiPort = 3000;

String get apiBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:$_apiPort';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    final host = _apiMode == 'remote' ? _apiHostRemote : _apiHostLocal;
    return 'http://$host:$_apiPort';
  }
  return 'http://localhost:$_apiPort';
}
```

Замените `123.45.67.89` на IP или домен вашего сервера.

---

## 3. Сборка и установка приложения

```bash
cd c:\myJts\my_new_project
flutter build apk
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

Скопируйте на телефон и установите. Приложение будет работать в любой сети, где есть доступ к серверу.

---

## 4. Nginx + HTTPS (опционально)

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

После настройки SSL в `api_config.dart` укажите `https://api.yourdomain.com` (без порта).
