import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/request.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class RequestsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Request> _requests = [];
  List<Map<String, dynamic>> _statuses = [];
  bool _showCompleted = false;
  bool _loading = false;
  String? _error;

  bool get loading => _loading;

  String? get error => _error;

  bool get showCompleted => _showCompleted;

  void toggleShowCompleted() {
    _showCompleted = !_showCompleted;
    notifyListeners();
  }

  void setToken(String? token) {
    _api.setToken(token);
  }

  List<Request> getFilteredRequests(AppUser currentUser) {
    var list = List<Request>.from(_requests);

    if (!_showCompleted) {
      list = list.where((r) => r.status != RequestStatus.completed).toList();
    }

    if (!currentUser.role.canSeeAllRequests) {
      list = list.where((r) {
        return r.responsibleUserId == currentUser.id ||
            r.requestorUserId == currentUser.id;
      }).toList();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Request? getById(String id) {
    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> get statuses => List.unmodifiable(_statuses);

  Future<void> loadRequests() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _statuses = await _api.getStatuses();
      _requests = await _api.getRequests(showCompleted: true);
    } on ApiException catch (e) {
      _error = e.message;
      _requests = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Request?> fetchRequest(String id) async {
    try {
      final request = await _api.getRequest(id);
      if (request != null) {
        final index = _requests.indexWhere((r) => r.id == id);
        if (index != -1) {
          _requests[index] = request;
        } else {
          _requests.insert(0, request);
        }
        notifyListeners();
      }
      return request;
    } on ApiException {
      return null;
    }
  }

  Future<void> addRequest({
    required String title,
    required String description,
    required String requestorUserId,
    String? priority,
    String? roomId,
    String? responsibleUserId,
    String? requestTypeId,
    List<Uint8List> photoBytes = const [],
  }) async {
    _error = null;
    try {
      final created = await _api.createRequest(
        title: title,
        description: description,
        priority: priority,
        roomId: roomId,
        responsibleUserId: responsibleUserId,
        requestTypeId: requestTypeId,
        photoBytes: photoBytes,
      );
      _requests.insert(0, created);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    }
  }

  Future<void> updateRequest(String id, Request request) async {
    _error = null;
    try {
      await _api.updateRequest(id,
        title: request.title,
        description: request.description,
        priority: request.priority,
        roomId: request.roomId,
        responsibleUserId: request.responsibleUserId,
        requestTypeId: request.requestTypeId,
        photoBytes: request.photoBytes.isNotEmpty ? request.photoBytes : null,
      );
      final index = _requests.indexWhere((r) => r.id == id);
      if (index != -1) {
        _requests[index] = request.copyWith(updatedAt: DateTime.now());
      }
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String statusId) async {
    _error = null;
    try {
      await _api.updateRequestStatus(id, statusId);
      final index = _requests.indexWhere((r) => r.id == id);
      if (index != -1) {
        final status = _statusFromId(statusId, _statuses);
        _requests[index] = _requests[index].copyWith(
          status: status,
          statusId: statusId,
          updatedAt: DateTime.now(),
        );
      }
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    }
  }

  RequestStatus _statusFromId(String statusId, List<Map<String, dynamic>> statuses) {
    for (final s in statuses) {
      if (s['id'] == statusId) {
        return _statusFromCode(s['code'] as String?);
      }
    }
    return RequestStatus.newRequest;
  }

  Future<void> updateRating(String id, int rating) async {
    _error = null;
    try {
      await _api.updateRequestRating(id, rating);
      final index = _requests.indexWhere((r) => r.id == id);
      if (index != -1) {
        _requests[index] = _requests[index].copyWith(
          rating: rating,
          updatedAt: DateTime.now(),
        );
      }
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    }
  }

  Future<void> deleteRequest(String id) async {
    _error = null;
    try {
      await _api.deleteRequest(id);
      _requests.removeWhere((r) => r.id == id);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStatuses() async {
    return _api.getStatuses();
  }

  Future<List<Map<String, dynamic>>> getRooms() async {
    return _api.getRooms();
  }

  Future<List<Map<String, dynamic>>> getRequestTypes() async {
    return _api.getRequestTypes();
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
}
