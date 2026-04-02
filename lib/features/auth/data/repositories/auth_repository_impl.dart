import '../../domain/entities/user_entity.dart';
import '../../domain/exceptions/auth_email_verification_required_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../../../core/utils/logger.dart';

/// Implementation of authentication repository
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      // Login via API
      final authResponse = await remoteDataSource.login(email, password);

      // Save tokens and user data locally
      await localDataSource.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );
      await localDataSource.saveUser(authResponse.user);

      AppLogger.success('Login successful', 'AuthRepository');
      return authResponse.user;
    } catch (e) {
      AppLogger.error('Login failed in repository', e, null, 'AuthRepository');
      rethrow;
    }
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Register via API
      final authResponse =
          await remoteDataSource.register(email, password, name);

      // Save tokens and user data locally
      await localDataSource.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );
      await localDataSource.saveUser(authResponse.user);

      AppLogger.success('Registration successful', 'AuthRepository');
      return authResponse.user;
    } on AuthEmailVerificationRequiredException {
      AppLogger.info(
        'Registration pending email verification',
        'AuthRepository',
      );
      rethrow;
    } catch (e) {
      AppLogger.error(
          'Registration failed in repository', e, null, 'AuthRepository');
      rethrow;
    }
  }

  @override
  Future<void> resendSignupVerification(String email) async {
    try {
      await remoteDataSource.resendSignupVerification(email);
      AppLogger.success(
        'Verification email resend requested',
        'AuthRepository',
      );
    } catch (e) {
      AppLogger.error(
        'Verification email resend failed',
        e,
        null,
        'AuthRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();

      // Clear local data
      await localDataSource.clearTokens();
      await localDataSource.clearUser();

      AppLogger.success('Logout successful', 'AuthRepository');
    } catch (e) {
      AppLogger.error('Logout failed', e, null, 'AuthRepository');
      rethrow;
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final cachedUser = await localDataSource.getCachedUser();
    final accessToken = await localDataSource.getAccessToken();

    if ((accessToken == null || accessToken.isEmpty) && cachedUser == null) {
      return null;
    }

    try {
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.saveUser(user);
      return user;
    } catch (e) {
      AppLogger.error('Failed to get current user', e, null, 'AuthRepository');

      if (accessToken != null && accessToken.isNotEmpty && cachedUser != null) {
        return cachedUser;
      }

      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }

  @override
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final success = await remoteDataSource.refreshToken(refreshToken);
      return success;
    } catch (e) {
      AppLogger.error('Token refresh failed', e, null, 'AuthRepository');
      return false;
    }
  }
}
