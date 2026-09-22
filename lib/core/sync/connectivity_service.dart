import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class IConnectivityService {
  Future<bool> get isOnline;
  Stream<bool> get onConnectivityChanged;
}

final connectivityServiceProvider = Provider<IConnectivityService>((ref) {
  return ConnectivityService();
});

final isOnlineStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

class ConnectivityService implements IConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  bool _isResultOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  @override
  Future<bool> get isOnline async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isResultOnline(results);
    } catch (_) {
      return true; // Default fallback to optimistic online
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_isResultOnline).distinct();
  }
}
