import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/product_controller.dart';
import '../models/enums/user_role.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

class ProductDetailView extends StatelessWidget {
  final int productId;

  const ProductDetailView({required this.productId, super.key});

  /// Informa si el producto no existe y regresa; build de ProductDetailView lo utiliza.
  Future<void> _showUnavailable(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Producto no disponible'),
        content: const Text('No fue posible encontrar este producto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (context.mounted) Navigator.pop(context);
  }

  /// Carga el producto y prepara el detalle; HomeView, definido en home_view.dart, abre esta vista.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProductController(
        authController: context.read<AuthController>(),
        // loadProduct está definido en product_controller.dart.
      )..loadProduct(productId),
      child: _ProductDetailContent(
        productId: productId,
        onUnavailable: _showUnavailable,
      ),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  final int productId;
  final Future<void> Function(BuildContext) onUnavailable;

  const _ProductDetailContent({
    required this.productId,
    required this.onUnavailable,
  });

  /// Renderiza el producto, o las acciones de administración; Flutter lo invoca tras cargar product_controller.dart.
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductController>();
    final product = controller.product;
    if (controller.status == ProductStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (product == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) onUnavailable(context);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final authRole = context.read<AuthController>().user?.role;
    final isAdmin = authRole == UserRole.admin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        leading: IconButton(
          tooltip: 'Volver al catálogo',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.greenPastel, AppColors.greenPale],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Image.network(
                product.image,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.green,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenPastel,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: AppColors.greenDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      product.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 25,
                              ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenPale,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Descripción',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 7),
                    Text(product.description),
                  ],
                ),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => _edit(context, product),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _delete(context, product.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Edita los datos del producto y los envía al controlador; el botón Editar de esta vista la invoca.
  Future<void> _edit(BuildContext context, ProductModel product) async {
    final title = TextEditingController(text: product.title);
    final price = TextEditingController(text: product.price.toString());
    final description = TextEditingController(text: product.description);
    final category = TextEditingController(text: product.category);
    final formKey = GlobalKey<FormState>();
    var isSaving = false;
    String? saveError;
    final controller = context.read<ProductController>();
    final save = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar producto'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingrese un título.'
                        : null,
                  ),
                  TextFormField(
                    controller: price,
                    decoration: const InputDecoration(labelText: 'Precio'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      return parsed == null || !parsed.isFinite
                          ? 'Ingrese un precio numérico válido.'
                          : null;
                    },
                  ),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingrese una descripción.'
                        : null,
                  ),
                  TextFormField(
                    controller: category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingrese una categoría.'
                        : null,
                  ),
                  if (saveError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      saveError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSaving = true;
                        saveError = null;
                      });
                      // updateProduct está definido en product_controller.dart.
                      final updated = await controller.updateProduct(
                        product.copyWith(
                          // copyWith está definido en product_model.dart.
                          title: title.text.trim(),
                          price: double.parse(price.text.trim()),
                          description: description.text.trim(),
                          category: category.text.trim(),
                        ),
                      );
                      if (!dialogContext.mounted) return;
                      if (updated == null) {
                        setDialogState(() {
                          isSaving = false;
                          saveError = controller.errorMessage ??
                              'No se pudo actualizar el producto.';
                        });
                        return;
                      }
                      Navigator.pop(dialogContext, true);
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    price.dispose();
    description.dispose();
    category.dispose();
    if (save == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto actualizado (Simulación)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Confirma y elimina el producto; el botón Eliminar de esta vista la invoca mediante ProductController de product_controller.dart.
  Future<void> _delete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Estás seguro de eliminar este producto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // deleteProduct está definido en product_controller.dart.
    final deleted = await context.read<ProductController>().deleteProduct(id);
    if (!context.mounted) return;
    if (deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto eliminado (Simulación)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.read<ProductController>().errorMessage ??
                'No se pudo eliminar.')),
      );
    }
  }
}
