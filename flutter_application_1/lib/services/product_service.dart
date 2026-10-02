import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_model.dart';

class ProductException implements Exception {
  final String message;

  const ProductException(this.message);

  /// Devuelve el texto del error; product_controller.dart lo usa para informar fallos.
  @override
  String toString() => message;
}

abstract class IProductService {
  /// Contrato de catálogo implementado por ProductService en este archivo.
  Future<List<ProductModel>> getProducts();

  /// Contrato de carga de categorías implementado por ProductService en este archivo.
  Future<List<String>> getCategories();

  /// Contrato de filtro por categoría implementado por ProductService en este archivo.
  Future<List<ProductModel>> getProductsByCategory(String category);

  /// Contrato de búsqueda de producto implementado por ProductService en este archivo.
  Future<ProductModel?> getProduct(int id);

  /// Contrato de alta implementado por ProductService en este archivo.
  Future<ProductModel> createProduct(ProductModel product);

  /// Contrato de actualización implementado por ProductService en este archivo.
  Future<ProductModel> updateProduct(ProductModel product);

  /// Contrato de eliminación implementado por ProductService en este archivo.
  Future<void> deleteProduct(int id);
}

class ProductService implements IProductService {
  static final Uri _baseUri = Uri.parse('https://fakestoreapi.com');
  final bool Function() _isAdmin;

  ProductService({bool Function()? isAdmin})
      : _isAdmin = isAdmin ?? (() => false);

  /// Ejecuta petición HTTP y valida respuesta; los métodos públicos de ProductService la utilizan.
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

  /// Impide mutaciones si el usuario no es administrador; altas, cambios y bajas lo invocan.
  void _requireAdmin() {
    if (!_isAdmin()) {
      throw const ProductException(
        'Acceso denegado: solo un Administrador puede modificar productos.',
      );
    }
  }

  /// Descarga y convierte el catálogo; ProductController, definido en product_controller.dart, lo usa.
  @override
  Future<List<ProductModel>> getProducts() async {
    final data = await _request('GET', _baseUri.resolve('/products'));
    if (data is! List)
      throw const ProductException('La API devolvió un catálogo inválido.');
    // ProductModel.fromJson está definido en product_model.dart.
    return data
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  /// Descarga las categorías del catálogo; ProductController, definido en product_controller.dart, lo usa.
  @override
  Future<List<String>> getCategories() async {
    final data =
        await _request('GET', _baseUri.resolve('/products/categories'));
    if (data is! List)
      throw const ProductException('No se pudieron cargar las categorías.');
    return data.whereType<String>().toList();
  }

  /// Descarga productos de una categoría; ProductController, definido en product_controller.dart, lo usa.
  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final path = '/products/category/${Uri.encodeComponent(category)}';
    final data = await _request('GET', _baseUri.resolve(path));
    if (data is! List)
      throw const ProductException(
          'La categoría no devolvió productos válidos.');
    // ProductModel.fromJson está definido en product_model.dart.
    return data
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  /// Recupera un producto por ID; ProductController, definido en product_controller.dart, lo usa.
  @override
  Future<ProductModel?> getProduct(int id) async {
    final data = await _request('GET', _baseUri.resolve('/products/$id'));
    if (data is! Map<String, dynamic> || data.isEmpty) return null;
    // ProductModel.fromJson está definido en product_model.dart.
    return ProductModel.fromJson(data);
  }

  /// Envía el alta tras verificar rol; ProductController, definido en product_controller.dart, lo usa.
  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    _requireAdmin();
    final data = await _request(
      'POST',
      _baseUri.resolve('/products'),
      body: {
        'title': product.title,
        'price': product.price,
        'description': product.description,
        'image': product.image,
        'category': product.category,
      },
    );
    if (data is! Map<String, dynamic> || data.isEmpty || data['id'] == null) {
      throw const ProductException('La API no devolvió el ID del producto.');
    }
    // ProductModel.fromJson está definido en product_model.dart.
    return ProductModel.fromJson(data);
  }

  /// Envía la actualización tras verificar rol; ProductController, definido en product_controller.dart, lo usa.
  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    _requireAdmin();
    final data = await _request(
      'PUT',
      _baseUri.resolve('/products/${product.id}'),
      // ProductModel.toJson está definido en product_model.dart.
      body: product.toJson(),
    );
    if (data is! Map<String, dynamic> || data.isEmpty) {
      throw const ProductException(
          'La API no devolvió el producto actualizado.');
    }
    // ProductModel.fromJson está definido en product_model.dart.
    return ProductModel.fromJson(data);
  }

  /// Envía la eliminación tras verificar rol; ProductController, definido en product_controller.dart, lo usa.
  @override
  Future<void> deleteProduct(int id) async {
    _requireAdmin();
    final data = await _request('DELETE', _baseUri.resolve('/products/$id'));
    if (data is! Map<String, dynamic> || data.isEmpty) {
      throw const ProductException('La API no confirmó la eliminación.');
    }
  }
}
