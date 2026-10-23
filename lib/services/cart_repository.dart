import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';

abstract class ICartRepository {
  Future<List<CartItem>> load(int userId);

  Future<void> save(int userId, List<CartItem> items);
}

class CartRepository implements ICartRepository {
  static const _storagePrefix = 'shopping_cart_';
  final SharedPreferences? _preferences;

  CartRepository({SharedPreferences? preferences}) : _preferences = preferences;

  Future<SharedPreferences> get _prefs {
    final preferences = _preferences;
    return preferences == null
        ? SharedPreferences.getInstance()
        : Future.value(preferences);
  }

  String _key(int userId) => '$_storagePrefix$userId';

  @override
  Future<List<CartItem>> load(int userId) async {
    final value = (await _prefs).getString(_key(userId));
    if (value == null) return [];

    final decoded = jsonDecode(value);
    if (decoded is! List) {
      throw const FormatException(
          'Los datos guardados del carrito no son válidos.');
    }
    return decoded
        .map((item) => CartItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .where((item) => item.quantity > 0)
        .toList();
  }

  @override
  Future<void> save(int userId, List<CartItem> items) async {
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    final saved = await (await _prefs).setString(_key(userId), encoded);
    if (!saved) {
      throw StateError('No se pudo guardar el carrito en este dispositivo.');
    }
  }
}
