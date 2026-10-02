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

  /// Devuelve el usuario activo; lo consultan main.dart, home_view.dart y vistas protegidas.
  UserModel? get user => _user;

  /// Expone el estado de carga; login_view.dart lo usa para bloquear el formulario.
  bool get isLoading => _isLoading;

  /// Expone el último error; login_view.dart lo muestra tras fallar el acceso.
  String? get errorMessage => _errorMessage;

  /// Indica si hay usuario activo; main.dart decide la pantalla inicial con este valor.
  bool get isAuthenticated => _user != null;

  /// Restaura la sesión persistida; main.dart lo invoca al iniciar la aplicación.
  Future<void> restoreSession() async {
    try {
      // getStoredUser está definido en auth_service.dart.
      _user = await _authService.getStoredUser();
    } catch (_) {
      // Los datos persistidos pueden quedar corruptos tras una actualización.
      _user = null;
    }
    notifyListeners();
  }

  /// Autentica y actualiza el estado; login_view.dart y las pruebas lo invocan.
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // login está definido en auth_service.dart.
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

  /// Cierra la sesión y limpia credenciales; home_view.dart lo invoca al salir.
  Future<void> logout() async {
    // logout está definido en auth_service.dart.
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  /// Actualiza el estado de carga y notifica; login de este archivo lo usa.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Publica un error y finaliza la carga; login de este archivo lo utiliza.
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Borra el mensaje anterior; login de este archivo lo invoca antes de autenticar.
  void _clearError() {
    _errorMessage = null;
  }
}
