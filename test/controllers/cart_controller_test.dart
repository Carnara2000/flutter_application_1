import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/controllers/cart_controller.dart';
import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/services/cart_repository.dart';

void main() {
  group('CartController', () {
    late _MemoryCartRepository repository;
    late CartController controller;
    final product = ProductModel(
      id: 'p-1',
      title: 'Producto',
      price: 12.5,
      description: '',
      category: 'General',
      image: '',
    );

    setUp(() async {
      repository = _MemoryCartRepository();
      controller = CartController(repository: repository);
      await controller.activateForUser(42);
    });

    test('combina cantidades y calcula el total local', () async {
      await controller.addProduct(product, quantity: 2);
      await controller.addProduct(product, quantity: 3);

      expect(controller.items, hasLength(1));
      expect(controller.items.single.quantity, 5);
      expect(controller.total, 62.5);
      expect(repository.savedUserId, 42);
    });

    test('cantidad cero y eliminación remueven el artículo', () async {
      await controller.addProduct(product);
      await controller.updateQuantity(product.id, 0);

      expect(controller.isEmpty, isTrue);
      expect(controller.total, 0);

      await controller.addProduct(product);
      await controller.removeProduct(product.id);
      expect(controller.isEmpty, isTrue);
    });

    test('decrementar el último artículo elimina su producto', () async {
      await controller.addProduct(product);
      await controller.decrement(product.id);

      expect(controller.items, isEmpty);
    });
  });
}

class _MemoryCartRepository implements ICartRepository {
  final Map<int, List<CartItem>> storage = {};
  int? savedUserId;

  @override
  Future<List<CartItem>> load(int userId) async =>
      List<CartItem>.of(storage[userId] ?? []);

  @override
  Future<void> save(int userId, List<CartItem> items) async {
    savedUserId = userId;
    storage[userId] = List<CartItem>.of(items);
  }
}
