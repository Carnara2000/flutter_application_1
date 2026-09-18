import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

abstract class IAuthService {
  Future<UserModel?> login(String username, String password);
  Future<void> logout();
  Future<UserModel?> getStoredUser();
}

class AuthService implements IAuthService {
  final FlutterSecureStorage _secureStorage;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<UserModel?> login(String username, String password) async {
    // =============================================
    // AQUÍ SE CONECTA CON LA FAKE STORE API
    // =============================================
    final url = Uri.parse('https://fakestoreapi.com/auth/login');

    final http.Response response;
    try {
      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
    } catch (e) {
      throw AuthException('Error de conexión: $e');
    }

    // La Fake Store API devuelve 201 (no 200) cuando el login es exitoso
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Extraer el token del JSON de respuesta
      final data = jsonDecode(response.body);
      final String token = data['token'];

      // Decodificar el JWT para obtener el ID del usuario
      final Map<String, dynamic> jwtPayload = JwtDecoder.decode(token);
      final int userId = _extractUserId(jwtPayload['sub']);

      // Guardar token en almacenamiento seguro del dispositivo
      await _secureStorage.write(key: _tokenKey, value: token);

      // Crear el modelo de usuario (aquí se asigna el rol automáticamente)
      final user = UserModel.fromIdAndUsername(userId, username);

      // Guardar datos del usuario en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));

      return user;
    } else if (response.statusCode == 401) {
      throw AuthException('Usuario o contraseña inválidos');
    } else {
      throw AuthException('Error en el servidor: ${response.statusCode}');
    }
  }

  @override
  Future<void> logout() async {
    // US02: Limpieza profunda de memoria persistente
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Future<UserModel?> getStoredUser() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return null;

    return UserModel.fromJson(jsonDecode(userData));
  }

  int _extractUserId(dynamic sub) {
    if (sub is int) return sub;
    if (sub is String) return int.tryParse(sub) ?? 0;
    return 0;
  }
}