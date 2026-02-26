import 'package:flutter/foundation.dart';

/// Базовый URL API.
/// Для Android-эмулятора: 10.0.2.2 — это localhost хоста.
/// Для Web и остальных: localhost.
String get apiBaseUrl {
  if (kIsWeb) {
  //  return 'http://localhost:3000';
  //if (Platform.isAndroid) {
  //return 'http://10.0.2.2:3000';  // localhost хоста

  }
  //return 'http://localhost:3000';
  // Для Android-эмулятора раскомментируйте и замените:
   return 'http://10.0.2.2:3000';
}
