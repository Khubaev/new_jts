import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

class ApiClient {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> get(String path) async {
    return http.get(
      Uri.parse('${apiBaseUrl}$path'),
      headers: _headers,
    );
  }

  Future<http.Response> post(String path, [Map<String, dynamic>? body]) async {
    return http.post(
      Uri.parse('${apiBaseUrl}$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String path, [Map<String, dynamic>? body]) async {
    return http.put(
      Uri.parse('${apiBaseUrl}$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> patch(String path, [Map<String, dynamic>? body]) async {
    return http.patch(
      Uri.parse('${apiBaseUrl}$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String path) async {
    return http.delete(
      Uri.parse('${apiBaseUrl}$path'),
      headers: _headers,
    );
  }
}
