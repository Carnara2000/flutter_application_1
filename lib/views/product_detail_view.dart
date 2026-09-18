import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/product_controller.dart';
import '../models/enums/user_role.dart';
import '../models/product_model.dart';

class ProductDetailView extends StatelessWidget {
  final int productId;

  const ProductDetailView({required this.productId, super.key});

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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductController()..loadProduct(productId),
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
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 260,
              width: double.infinity,
              child: Image.network(
                product.image,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 64),
              ),
            ),
            const SizedBox(height: 20),
            Text(product.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('\$${product.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Chip(label: Text(product.category)),
            const SizedBox(height: 12),
            Text(product.description),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _edit(context, product),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _delete(context, product.id),
                    icon: const Icon(Icons.delete),
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

  Future<void> _edit(BuildContext context, ProductModel product) async {
    final title = TextEditingController(text: product.title);
    final price = TextEditingController(text: product.price.toString());
    final description = TextEditingController(text: product.description);
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar producto'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Título'), validator: (v) => v!.trim().isEmpty ? 'Requerido' : null),
            TextFormField(controller: price, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: TextInputType.number, validator: (v) => double.tryParse(v ?? '') == null ? 'Precio inválido' : null),
            TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 3, validator: (v) => v!.trim().isEmpty ? 'Requerida' : null),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, true); }, child: const Text('Guardar')),
        ],
      ),
    );
    if (save != true || !context.mounted) return;
    final updated = await context.read<ProductController>().updateProduct(
          product.copyWith(
            title: title.text.trim(),
            price: double.parse(price.text),
            description: description.text.trim(),
          ),
        );
    if (updated == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<ProductController>().errorMessage ?? 'No se pudo editar.')),
      );
    }
  }

  Future<void> _delete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Deseas eliminar este producto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await context.read<ProductController>().deleteProduct(id);
    if (!context.mounted) return;
    if (deleted) {
      Navigator.pop(context, id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<ProductController>().errorMessage ?? 'No se pudo eliminar.')),
      );
    }
  }
}
