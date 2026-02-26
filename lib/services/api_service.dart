import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/request.dart';
import '../models/user.dart';
import 'api_client.dart';

class ApiService {
  final ApiClient _client = ApiClient();

  void setToken(String? token) {
    _client.setToken(token);
  }

  Future<LoginResult> login(String login, String password) async {
    final res = await _client.post('/api/auth/login', {
      'login': login,
      'password': password,
    });
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw ApiException(body['error'] ?? 'Ошибка авторизации');
    }
    final data = jsonDecode(res.body);
    final user = AppUser(
      id: data['user']['id'],
      login: data['user']['login'],
      name: data['user']['name'],
      role: _roleFromString(data['user']['role']),
    );
    return LoginResult(user: user, token: data['token']);
  }

  UserRole _roleFromString(String s) {
    switch (s) {
      case 'administrator':
        return UserRole.administrator;
      case 'director':
        return UserRole.director;
      default:
        return UserRole.user;
    }
  }

  RequestStatus _statusFromCode(String? code) {
    switch (code) {
      case 'new':
        return RequestStatus.newRequest;
      case 'in_progress':
        return RequestStatus.inProgress;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
        return RequestStatus.cancelled;
      default:
        return RequestStatus.newRequest;
    }
  }

  Future<List<Request>> getRequests({bool showCompleted = false}) async {
    final path = showCompleted ? '/api/requests?show_completed=true' : '/api/requests';
    final res = await _client.get(path);
    _checkResponse(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => _requestFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Request?> getRequest(String id) async {
    final res = await _client.get('/api/requests/$id');
    if (res.statusCode == 404) return null;
    _checkResponse(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return _requestFromJson(data, withPhotos: true);
  }

  Request _requestFromJson(Map<String, dynamic> json, {bool withPhotos = false}) {
    final status = json['status'] as Map<String, dynamic>?;
    List<Uint8List> photoBytes = [];
    if (withPhotos) {
      final photos = json['photoBase64'] as List?;
      if (photos != null) {
        for (final p in photos) {
          try {
            photoBytes.add(base64Decode(p as String));
          } catch (_) {}
        }
      }
    }
    return Request(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: _statusFromCode(status?['code'] as String?),
      statusId: status?['id'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      priority: json['priority'] as String?,
      roomNumber: json['roomNumber'] as String?,
      roomId: json['roomId'] as String?,
      requestorUserId: json['requestorUserId'] as String?,
      requestorName: json['requestorName'] as String?,
      responsibleUserId: json['responsibleUserId'] as String?,
      responsibleName: json['responsibleName'] as String?,
      rating: json['rating'] as int?,
      requestType: json['requestType'] as String?,
      requestTypeId: json['requestTypeId'] as String?,
      photoBytes: photoBytes,
    );
  }

  Future<Request> createRequest({
    required String title,
    required String description,
    String? priority,
    String? roomId,
    String? responsibleUserId,
    String? requestTypeId,
    List<Uint8List> photoBytes = const [],
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      if (priority != null) 'priority': priority,
      if (roomId != null) 'roomId': roomId,
      if (responsibleUserId != null) 'responsibleUserId': responsibleUserId,
      if (requestTypeId != null) 'requestTypeId': requestTypeId,
    };
    if (photoBytes.isNotEmpty) {
      body['photoBytes'] = photoBytes.map((b) => base64Encode(b)).toList();
    }
    final res = await _client.post('/api/requests', body);
    _checkResponse(res, statusOk: 201);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return _requestFromJson(data);
  }

  Future<void> updateRequest(String id, {
    String? title,
    String? description,
    String? priority,
    String? roomId,
    String? responsibleUserId,
    String? requestTypeId,
    List<Uint8List>? photoBytes,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (priority != null) body['priority'] = priority;
    if (roomId != null) body['roomId'] = roomId;
    if (responsibleUserId != null) body['responsibleUserId'] = responsibleUserId;
    if (requestTypeId != null) body['requestTypeId'] = requestTypeId;
    if (photoBytes != null) {
      body['photoBytes'] = photoBytes.map((b) => base64Encode(b)).toList();
    }
    final res = await _client.put('/api/requests/$id', body);
    _checkResponse(res);
  }

  Future<void> updateRequestStatus(String id, String statusId) async {
    final res = await _client.patch('/api/requests/$id/status', {'statusId': statusId});
    _checkResponse(res);
  }

  Future<void> updateRequestRating(String id, int rating) async {
    final res = await _client.patch('/api/requests/$id/rating', {'rating': rating});
    _checkResponse(res);
  }

  Future<void> deleteRequest(String id) async {
    final res = await _client.delete('/api/requests/$id');
    _checkResponse(res, statusOk: 204);
  }

  Future<List<AppUser>> getUsersForResponsible() async {
    final res = await _client.get('/api/users/for-responsible');
    _checkResponse(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return AppUser(
        id: m['id'] as String,
        login: m['login'] as String,
        name: m['name'] as String,
        role: UserRole.user,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getRooms() async {
    final res = await _client.get('/api/rooms');
    _checkResponse(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getStatuses() async {
    final res = await _client.get('/api/statuses');
    _checkResponse(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getRequestTypes() async {
    final res = await _client.get('/api/types');
    _checkResponse(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  void _checkResponse(dynamic res, {int? statusOk}) {
    final ok = statusOk ?? 200;
    if (res.statusCode == 401) {
      throw ApiException('Требуется авторизация');
    }
    if (res.statusCode != ok) {
      try {
        final body = jsonDecode(res.body);
        throw ApiException(body['error'] ?? 'Ошибка сервера');
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Ошибка: ${res.statusCode}');
      }
    }
  }
}

class LoginResult {
  final AppUser user;
  final String token;

  LoginResult({required this.user, required this.token});
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
