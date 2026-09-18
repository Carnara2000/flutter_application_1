import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_model.dart';

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
  Future<ProductModel?> getProduct(int id);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> deleteProduct(int id);
}

class ProductService implements IProductService {
  static final Uri _baseUri = Uri.parse('https://fakestoreapi.com');

  Future<dynamic> _request(String method, Uri uri, {Map<String, dynamic>? body}) async {
    try {
      final response = switch (method) {
        'GET' => await http.get(uri),
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
          'La API no pudo completar la operación (código ${response.statusCode}).',
        );
      }
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } on ProductException {
      rethrow;
    } on FormatException {
      throw const ProductException('La respuesta de la API no es válida.');
    } catch (e) {
      throw ProductException('No se pudo conectar con Fake Store API: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    final data = await _request('GET', _baseUri.resolve('/products'));
    if (data is! List) throw const ProductException('La API devolvió un catálogo inválido.');
    return data
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  @override
  Future<List<String>> getCategories() async {
    final data = await _request('GET', _baseUri.resolve('/products/categories'));
    if (data is! List) throw const ProductException('No se pudieron cargar las categorías.');
    return data.whereType<String>().toList();
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final path = '/products/category/${Uri.encodeComponent(category)}';
    final data = await _request('GET', _baseUri.resolve(path));
    if (data is! List) throw const ProductException('La categoría no devolvió productos válidos.');
    return data
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  @override
  Future<ProductModel?> getProduct(int id) async {
    final data = await _request('GET', _baseUri.resolve('/products/$id'));
    if (data is! Map<String, dynamic> || data.isEmpty) return null;
    return ProductModel.fromJson(data);
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    final data = await _request(
      'PUT',
      _baseUri.resolve('/products/${product.id}'),
      body: product.toJson(),
    );
    if (data is! Map<String, dynamic> || data.isEmpty) {
      throw const ProductException('La API no devolvió el producto actualizado.');
    }
    return ProductModel.fromJson(data);
  }

  @override
  Future<void> deleteProduct(int id) async {
    await _request('DELETE', _baseUri.resolve('/products/$id'));
  }
}
