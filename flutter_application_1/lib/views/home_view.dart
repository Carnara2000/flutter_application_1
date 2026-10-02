import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../models/enums/user_role.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'product_detail_view.dart';
import 'widgets/product_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  /// Provee el controlador de catálogo; main.dart crea esta vista como pantalla principal.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProductController(
        authController: context.read<AuthController>(),
      ),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatefulWidget {
  const _CatalogView();

  /// Crea el estado del catálogo; Flutter lo invoca al montar HomeView.
  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  /// Carga el catálogo al abrir la pantalla; el framework lo invoca y usa ProductController de product_controller.dart.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      // loadCatalog está definido en product_controller.dart.
      (_) => context.read<ProductController>().loadCatalog(),
    );
  }

  /// Limpia sesión y carrito y regresa al login; el botón de salida de esta vista lo invoca.
  Future<void> _handleLogout() async {
    final authController = context.read<AuthController>();
    // clear está definido en cart_controller.dart.
    context.read<CartController>().clear();
    // logout está definido en auth_controller.dart.
    await authController.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  /// Abre el detalle y sincroniza bajas; las tarjetas de esta vista lo invocan y el detalle está en product_detail_view.dart.
  Future<void> _openProduct(int id) async {
    final deletedId = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailView(productId: id)),
    );
    if (deletedId != null && mounted) {
      // removeById está definido en product_controller.dart.
      context.read<ProductController>().removeById(deletedId);
    }
  }

  /// Construye el catálogo y sus controles; Flutter lo invoca tras cambios notificados por product_controller.dart.
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final controller = context.watch<ProductController>();
    final isAdmin = user?.role == UserRole.admin;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.greenPastel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.green),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tienda',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                if (user != null)
                  Text(
                    '${user.username} · ${user.role.displayName}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Agregar producto',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.createProduct),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.greenPastel, Color(0xFFD7EEDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Encuentra algo que te guste',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 21,
                                    height: 1.2,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.status == ProductStatus.loading
                              ? 'Preparando el catálogo...'
                              : '${controller.products.length} productos para explorar',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.greenDark,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.green,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (controller.categories.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 2),
                  child: Text(
                    'Explorar por categoría',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    children: [
                      _CategoryChip(
                        label: 'Todos',
                        active: controller.selectedCategory == null,
                        // selectCategory está definido en product_controller.dart.
                        onTap: () => controller.selectCategory(null),
                      ),
                      ...controller.categories.map(
                        (category) => _CategoryChip(
                          label: category,
                          active: controller.selectedCategory == category,
                          // selectCategory está definido en product_controller.dart.
                          onTap: () => controller.selectCategory(category),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          Expanded(child: _catalogBody(controller)),
        ],
      ),
    );
  }

  /// Decide qué contenido mostrar según el estado; build de esta clase lo utiliza.
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
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.green, size: 48),
              const SizedBox(height: 12),
              Text(controller.errorMessage ?? 'Ocurrió un error.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                // loadCatalog está definido en product_controller.dart.
                onPressed: controller.loadCatalog,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (controller.products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.green, size: 48),
            SizedBox(height: 12),
            Text('No hay productos disponibles.'),
          ],
        ),
      );
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
        return ProductCard(
            product: product, onTap: () => _openProduct(product.id));
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

  /// Renderiza un filtro de categoría; home_view.dart lo usa para cada chip del catálogo.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: active ? AppColors.white : AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
