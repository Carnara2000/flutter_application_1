enum UserRole {
  admin('Administrador'),
  auditor('Auditor'),
  client('Cliente');

  final String displayName;

  /// Asocia cada rol con su etiqueta; la usa UserModel, definido en user_model.dart.
  const UserRole(this.displayName);
}
