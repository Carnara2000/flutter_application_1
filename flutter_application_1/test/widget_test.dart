// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/controllers/auth_controller.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/views/login_view.dart';

/// Ejecuta las pruebas de widgets del inicio de sesión.
void main() {
  // Verifica la presentación de LoginView, definida en login_view.dart.
  testWidgets('muestra el formulario de inicio de sesión',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(authService: FakeAuthService()),
        child: const MaterialApp(home: LoginView()),
      ),
    );

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(find.byIcon(Icons.eco_rounded), findsNothing);
  });

  // Verifica la validación del formulario implementada en login_view.dart.
  testWidgets('valida los campos obligatorios', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(authService: FakeAuthService()),
        child: const MaterialApp(home: LoginView()),
      ),
    );

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Ingrese un usuario'), findsOneWidget);
    expect(find.text('Ingrese una contraseña'), findsOneWidget);
  });

  // Verifica el tratamiento del resultado de login definido en auth_controller.dart.
  test('rechaza un login que no devuelve usuario', () async {
    final controller = AuthController(authService: FakeAuthService());

    final success = await controller.login('usuario', 'clave');

    expect(success, isFalse);
    expect(controller.isAuthenticated, isFalse);
    expect(controller.errorMessage, 'No se pudo completar la autenticación');
  });
}

class FakeAuthService implements IAuthService {
  /// Simula que auth_service.dart no tiene una sesión persistida.
  @override
  Future<UserModel?> getStoredUser() async => null;

  /// Simula credenciales que no producen usuario; auth_controller.dart consume este contrato.
  @override
  Future<UserModel?> login(String username, String password) async => null;

  /// Simula el cierre de sesión definido por el contrato en auth_service.dart.
  @override
  Future<void> logout() async {}
}
