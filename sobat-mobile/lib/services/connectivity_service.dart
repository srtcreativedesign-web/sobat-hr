import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor internet connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
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
      final result = await _connectivity.checkConnectivity();
      
      _isOnline = result != ConnectivityResult.none;

      debugPrint('Connectivity check: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      debugPrint('Connection type: ${result.name}');
      
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
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    
    _isOnline = result != ConnectivityResult.none;

    if (wasOnline != _isOnline) {
      debugPrint('Connectivity changed: ${wasOnline ? "ONLINE" : "OFFLINE"} -> ${_isOnline ? "ONLINE" : "OFFLINE"}');
      _onlineStatusController.add(_isOnline);
    }
  }

  /// Check if internet is actually reachable (not just connected to WiFi)
  Future<bool> hasInternetAccess() async {
    if (!_isOnline) return false;

    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking internet access: $e');
      return false;
    }
  }

  /// Get current connection type
  Future<ConnectivityResult> getConnectionType() async {
    try {
      return await _connectivity.checkConnectivity();
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
