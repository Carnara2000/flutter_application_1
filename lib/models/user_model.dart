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

  // =============================================
  // AQUÍ SE ASIGNA EL ROL SEGÚN EL ID
  // Regla de negocio del profesor:
  // ID 1 y 2 → Administrador
  // ID 3 → Auditor
  // ID 4 en adelante → Cliente
  // =============================================
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role.name,
      };

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