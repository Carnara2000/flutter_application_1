import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/product_controller.dart';
import '../models/enums/user_role.dart';
import '../models/product_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class ProductFormView extends StatelessWidget {
  const ProductFormView({super.key});

  /// Provee el controlador de productos; main.dart monta esta vista para la ruta de alta.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductController(
        authController: context.read<AuthController>(),
      ),
      child: const _ProductFormContent(),
    );
  }
}

class _ProductFormContent extends StatefulWidget {
  const _ProductFormContent();

  /// Crea el estado del formulario; Flutter lo invoca al montar esta vista interna.
  @override
  State<_ProductFormContent> createState() => _ProductFormContentState();
}

class _ProductFormContentState extends State<_ProductFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isSubmitting = false;
  bool _redirectScheduled = false;

  /// Consulta permisos; didChangeDependencies y build de esta clase la usan.
  bool get _isAdmin =>
      context.read<AuthController>().user?.role == UserRole.admin;

  /// Redirige usuarios sin permisos; Flutter lo invoca al cambiar dependencias.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAdmin && !_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (_) => false,
          );
        }
      });
    }
  }

  /// Libera los controladores del formulario; Flutter lo invoca al desmontar la vista.
  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// Valida que un campo tenga contenido; los validadores del formulario de este archivo la usan.
  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Ingrese $label.';
    return null;
  }

  /// Valida que el precio sea numérico; el campo Precio de este archivo la usa como validador.
  String? _validatePrice(String? value) {
    final requiredError = _required(value, 'un precio');
    if (requiredError != null) return requiredError;
    final price = double.tryParse(value!.trim());
    if (price == null || !price.isFinite)
      return 'Ingrese un precio numérico válido.';
    return null;
  }

  /// Valida una URL HTTP(S); el campo de imagen de este archivo la usa como validador.
  String? _validateImageUrl(String? value) {
    final requiredError = _required(value, 'una URL de imagen');
    if (requiredError != null) return requiredError;
    final uri = Uri.tryParse(value!.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Ingrese una URL válida (http o https).';
    }
    return null;
  }

  /// Valida y crea el producto; el botón Guardar de esta vista lo invoca mediante ProductController de product_controller.dart.
  Future<void> _submit() async {
    if (!_isAdmin || _isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final controller = context.read<ProductController>();
    // createProduct está definido en product_controller.dart.
    final created = await controller.createProduct(
      ProductModel(
        id: 0,
        title: _titleController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
        image: _imageController.text.trim(),
        category: _categoryController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(controller.errorMessage ?? 'No se pudo crear el producto.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Producto registrado'),
        content: Text('Producto creado con el ID ${created.id}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _formKey.currentState!.reset();
    _titleController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _imageController.clear();
    _categoryController.clear();
  }

  /// Construye el formulario administrativo; Flutter lo invoca al mostrar la vista.
  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar producto'),
        leading: IconButton(
          tooltip: 'Volver al catálogo',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.greenPastel,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart_rounded,
                              color: AppColors.green,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nuevo artículo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontSize: 20),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Completa los datos para registrarlo en el catálogo.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Información del producto',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Título',
                                prefixIcon: Icon(Icons.sell_outlined),
                              ),
                              validator: (value) =>
                                  _required(value, 'un título'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Precio',
                                prefixIcon: Icon(Icons.attach_money_rounded),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: _validatePrice,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Descripción',
                                prefixIcon: Icon(Icons.notes_rounded),
                                alignLabelWithHint: true,
                              ),
                              minLines: 3,
                              maxLines: 5,
                              validator: (value) =>
                                  _required(value, 'una descripción'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _imageController,
                              decoration: const InputDecoration(
                                labelText: 'URL de imagen',
                                prefixIcon: Icon(Icons.image_outlined),
                              ),
                              keyboardType: TextInputType.url,
                              validator: _validateImageUrl,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _categoryController,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              validator: (value) =>
                                  _required(value, 'una categoría'),
                            ),
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              onPressed: _isSubmitting ? null : _submit,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(
                                _isSubmitting
                                    ? 'Guardando...'
                                    : 'Guardar producto',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
