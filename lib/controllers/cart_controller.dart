import 'package:flutter/material.dart';

/// Debe resetearse al cerrar sesión (US02 - Regla 3).
class CartController extends ChangeNotifier {
  final List<String> _items = [];

  /// Devuelve una vista inmutable del carrito; actualmente no tiene consumidores en otras clases.
  List<String> get items => List.unmodifiable(_items);

  /// Informa cuántos artículos hay; actualmente no tiene consumidores en otras clases.
  int get itemCount => _items.length;

  /// Añade un artículo y notifica a los consumidores; actualmente no lo invocan otras clases.
  void addItem(String item) {
    _items.add(item);
    notifyListeners();
  }

  /// Reinicia el carrito al cerrar sesión; home_view.dart lo invoca al salir.
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
