import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  NetworkService([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();
  final Connectivity _connectivity;

  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged.map(
        (items) => items.any((item) => item != ConnectivityResult.none),
      );

  Future<bool> get isOnline async {
    final items = await _connectivity.checkConnectivity();
    return items.any((item) => item != ConnectivityResult.none);
  }
}
