import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../services/cart_repository.dart';

class CartController extends ChangeNotifier {
  final ICartRepository _repository;
  List<CartItem> _items = [];
  int? _userId;
  bool _isLoading = false;
  String? _errorMessage;
  Future<void> _writeTail = Future<void>.value();

  CartController({ICartRepository? repository})
      : _repository = repository ?? CartRepository();

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (total, item) => total + item.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> activateForUser(int? userId) async {
    if (userId == null) {
      _userId = null;
      _items = [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }
    if (_userId == userId && !_isLoading && _errorMessage == null) return;

    _userId = userId;
    _items = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _writeTail;
      _items = await _repository.load(userId);
    } catch (error) {
      _errorMessage = 'No se pudo cargar el carrito: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(ProductModel product, {int quantity = 1}) async {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Debe ser mayor a cero.');
    }
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      _items = [..._items, CartItem(product: product, quantity: quantity)];
    } else {
      final updated = [..._items];
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + quantity,
      );
      _items = updated;
    }
    _errorMessage = null;
    notifyListeners();
    await _persist();
  }

  Future<void> increment(String productId) =>
      updateQuantity(productId, _quantityOf(productId) + 1);

  Future<void> decrement(String productId) =>
      updateQuantity(productId, _quantityOf(productId) - 1);

  Future<void> updateQuantity(String productId, int quantity) async {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;
    if (quantity <= 0) {
      _items = _items.where((item) => item.product.id != productId).toList();
    } else {
      final updated = [..._items];
      updated[index] = updated[index].copyWith(quantity: quantity);
      _items = updated;
    }
    _errorMessage = null;
    notifyListeners();
    await _persist();
  }

  Future<void> removeProduct(String productId) async {
    _items = _items.where((item) => item.product.id != productId).toList();
    _errorMessage = null;
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _items = [];
    _errorMessage = null;
    notifyListeners();
    if (_userId != null) await _persist();
  }

  int _quantityOf(String productId) {
    for (final item in _items) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }

  Future<void> _persist() {
    final userId = _userId;
    if (userId == null) {
      throw StateError('No hay una sesión activa para guardar el carrito.');
    }
    final snapshot = List<CartItem>.unmodifiable(_items);
    final write = _writeTail.then((_) => _repository.save(userId, snapshot));
    _writeTail = write.catchError((Object _) {});
    return write;
  }
}
