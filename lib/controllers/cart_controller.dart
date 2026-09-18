import 'package:flutter/material.dart';


/// Debe resetearse al cerrar sesión (US02 - Regla 3).
class CartController extends ChangeNotifier {
  final List<String> _items = [];

  List<String> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;

  void addItem(String item) {
    _items.add(item);
    notifyListeners();
  }

  /// Reinicio total del estado (US02 - Regla 3).
  void clear() {
    _items.clear();
    notifyListeners();
  }
}