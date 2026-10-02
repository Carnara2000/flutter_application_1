import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/controllers/auth_controller.dart';
import 'package:flutter_application_1/controllers/product_controller.dart';
import 'package:flutter_application_1/models/enums/user_role.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/network_service.dart';
import 'package:flutter_application_1/services/product_service.dart';
import 'package:flutter_application_1/views/product_form_view.dart';

/// Ejecuta pruebas de validación y autorización del alta de productos.
void main() {
  // Verifica validación del formulario definido en product_form_view.dart.
  testWidgets('el alta marca campos inválidos sin enviar el formulario',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final authController = AuthController(
      authService: _FakeAuthService(
        UserModel(id: 1, username: 'admin', role: UserRole.admin),
      ),
    );
    await authController.login('admin', 'password');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authController,
        child: const MaterialApp(home: ProductFormView()),
      ),
    );

    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    expect(find.text('Ingrese un título.'), findsOneWidget);
    expect(find.text('Ingrese un precio.'), findsOneWidget);
    expect(find.text('Ingrese una descripción.'), findsOneWidget);
    expect(find.text('Ingrese una URL de imagen.'), findsOneWidget);
    expect(find.text('Ingrese una categoría.'), findsOneWidget);
  });

  // Comprueba validación local implementada en product_form_view.dart.
  testWidgets('el alta valida localmente el precio y la URL', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final authController = AuthController(
      authService: _FakeAuthService(
        UserModel(id: 1, username: 'admin', role: UserRole.admin),
      ),
    );
    await authController.login('admin', 'password');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authController,
        child: const MaterialApp(home: ProductFormView()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Producto');
    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    await tester.enterText(find.byType(TextFormField).at(2), 'Descripción');
    await tester.enterText(find.byType(TextFormField).at(3), 'no-es-una-url');
    await tester.enterText(find.byType(TextFormField).at(4), 'Categoría');
    await tester.tap(find.text('Guardar producto'));
    await tester.pumpAndSettle();

    expect(find.text('Ingrese un precio numérico válido.'), findsOneWidget);
    expect(find.text('Ingrese una URL válida (http o https).'), findsOneWidget);
  });

  // Comprueba la protección de ruta implementada en product_form_view.dart.
  testWidgets('un auditor es redirigido al catálogo desde alta',
      (tester) async {
    final authController = AuthController(
      authService: _FakeAuthService(
        UserModel(id: 3, username: 'auditor', role: UserRole.auditor),
      ),
    );
    await authController.login('auditor', 'password');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authController,
        child: MaterialApp(
          initialRoute: '/products/create',
          routes: {
            '/products/create': (_) => const ProductFormView(),
            '/home': (_) => const Scaffold(body: Text('Catálogo principal')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catálogo principal'), findsOneWidget);
    expect(find.text('Agregar producto'), findsNothing);
  });

  // Verifica que ProductController, definido en product_controller.dart, rechaza mutaciones de cliente.
  test('un cliente no puede ejecutar operaciones de modificación', () async {
    final authController = AuthController(
      authService: _FakeAuthService(
        UserModel(id: 4, username: 'cliente', role: UserRole.client),
      ),
    );
    await authController.login('cliente', 'password');
    final service = _FakeProductService();
    final controller = ProductController(
      authController: authController,
      service: service,
      networkService: _FakeNetworkService(),
    );
    const product = ProductModel(
      id: 1,
      title: 'Producto',
      price: 10,
      description: 'Descripción',
      category: 'Categoría',
      image: 'https://example.com/image.png',
    );

    expect(await controller.createProduct(product), isNull);
    expect(await controller.updateProduct(product), isNull);
    expect(await controller.deleteProduct(product.id), isFalse);
    expect(service.mutationCalls, 0);
  });

  // Verifica que ProductService, definido en product_service.dart, protege también su acceso directo.
  test('el servicio bloquea mutaciones sin autorización antes de red',
      () async {
    final service = ProductService();
    const product = ProductModel(
      id: 1,
      title: 'Producto',
      price: 10,
      description: 'Descripción',
      category: 'Categoría',
      image: 'https://example.com/image.png',
    );

    await expectLater(
      service.createProduct(product),
      throwsA(isA<ProductException>()),
    );
    await expectLater(
      service.updateProduct(product),
      throwsA(isA<ProductException>()),
    );
    await expectLater(
      service.deleteProduct(product.id),
      throwsA(isA<ProductException>()),
    );
  });
}

class _FakeAuthService implements IAuthService {
  final UserModel user;

  _FakeAuthService(this.user);

  /// Simula que auth_service.dart no tiene sesión persistida.
  @override
  Future<UserModel?> getStoredUser() async => null;

  /// Devuelve el usuario configurado; AuthController de auth_controller.dart consume este contrato.
  @override
  Future<UserModel?> login(String username, String password) async => user;

  /// Simula el cierre de sesión del contrato definido en auth_service.dart.
  @override
  Future<void> logout() async {}
}

class _FakeNetworkService implements INetworkService {
  /// Simula una conexión disponible; ProductController de product_controller.dart consume este contrato.
  @override
  Future<bool> isConnected() async => true;
}

class _FakeProductService implements IProductService {
  int mutationCalls = 0;

  /// Registra la solicitud de alta del contrato definido en product_service.dart.
  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    mutationCalls++;
    return product.copyWith(id: 101);
  }

  /// Registra la solicitud de baja del contrato definido en product_service.dart.
  @override
  Future<void> deleteProduct(int id) async {
    mutationCalls++;
  }

  /// Devuelve una lista de categorías vacía para ProductController de product_controller.dart.
  @override
  Future<List<String>> getCategories() async => [];

  /// Simula que no existe el producto solicitado; implementa el contrato de product_service.dart.
  @override
  Future<ProductModel?> getProduct(int id) async => null;

  /// Devuelve un catálogo vacío para ProductController de product_controller.dart.
  @override
  Future<List<ProductModel>> getProducts() async => [];

  /// Devuelve una categoría sin productos para ProductController de product_controller.dart.
  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async => [];

  /// Registra la solicitud de actualización definida en product_service.dart.
  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    mutationCalls++;
    return product;
  }
}
