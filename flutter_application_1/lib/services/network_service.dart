import 'package:connectivity_plus/connectivity_plus.dart';

/// Interfaz para abstracción (POO)
abstract class INetworkService {
  /// Contrato de comprobación de conectividad implementado por NetworkService aquí.
  Future<bool> isConnected();
}

/// Implementación del servicio de red (Compatible con connectivity_plus 5.x y 6.x)
class NetworkService implements INetworkService {
  /// Comprueba conectividad del dispositivo; product_controller.dart y login_view.dart lo usan.
  @override
  Future<bool> isConnected() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}
