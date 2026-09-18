import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/network_service.dart';
import '../services/product_service.dart';

enum ProductStatus { idle, loading, loaded, error }

class ProductController extends ChangeNotifier {
  final IProductService _service;
  final INetworkService _networkService;
  int _requestId = 0;

  ProductStatus _status = ProductStatus.idle;
  List<ProductModel> _products = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String? _errorMessage;
  ProductModel? _product;

  ProductController({
    IProductService? service,
    INetworkService? networkService,
  })  : _service = service ?? ProductService(),
        _networkService = networkService ?? NetworkService();

  ProductStatus get status => _status;
  List<ProductModel> get products => List.unmodifiable(_products);
  List<String> get categories => List.unmodifiable(_categories);
  String? get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;
  ProductModel? get product => _product;

  Future<void> loadCatalog() async {
    final request = ++_requestId;
    _setLoading();
    _products = [];
    try {
      final connected = await _networkService.isConnected();
      if (!connected) throw const ProductException('No hay conexión a Internet.');
      final results = await Future.wait([
        _service.getProducts(),
        _service.getCategories(),
      ]);
      if (request != _requestId) return;
      _products = results[0] as List<ProductModel>;
      _categories = results[1] as List<String>;
      _selectedCategory = null;
      _setLoaded();
    } on ProductException catch (e) {
      if (request == _requestId) _setError(e.message);
    } catch (e) {
      if (request == _requestId) _setError('No se pudo cargar el catálogo: $e');
    }
  }

  Future<void> selectCategory(String? category) async {
    if (category == _selectedCategory && category != null) {
      await loadCatalog();
      return;
    }
    final request = ++_requestId;
    _setLoading();
    _products = [];
    try {
      final connected = await _networkService.isConnected();
      if (!connected) throw const ProductException('No hay conexión a Internet.');
      final products = category == null
          ? await _service.getProducts()
          : await _service.getProductsByCategory(category);
      if (request != _requestId) return;
      _products = products;
      _selectedCategory = category;
      _setLoaded();
    } on ProductException catch (e) {
      if (request == _requestId) _setError(e.message);
    } catch (e) {
      if (request == _requestId) _setError('No se pudo filtrar el catálogo: $e');
    }
  }

  Future<bool> loadProduct(int id) async {
    _product = null;
    _setLoading();
    try {
      if (!await _networkService.isConnected()) {
        throw const ProductException('No hay conexión a Internet.');
      }
      _product = await _service.getProduct(id);
      if (_product == null) {
        _setError('Producto no disponible');
        return false;
      }
      _setLoaded();
      return true;
    } on ProductException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('No se pudo cargar el producto: $e');
      return false;
    }
  }

  Future<ProductModel?> updateProduct(ProductModel product) async {
    try {
      if (!await _networkService.isConnected()) {
        throw const ProductException('No hay conexión a Internet.');
      }
      final updated = await _service.updateProduct(product);
      _product = updated;
      _setLoaded();
      return updated;
    } on ProductException catch (e) {
      _setError(e.message);
      return null;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      if (!await _networkService.isConnected()) {
        throw const ProductException('No hay conexión a Internet.');
      }
      await _service.deleteProduct(id);
      return true;
    } on ProductException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  void removeById(int id) {
    _products = _products.where((product) => product.id != id).toList();
    notifyListeners();
  }

  void _setLoading() {
    _status = ProductStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoaded() {
    _status = ProductStatus.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = ProductStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
