enum UserRole {
  administrator,
  director,
  user,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.administrator:
        return 'Администратор';
      case UserRole.director:
        return 'Директор';
      case UserRole.user:
        return 'Пользователь';
    }
  }

  bool get canSeeAllRequests =>
      this == UserRole.administrator || this == UserRole.director;
}

class AppUser {
  final String id;
  final String login;
  final String name;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.login,
    required this.name,
    required this.role,
  });
}
