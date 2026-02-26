import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  String? _token;

  AppUser? get currentUser => _currentUser;

  String? get token => _token;

  bool get isAuthenticated => _currentUser != null;

  List<AppUser> _usersForResponsible = [];

  List<AppUser> get usersForResponsible => List.unmodifiable(_usersForResponsible);

  final ApiService _api = ApiService();

  Future<bool> login(String login, String password) async {
    try {
      final result = await _api.login(login, password);
      _currentUser = result.user;
      _token = result.token;
      _api.setToken(_token);
      await _loadUsersForResponsible();
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<void> _loadUsersForResponsible() async {
    try {
      _usersForResponsible = await _api.getUsersForResponsible();
    } catch (_) {
      _usersForResponsible = [];
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _api.setToken(null);
    notifyListeners();
  }

  void setTokenForApi(String? token) {
    _token = token;
    _api.setToken(token);
  }

  AppUser? getUserById(String id) {
    if (_currentUser?.id == id) return _currentUser;
    return _usersForResponsible.cast<AppUser?>().firstWhere(
          (u) => u?.id == id,
          orElse: () => null,
        );
  }
}
