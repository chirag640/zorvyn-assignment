import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAvailability {
  const BiometricAvailability({
    required this.isAvailable,
    this.message,
    this.availableTypes = const <BiometricType>[],
  });

  final bool isAvailable;
  final String? message;
  final List<BiometricType> availableTypes;
}

class BiometricAuthResult {
  const BiometricAuthResult({
    required this.isAuthenticated,
    this.message,
  });

  final bool isAuthenticated;
  final String? message;
}

class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<BiometricAvailability> checkAvailability() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        return const BiometricAvailability(
          isAvailable: false,
          message: 'Biometric authentication is not supported on this device.',
        );
      }

      final availableTypes = await _auth.getAvailableBiometrics();
      if (availableTypes.isEmpty) {
        return const BiometricAvailability(
          isAvailable: false,
          message: 'No biometrics are enrolled on this device yet.',
        );
      }

      return BiometricAvailability(
        isAvailable: true,
        availableTypes: availableTypes,
      );
    } on PlatformException catch (error) {
      return BiometricAvailability(
        isAvailable: false,
        message:
            'Unable to access biometrics right now (${error.code}). Please try again.',
      );
    } catch (_) {
      return const BiometricAvailability(
        isAvailable: false,
        message: 'Unable to access biometrics right now. Please try again.',
      );
    }
  }

  Future<BiometricAuthResult> authenticate({
    String reason = 'Authenticate to continue',
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: false,
          useErrorDialogs: true,
        ),
      );

      if (!authenticated) {
        return const BiometricAuthResult(
          isAuthenticated: false,
          message: 'Authentication was cancelled or failed.',
        );
      }

      return const BiometricAuthResult(isAuthenticated: true);
    } on PlatformException catch (error) {
      return BiometricAuthResult(
        isAuthenticated: false,
        message:
            'Biometric authentication failed (${error.code}). Please try again.',
      );
    } catch (_) {
      return const BiometricAuthResult(
        isAuthenticated: false,
        message: 'Biometric authentication failed. Please try again.',
      );
    }
  }
}
