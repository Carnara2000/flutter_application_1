enum UserRole {
  admin('Administrador'),
  auditor('Auditor'),
  client('Cliente');

  final String displayName;
  const UserRole(this.displayName);
}