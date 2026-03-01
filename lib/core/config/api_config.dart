import 'package:flutter/foundation.dart';

/// Режим: 'local' — локальная сеть (Wi‑Fi), 'remote' — удалённый сервер
const _apiMode = 'remote';

/// Локальная сеть: IP вашего ПК (например 192.168.1.100)
const String _apiHostLocal = '192.168.1.100';
/// Удалённый сервер: IP или домен (например 123.45.67.89 или api.example.com)
const String _apiHostRemote = '123.45.67.89';
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
