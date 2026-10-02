import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/network_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  /// Crea el estado del formulario; Flutter lo invoca al montar LoginView.
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final INetworkService _networkService = NetworkService();
  bool _showPassword = false;

  /// Libera los controladores del formulario; Flutter lo invoca al desmontar esta vista.
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida conectividad y credenciales; el botón de LoginView lo invoca en este archivo.
  Future<void> _handleLogin() async {
    // 1. Validar formulario
    if (!_formKey.currentState!.validate()) return;

    // 2. Validar conectividad (Escenario 3 US01)
    // isConnected está definido en network_service.dart.
    final hasInternet = await _networkService.isConnected();
    if (!hasInternet) {
      _showSnackBar('Sin conexión a internet. Verifica tu red.', Colors.red);
      return;
    }

    // 3. Ejecutar login a través del controlador
    final controller = context.read<AuthController>();
    // login está definido en auth_controller.dart.
    final success = await controller.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    // 4. Verificar que el widget siga montado antes de actualizar la UI
    if (!mounted) return;

    if (success) {
      // Destrucción del historial (US02 - Regla 2: Bloqueo de retroceso)
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } else {
      // Mostrar error (Escenario 2 US01: Credenciales incorrectas)
      _showSnackBar(
        controller.errorMessage ?? 'Error de autenticación',
        Colors.red,
      );
    }
  }

  /// Muestra errores de autenticación o conexión; _handleLogin de este archivo lo utiliza.
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Construye el formulario de acceso; Flutter lo invoca y main.dart monta esta vista.
  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios de estado (isLoading) del controlador
    final controller = context.watch<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.greenDark, AppColors.green],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.white,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tienda',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Todo lo que buscas, en un solo lugar.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.86,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Iniciar Sesión',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 22),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Ingresa tus datos para continuar',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 22),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Usuario',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese un usuario';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _showPassword
                                      ? 'Ocultar contraseña'
                                      : 'Mostrar contraseña',
                                  onPressed: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese una contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed:
                                  controller.isLoading ? null : _handleLogin,
                              child: controller.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Ingresar'),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
