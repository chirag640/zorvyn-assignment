import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'app_responsive.dart';
import '../utils/logger.dart';

/// Network settings and connectivity management
class NetworkSettings {
  NetworkSettings._();

  static final Connectivity _connectivity = Connectivity();

  static Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      AppLogger.error(
        'Error checking connectivity',
        e,
        null,
        'NetworkSettings',
      );
      return false;
    }
  }

  static Future<ConnectivityResult> getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.first;
    } catch (e) {
      AppLogger.error(
        'Error getting connection type',
        e,
        null,
        'NetworkSettings',
      );
      return ConnectivityResult.none;
    }
  }

  static Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  static String getConnectionTypeString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.satellite:
        return 'Satellite';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
    }
  }

  static void showNetworkError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.rRadius(16)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.wifi_off,
              color: Colors.red,
              size: context.rIcon(22),
            ),
            SizedBox(width: context.rs(12)),
            Text(
              'No Internet Connection',
              style: TextStyle(fontSize: context.rFont(18)),
            ),
          ],
        ),
        content: Text(
          'Please check your internet connection and try again.',
          style: TextStyle(fontSize: context.rFont(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<T?> executeWithNetworkCheck<T>(
    BuildContext context,
    Future<T> Function() function, {
    bool showError = true,
  }) async {
    if (!await isConnected()) {
      if (showError && context.mounted) showNetworkError(context);
      return null;
    }
    return await function();
  }
}
