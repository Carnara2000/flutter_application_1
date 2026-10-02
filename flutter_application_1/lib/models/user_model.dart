import 'enums/user_role.dart';

class UserModel {
  final int id;
  final String username;
  final UserRole role;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
  });

  /// Asigna el rol con base en el ID; auth_service.dart lo usa al autenticar.
  factory UserModel.fromIdAndUsername(int id, String username) {
    final UserRole role;
    if (id == 1 || id == 2) {
      role = UserRole.admin;
    } else if (id == 3) {
      role = UserRole.auditor;
    } else {
      role = UserRole.client;
    }
    return UserModel(id: id, username: username, role: role);
  }

  /// Serializa el usuario para guardarlo; auth_service.dart lo usa al persistir.
  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role.name,
      };

  /// Reconstruye el usuario persistido; auth_service.dart lo usa al restaurar sesión.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.client,
      ),
    );
  }
}
