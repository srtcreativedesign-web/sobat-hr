import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor internet connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  final StreamController<bool> _onlineStatusController = StreamController<bool>.broadcast();

  /// Stream of online status changes
  Stream<bool> get onlineStatusStream => _onlineStatusController.stream;
  
  /// Current online status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial status
    await checkConnectivity();

    // Listen for changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      
      _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);

      debugPrint('Connectivity check: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      if (results.isNotEmpty) {
        debugPrint('Connection type: ${results.first.name}');
      }
      
      _onlineStatusController.add(_isOnline);
      return _isOnline;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
      _onlineStatusController.add(_isOnline);
      return false;
    }
  }

  /// Update connection status from stream
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      debugPrint('Connectivity changed: ${wasOnline ? "ONLINE" : "OFFLINE"} -> ${_isOnline ? "ONLINE" : "OFFLINE"}');
      _onlineStatusController.add(_isOnline);
    }
  }

  /// Check if internet is actually reachable (not just connected to WiFi)
  Future<bool> hasInternetAccess() async {
    if (!_isOnline) return false;

    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error checking internet access: $e');
      return false;
    }
  }

  /// Get current connection type
  Future<ConnectivityResult> getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty ? results.first : ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error getting connection type: $e');
      return ConnectivityResult.none;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineStatusController.close();
  }
}
