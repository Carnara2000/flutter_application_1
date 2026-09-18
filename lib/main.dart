import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'routes/app_routes.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        home: const SessionGate(),
        routes: {
          AppRoutes.login: (_) => const LoginView(),
          AppRoutes.home: (_) => const HomeView(),
        },
      ),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final controller = context.read<AuthController>();
    await controller.restoreSession();
    if (mounted) setState(() => _isChecking = false);
  }

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