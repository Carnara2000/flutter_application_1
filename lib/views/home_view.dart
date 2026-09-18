import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../routes/app_routes.dart';
import 'product_detail_view.dart';
import 'widgets/product_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductController(),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatefulWidget {
  const _CatalogView();

  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ProductController>().loadCatalog(),
    );
  }

  Future<void> _handleLogout() async {
    final authController = context.read<AuthController>();
    context.read<CartController>().clear();
    await authController.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  Future<void> _openProduct(int id) async {
    final deletedId = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailView(productId: id)),
    );
    if (deletedId != null && mounted) {
      context.read<ProductController>().removeById(deletedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final controller = context.watch<ProductController>();
    return Scaffold(
      appBar: AppBar(
        title: user == null
            ? const Text('Catálogo')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catálogo'),
                  Text(
                    '${user.username} - ${user.role.displayName}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (controller.categories.isNotEmpty)
            SizedBox(
              height: 58,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _CategoryChip(
                    label: 'Ver todos',
                    active: controller.selectedCategory == null,
                    onTap: () => controller.selectCategory(null),
                  ),
                  ...controller.categories.map(
                    (category) => _CategoryChip(
                      label: category,
                      active: controller.selectedCategory == category,
                      onTap: () => controller.selectCategory(category),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _catalogBody(controller)),
        ],
      ),
    );
  }

  Widget _catalogBody(ProductController controller) {
    if (controller.status == ProductStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.status == ProductStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.errorMessage ?? 'Ocurrió un error.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: controller.loadCatalog,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (controller.products.isEmpty) {
      return const Center(child: Text('No hay productos disponibles.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 300,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: controller.products.length,
      itemBuilder: (_, index) {
        final product = controller.products[index];
        return ProductCard(product: product, onTap: () => _openProduct(product.id));
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: active, onSelected: (_) => onTap()),
    );
  }
}
