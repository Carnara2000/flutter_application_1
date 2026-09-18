import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Controlador que gestiona el estado de autenticación.
/// Sigue el patrón Observer (ChangeNotifier) para notificar a las vistas.
class AuthController extends ChangeNotifier {
  final IAuthService _authService;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController({IAuthService? authService})
      : _authService = authService ?? AuthService();

  // Getters encapsulados
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  /// Restaura la sesión desde almacenamiento persistente.
  Future<void> restoreSession() async {
    try {
      _user = await _authService.getStoredUser();
    } catch (_) {
      // Los datos persistidos pueden quedar corruptos tras una actualización.
      _user = null;
    }
    notifyListeners();
  }

  /// Ejecuta el flujo completo de login.
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.login(username, password);
      if (user == null) {
        _setError('No se pudo completar la autenticación');
        return false;
      }
      _user = user;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Error inesperado: $e');
      return false;
    }
  }

  /// Cierra la sesión y limpia credenciales (US02).
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}