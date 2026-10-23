import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../models/enums/user_role.dart';
import '../models/cart_item.dart';
import '../theme/app_theme.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.read<AuthController>().user?.role != UserRole.client) {
      return const Scaffold(
        body: Center(child: Text('El carrito está disponible para Clientes.')),
      );
    }

    final cart = context.watch<CartController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mi carrito')),
      body: cart.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cart.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      cart.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : cart.isEmpty
                  ? _EmptyCart(onExplore: () => Navigator.maybePop(context))
                  : _CartContents(cart: cart),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onExplore;

  const _EmptyCart({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.remove_shopping_cart_outlined,
              size: 76,
              color: AppColors.green,
            ),
            const SizedBox(height: 18),
            Text(
              'Tu carrito está vacío, explora el catálogo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Explorar catálogo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartContents extends StatelessWidget {
  final CartController cart;

  const _CartContents({required this.cart});

  Future<void> _perform(
    BuildContext context,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el carrito: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CartProductTile(
              item: cart.items[index],
              onIncrement: () => _perform(
                context,
                () => cart.increment(cart.items[index].product.id),
              ),
              onDecrement: () => _perform(
                context,
                () => cart.decrement(cart.items[index].product.id),
              ),
              onRemove: () => _perform(
                context,
                () => cart.removeProduct(cart.items[index].product.id),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '\$${cart.total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.greenDark,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: cart.isEmpty
                      ? null
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'La simulación de pago no está implementada.',
                              ),
                            ),
                          ),
                  child: const Text('Proceder al pago'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartProductTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartProductTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 68,
                height: 68,
                child: Image.network(
                  product.image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('\$${product.price.toStringAsFixed(2)} c/u'),
                  Text(
                    'Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Eliminar producto',
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Reducir cantidad',
                      onPressed: onDecrement,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      tooltip: 'Aumentar cantidad',
                      onPressed: onIncrement,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
