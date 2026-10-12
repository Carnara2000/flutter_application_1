import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'models/enums/user_role.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/product_form_view.dart';

/// Inicia la aplicación; es el punto de entrada invocado por Flutter.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Configura proveedores, tema y rutas; Flutter lo invoca al construir la raíz.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CartController()),
      ],
      child: MaterialApp(
        title: 'FakeStore MVC',
        debugShowCheckedModeBanner: false,
        // AppTheme.light está definido en app_theme.dart.
        theme: AppTheme.light,
        home: const SessionGate(),
        routes: {
          AppRoutes.login: (_) => const LoginView(),
          AppRoutes.home: (_) => const HomeView(),
          AppRoutes.createProduct: (context) =>
              context.read<AuthController>().user?.role == UserRole.admin
                  ? const ProductFormView()
                  : const HomeView(),
        },
      ),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  /// Crea el estado que decide entre inicio de sesión y catálogo.
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _isChecking = true;

  /// Restaura la sesión al iniciar; lo invoca [initState] en este archivo.
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  /// Carga la sesión guardada mediante [AuthController] (definido en auth_controller.dart).
  Future<void> _checkSession() async {
    final controller = context.read<AuthController>();
    // restoreSession está definido en auth_controller.dart.
    await controller.restoreSession();
    if (mounted) setState(() => _isChecking = false);
  }

  /// Muestra carga, catálogo o login; Flutter lo invoca tras comprobar la sesión.
  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return context.watch<AuthController>().isAuthenticated
        ? const HomeView()
        : const LoginView();
  }
}
