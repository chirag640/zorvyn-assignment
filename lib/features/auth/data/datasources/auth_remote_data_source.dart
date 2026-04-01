import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/logger.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Remote data source for authentication
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> register(String email, String password, String name);
  Future<UserModel> getCurrentUser();
  Future<bool> refreshToken(String refreshToken);
}

/// Implementation of authentication remote data source
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Login failed', e, e.stackTrace, 'AuthRemoteDataSource');
      throw Exception('Login failed: ${e.message}');
    }
  }

  @override
  Future<AuthResponseModel> register(String email, String password, String name) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Registration failed', e, e.stackTrace, 'AuthRemoteDataSource');
      throw Exception('Registration failed: ${e.message}');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.profile);

      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get user failed', e, e.stackTrace, 'AuthRemoteDataSource');
      throw Exception('Failed to get user: ${e.message}');
    }
  }

  @override
  Future<bool> refreshToken(String refreshToken) async {
    try {
      await _apiClient.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      return true;
    } on DioException catch (e) {
      AppLogger.error('Token refresh failed', e, e.stackTrace, 'AuthRemoteDataSource');
      return false;
    }
  }
}

