import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env_loader.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/exceptions/auth_email_verification_required_exception.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Remote data source for authentication.
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> register(
      String email, String password, String name);
  Future<UserModel> getCurrentUser();
  Future<bool> refreshToken(String refreshToken);
  Future<void> resendSignupVerification(String email);
  Future<void> logout();
}

/// Supabase-backed implementation of authentication remote data source.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required SupabaseClient? supabaseClient,
  }) : _supabaseClient = supabaseClient;

  final SupabaseClient? _supabaseClient;

  Future<SupabaseClient> _requireSupabaseClient() async {
    final client = _supabaseClient ?? SupabaseService.client;
    if (client != null) {
      return client;
    }

    // Recover from stale null-client snapshots by reloading env and retrying init.
    await EnvLoader.load();
    await SupabaseService.initialize();

    final recovered = SupabaseService.client;
    if (recovered != null) {
      return recovered;
    }

    final hasUrl = EnvLoader.supabaseUrl.trim().isNotEmpty;
    final hasAnonKey = EnvLoader.supabaseAnonKey.trim().isNotEmpty;

    throw Exception(
      'Supabase client is unavailable. SUPABASE_URL set: $hasUrl, '
      'SUPABASE_ANON_KEY set: $hasAnonKey. Ensure .env is bundled in flutter '
      'assets and restart app after pubspec changes.',
    );
  }

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    final supabase = await _requireSupabaseClient();

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      final user = response.user;
      if (session == null || user == null) {
        throw Exception('Unable to sign in with provided credentials.');
      }

      return AuthResponseModel(
        user: _mapSupabaseUser(user),
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Supabase login failed',
        e,
        stackTrace,
        'AuthRemoteDataSource',
      );
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> register(
    String email,
    String password,
    String name,
  ) async {
    final supabase = await _requireSupabaseClient();

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      final session = response.session;
      if (session == null) {
        AppLogger.info(
          'Registration succeeded and requires email verification.',
          'AuthRemoteDataSource',
        );

        throw AuthEmailVerificationRequiredException(email: email);
      }

      return AuthResponseModel(
        user: _mapSupabaseUser(user),
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    } on AuthEmailVerificationRequiredException {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Supabase registration failed',
        e,
        stackTrace,
        'AuthRemoteDataSource',
      );
      rethrow;
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final supabase = await _requireSupabaseClient();
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user session found.');
    }
    return _mapSupabaseUser(user);
  }

  @override
  Future<bool> refreshToken(String refreshToken) async {
    final supabase = await _requireSupabaseClient();

    if (refreshToken.trim().isEmpty) {
      return false;
    }

    try {
      await supabase.auth.refreshSession();
      return supabase.auth.currentSession != null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Supabase token refresh failed',
        e,
        stackTrace,
        'AuthRemoteDataSource',
      );
      return false;
    }
  }

  @override
  Future<void> resendSignupVerification(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw Exception('Email is required to resend verification.');
    }

    final supabase = await _requireSupabaseClient();

    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: normalizedEmail,
      );
      AppLogger.info(
        'Verification email resend requested.',
        'AuthRemoteDataSource',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Resend verification failed',
        e,
        stackTrace,
        'AuthRemoteDataSource',
      );
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    final supabase = await _requireSupabaseClient();

    try {
      await supabase.auth.signOut();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Supabase logout failed',
        e,
        stackTrace,
        'AuthRemoteDataSource',
      );
      rethrow;
    }
  }

  UserModel _mapSupabaseUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final name = (metadata['name'] as String?)?.trim();
    final avatar = (metadata['avatar'] as String?)?.trim();

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: name?.isEmpty ?? true ? null : name,
      avatar: avatar?.isEmpty ?? true ? null : avatar,
    );
  }
}
