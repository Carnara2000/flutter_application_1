import 'package:flutter/foundation.dart';

import '../controllers/auth_controller.dart';
import '../models/enums/user_role.dart';
import '../models/product_model.dart';
import '../services/network_service.dart';
import '../services/product_service.dart';

enum ProductStatus { idle, loading, loaded, error }

class ProductController extends ChangeNotifier {
  late final IProductService _service;
  final INetworkService _networkService;
  final AuthController? _authController;
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
    AuthController? authController,
  })  : _networkService = networkService ?? NetworkService(),
        _authController = authController {
    _service = service ?? ProductService(isAdmin: () => _isAdmin);
  }

  /// Expone el estado de carga; home_view.dart y product_detail_view.dart lo consultan.
  ProductStatus get status => _status;

  /// Entrega el catálogo sin permitir modificaciones externas; home_view.dart lo muestra.
  List<ProductModel> get products => List.unmodifiable(_products);

  /// Entrega las categorías; home_view.dart genera sus filtros con esta lista.
  List<String> get categories => List.unmodifiable(_categories);

  /// Devuelve la categoría seleccionada; home_view.dart marca el filtro activo.
  String? get selectedCategory => _selectedCategory;

  /// Expone el error del catálogo; home_view.dart lo presenta en pantalla.
  String? get errorMessage => _errorMessage;

  /// Devuelve el producto del detalle; product_detail_view.dart lo renderiza.
  ProductModel? get product => _product;

  /// Verifica permisos del usuario; los métodos de modificación de este archivo lo consultan.
  bool get _isAdmin => _authController?.user?.role == UserRole.admin;

  /// Carga catálogo y categorías; home_view.dart lo invoca al iniciar y reintentar.
  Future<void> loadCatalog() async {
    final request = ++_requestId;
    _setLoading();
    _products = [];
    try {
      // isConnected está definido en network_service.dart.
      final connected = await _networkService.isConnected();
      if (!connected)
        throw const ProductException('No hay conexión a Internet.');
      // getProducts y getCategories están definidos en product_service.dart.
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

  /// Filtra productos por categoría; home_view.dart lo invoca al seleccionar un filtro.
  Future<void> selectCategory(String? category) async {
    if (category == _selectedCategory && category != null) {
      await loadCatalog();
      return;
    }
    final request = ++_requestId;
    _setLoading();
    _products = [];
    try {
      // isConnected está definido en network_service.dart.
      final connected = await _networkService.isConnected();
      if (!connected)
        throw const ProductException('No hay conexión a Internet.');
      // Las consultas de catálogo están definidas en product_service.dart.
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
      if (request == _requestId)
        _setError('No se pudo filtrar el catálogo: $e');
    }
  }

  /// Busca un producto por ID; product_detail_view.dart lo invoca al abrir el detalle.
  Future<bool> loadProduct(int id) async {
    _product = null;
    _setLoading();
    try {
      // isConnected está definido en network_service.dart.
      if (!await _networkService.isConnected()) {
        throw const ProductException('No hay conexión a Internet.');
      }
      // getProduct está definido en product_service.dart.
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

  /// Actualiza un producto para administradores; product_detail_view.dart lo invoca al guardar cambios.
  Future<ProductModel?> updateProduct(ProductModel product) async {
    if (!_isAdmin) {
      _setError(
          'Acceso denegado: solo un Administrador puede modificar productos.');
      return null;
    }
    _setLoading();
    try {
      // isConnected está definido en network_service.dart.
      if (!await _networkService.isConnected()) {
        throw const ProductException('No hay conexión a Internet.');
      }
      // updateProduct está definido en product_service.dart.
      final updated = await _service.updateProduct(product);
      _product = updated;
      _setLoaded();
      return updated;
    } on ProductException catch (e) {
      _setError(e.message);
      return null;
    } catch (e) {
      _setError('No se pudo actualizar el producto: $e');
      return null;
    }
  }

  /// Crea un producto para administradores; product_form_view.dart lo invoca al enviar el formulario.
  Future<ProductModel?> createProduct(ProductModel product) async {
    if (!_isAdmin) {
      _setError(
          'Acceso denegado: solo un Administrador puede modificar productos.');
      return null;
    }
    _setLoading();
    try {
      // isConnected está definido en network_service.dart.
      if (!await _networkService.isConnected()) {
        throw const ProductException('No hay conexión a Internet.');
      }
      // createProduct está definido en product_service.dart.
      final created = await _service.createProduct(product);
      _setLoaded();
      return created;
    } on ProductException catch (e) {
      _setError(e.message);
      return null;
    } catch (e) {
      _setError('No se pudo crear el producto: $e');
      return null;
    }
  }

  /// Elimina un producto para administradores; product_detail_view.dart lo invoca al confirmar.
  Future<bool> deleteProduct(int id) async {
    if (!_isAdmin) {
      _setError(
          'Acceso denegado: solo un Administrador puede modificar productos.');
      return false;
    }
    _setLoading();
    try {
      // isConnected está definido en network_service.dart.
      if (!await _networkService.isConnected()) {
        throw const ProductException('No hay conexión a Internet.');
      }
      // deleteProduct está definido en product_service.dart.
      await _service.deleteProduct(id);
      _setLoaded();
      return true;
    } on ProductException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('No se pudo eliminar el producto: $e');
      return false;
    }
  }

  /// Quita un producto localmente; home_view.dart lo invoca tras recibir el ID eliminado.
  void removeById(int id) {
    _products = _products.where((product) => product.id != id).toList();
    notifyListeners();
  }

  /// Marca carga activa y notifica; los métodos de consulta y modificación de este archivo lo usan.
  void _setLoading() {
    _status = ProductStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Marca operación exitosa y notifica; los métodos de este archivo lo usan al terminar.
  void _setLoaded() {
    _status = ProductStatus.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  /// Guarda el error y notifica; los métodos de este archivo lo usan al fallar.
  void _setError(String message) {
    _status = ProductStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
