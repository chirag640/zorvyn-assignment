import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';
import 'dart:convert';

/// Local data source for authentication (caching tokens and user data)
abstract class AuthLocalDataSource {
  Future<void> saveTokens(String accessToken, String? refreshToken);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();
}

/// Implementation of authentication local data source
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({
    required this.localStorage,
    required this.secureStorage,
  });

  final LocalStorage localStorage;
  final SecureStorage secureStorage;

  @override
  Future<void> saveTokens(String accessToken, String? refreshToken) async {
    await secureStorage.write(AppConstants.keyAccessToken, accessToken);
    if (refreshToken != null) {
      await secureStorage.write(AppConstants.keyRefreshToken, refreshToken);
    }
    AppLogger.debug('Tokens saved', 'AuthLocalDataSource');
  }

  @override
  Future<String?> getAccessToken() async {
    return await secureStorage.read(AppConstants.keyAccessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(AppConstants.keyRefreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await secureStorage.delete(AppConstants.keyAccessToken);
    await secureStorage.delete(AppConstants.keyRefreshToken);
    AppLogger.debug('Tokens cleared', 'AuthLocalDataSource');
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await localStorage.setString('cached_user', jsonEncode(user.toJson()));
    AppLogger.debug('User cached locally', 'AuthLocalDataSource');
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final userJson = localStorage.getString('cached_user');
    if (userJson == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Failed to parse cached user', e, null, 'AuthLocalDataSource');
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    await localStorage.remove('cached_user');
    AppLogger.debug('Cached user cleared', 'AuthLocalDataSource');
  }
}

