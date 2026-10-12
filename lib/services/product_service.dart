import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_model.dart';

const String baseUrl = 'http://192.168.100.3:3000/api';

class ProductException implements Exception {
  final String message;

  const ProductException(this.message);

  @override
  String toString() => message;
}

abstract class IProductService {
  Future<List<ProductModel>> getProducts();

  Future<List<String>> getCategories();

  Future<List<ProductModel>> getProductsByCategory(String category);

  Future<ProductModel?> getProduct(String id);

  Future<ProductModel> createProduct(ProductModel product);

  Future<ProductModel> updateProduct(ProductModel product);

  Future<void> deleteProduct(String id);
}

class ProductService implements IProductService {
  static final Uri _productsUri = Uri.parse('$baseUrl/productos');
  final bool Function() _isAdmin;

  ProductService({bool Function()? isAdmin})
      : _isAdmin = isAdmin ?? (() => false);

  Future<dynamic> _request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = switch (method) {
        'GET' => await http.get(uri),
        'POST' => await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          ),
        'PUT' => await http.put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          ),
        'DELETE' => await http.delete(uri),
        _ => throw const ProductException('Operación no soportada'),
      };

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ProductException(
          'El servidor no pudo completar la operación '
          '(código ${response.statusCode}).',
        );
      }
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } on ProductException {
      rethrow;
    } on FormatException {
      throw const ProductException('La respuesta del servidor no es válida.');
    } catch (e) {
      throw ProductException('No se pudo conectar con el servidor: $e');
    }
  }

  void _requireAdmin() {
    if (!_isAdmin()) {
      throw const ProductException(
        'Acceso denegado: solo un Administrador puede modificar productos.',
      );
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    final data = await _request('GET', _productsUri);
    if (data is! List) {
      throw const ProductException(
          'El servidor devolvió un catálogo inválido.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  @override
  Future<List<String>> getCategories() async {
    final products = await getProducts();
    return products.map((product) => product.category).toSet().toList();
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final products = await getProducts();
    return products.where((product) => product.category == category).toList();
  }

  @override
  Future<ProductModel?> getProduct(String id) async {
    final products = await getProducts();
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    _requireAdmin();
    final data = await _request(
      'POST',
      _productsUri,
      body: {
        'title': product.title,
        'price': product.price,
        'description': product.description,
        'category': product.category,
        'image': product.image,
      },
    );
    if (data is! Map<String, dynamic> || data['_id'] is! String) {
      throw const ProductException(
        'El servidor no devolvió el ID Mongo del producto creado.',
      );
    }
    return ProductModel.fromJson(data);
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    _requireAdmin();
    final data = await _request(
      'PUT',
      Uri.parse('$baseUrl/productos/${product.id}'),
      body: {
        'title': product.title,
        'price': product.price,
        'description': product.description,
        'category': product.category,
        'image': product.image,
      },
    );
    if (data is! Map<String, dynamic> || data.isEmpty) {
      throw const ProductException(
        'El servidor no devolvió el producto actualizado.',
      );
    }
    return ProductModel.fromJson(data);
  }

  @override
  Future<void> deleteProduct(String id) async {
    _requireAdmin();
    final data = await _request(
      'DELETE',
      Uri.parse('$baseUrl/productos/$id'),
    );
    if (data is! Map<String, dynamic> || data['producto'] is! Map) {
      throw const ProductException('El servidor no confirmó la eliminación.');
    }
  }
}
