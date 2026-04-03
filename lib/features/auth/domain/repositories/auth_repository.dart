import '../entities/user_entity.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Login with email and password
  Future<UserEntity> login({
    required String email,
    required String password,
  });

  /// Register a new user
  Future<UserEntity> register({
    required String email,
    required String password,
    required String name,
  });

  /// Resend signup verification email.
  Future<void> resendSignupVerification(String email);

  /// Logout the current user
  Future<void> logout({bool allSessions = false});

  /// Get the currently logged in user
  Future<UserEntity?> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Refresh authentication token
  Future<bool> refreshToken();
}
