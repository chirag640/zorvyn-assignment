import 'package:connectivity_plus/connectivity_plus.dart';

/// Check network connectivity status
class NetworkInfo {
  NetworkInfo(this._connectivity);
  
  final Connectivity _connectivity;
  
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
  
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }
}

