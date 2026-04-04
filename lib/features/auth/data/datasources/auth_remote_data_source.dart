import 'dart:convert';

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
  Future<void> logout({bool allSessions = false});
}

/// Supabase-backed implementation of authentication remote data source.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required SupabaseClient? supabaseClient,
  }) : _supabaseClient = supabaseClient;

  final SupabaseClient? _supabaseClient;
  static const String _settingsTable = 'user_settings';
  static const String _sessionRevokedAtColumn = 'session_revoked_at';

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
    AppLogger.lifecycle(
      'auth.login.start',
      tag: 'AuthLifecycle',
      data: {
        'emailDomain': _emailDomain(email),
      },
      level: 'debug',
    );

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

      AppLogger.lifecycle(
        'auth.login.success',
        tag: 'AuthLifecycle',
        data: {
          'userId': user.id,
          'hasRefreshToken': (session.refreshToken ?? '').trim().isNotEmpty,
        },
        level: 'success',
      );

      return AuthResponseModel(
        user: _mapSupabaseUser(user),
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    } catch (e, stackTrace) {
      AppLogger.lifecycle(
        'auth.login.failure',
        tag: 'AuthLifecycle',
        data: {
          'errorType': e.runtimeType.toString(),
          'emailDomain': _emailDomain(email),
        },
        level: 'warning',
      );
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
    AppLogger.lifecycle(
      'auth.register.start',
      tag: 'AuthLifecycle',
      data: {
        'emailDomain': _emailDomain(email),
        'hasDisplayName': name.trim().isNotEmpty,
      },
      level: 'debug',
    );

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
        AppLogger.lifecycle(
          'auth.register.awaiting_verification',
          tag: 'AuthLifecycle',
          data: {
            'emailDomain': _emailDomain(email),
          },
          level: 'info',
        );
        AppLogger.info(
          'Registration succeeded and requires email verification.',
          'AuthRemoteDataSource',
        );

        throw AuthEmailVerificationRequiredException(email: email);
      }

      AppLogger.lifecycle(
        'auth.register.success',
        tag: 'AuthLifecycle',
        data: {
          'userId': user.id,
        },
        level: 'success',
      );

      return AuthResponseModel(
        user: _mapSupabaseUser(user),
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    } on AuthEmailVerificationRequiredException {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.lifecycle(
        'auth.register.failure',
        tag: 'AuthLifecycle',
        data: {
          'errorType': e.runtimeType.toString(),
          'emailDomain': _emailDomain(email),
        },
        level: 'warning',
      );
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
    final session = supabase.auth.currentSession;
    if (session == null) {
      AppLogger.lifecycle(
        'auth.session.current_user_missing',
        tag: 'AuthLifecycle',
        level: 'warning',
      );
      throw Exception('No authenticated user session found.');
    }

    final userResponse = await supabase.auth.getUser();
    final user = userResponse.user;
    if (user == null) {
      AppLogger.lifecycle(
        'auth.session.get_user_missing',
        tag: 'AuthLifecycle',
        level: 'warning',
      );
      throw Exception('No authenticated user session found.');
    }

    await _throwIfSessionRevoked(
      supabase: supabase,
      userId: user.id,
      accessToken: session.accessToken,
    );

    AppLogger.lifecycle(
      'auth.session.current_user_loaded',
      tag: 'AuthLifecycle',
      data: {
        'userId': user.id,
      },
      level: 'debug',
    );
    return _mapSupabaseUser(user);
  }

  @override
  Future<bool> refreshToken(String refreshToken) async {
    AppLogger.lifecycle(
      'auth.refresh.start',
      tag: 'AuthLifecycle',
      data: {
        'hasRefreshToken': refreshToken.trim().isNotEmpty,
      },
      level: 'debug',
    );

    final supabase = await _requireSupabaseClient();

    if (refreshToken.trim().isEmpty) {
      AppLogger.lifecycle(
        'auth.refresh.skipped_missing_token',
        tag: 'AuthLifecycle',
        level: 'warning',
      );
      return false;
    }

    try {
      await supabase.auth.refreshSession();
      final refreshed = supabase.auth.currentSession != null;
      AppLogger.lifecycle(
        refreshed ? 'auth.refresh.success' : 'auth.refresh.no_session',
        tag: 'AuthLifecycle',
        level: refreshed ? 'success' : 'warning',
      );
      return refreshed;
    } catch (e, stackTrace) {
      AppLogger.lifecycle(
        'auth.refresh.failure',
        tag: 'AuthLifecycle',
        data: {
          'errorType': e.runtimeType.toString(),
        },
        level: 'warning',
      );
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

    AppLogger.lifecycle(
      'auth.verification_resend.start',
      tag: 'AuthLifecycle',
      data: {
        'emailDomain': _emailDomain(normalizedEmail),
      },
      level: 'debug',
    );

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
      AppLogger.lifecycle(
        'auth.verification_resend.success',
        tag: 'AuthLifecycle',
        data: {
          'emailDomain': _emailDomain(normalizedEmail),
        },
        level: 'success',
      );
    } catch (e, stackTrace) {
      AppLogger.lifecycle(
        'auth.verification_resend.failure',
        tag: 'AuthLifecycle',
        data: {
          'errorType': e.runtimeType.toString(),
          'emailDomain': _emailDomain(normalizedEmail),
        },
        level: 'warning',
      );
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
  Future<void> logout({bool allSessions = false}) async {
    AppLogger.lifecycle(
      'auth.logout.start',
      tag: 'AuthLifecycle',
      data: {
        'scope': allSessions ? 'global' : 'local',
      },
      level: 'debug',
    );

    final supabase = await _requireSupabaseClient();

    try {
      if (allSessions) {
        try {
          await _markSessionRevokedAt(supabase);
        } catch (error, stackTrace) {
          AppLogger.warning(
            'Failed to mark session revocation timestamp before global logout.',
            'AuthRemoteDataSource',
          );
          AppLogger.error(
            'Session revocation mark failure',
            error,
            stackTrace,
            'AuthRemoteDataSource',
          );
        }
      }

      await supabase.auth.signOut(
        scope: allSessions ? SignOutScope.global : SignOutScope.local,
      );
      AppLogger.lifecycle(
        'auth.logout.success',
        tag: 'AuthLifecycle',
        level: 'success',
      );
    } catch (e, stackTrace) {
      AppLogger.lifecycle(
        'auth.logout.failure',
        tag: 'AuthLifecycle',
        data: {
          'errorType': e.runtimeType.toString(),
        },
        level: 'warning',
      );
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

  String _emailDomain(String email) {
    final trimmed = email.trim();
    final at = trimmed.lastIndexOf('@');
    if (at <= 0 || at == trimmed.length - 1) {
      return 'unknown';
    }
    return trimmed.substring(at + 1).toLowerCase();
  }

  Future<void> _markSessionRevokedAt(SupabaseClient supabase) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || userId.trim().isEmpty) {
      return;
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    await supabase.from(_settingsTable).upsert(
      {
        'user_id': userId,
        _sessionRevokedAtColumn: nowIso,
        'updated_at': nowIso,
      },
      onConflict: 'user_id',
    );
  }

  Future<void> _throwIfSessionRevoked({
    required SupabaseClient supabase,
    required String userId,
    required String? accessToken,
  }) async {
    final issuedAt = _jwtIssuedAt(accessToken);
    if (issuedAt == null) {
      return;
    }

    Map<String, dynamic>? row;
    try {
      row = await supabase
          .from(_settingsTable)
          .select(_sessionRevokedAtColumn)
          .eq('user_id', userId)
          .maybeSingle();
    } catch (error, stackTrace) {
      if (_isMissingRevocationColumnError(error)) {
        AppLogger.warning(
          'session_revoked_at column missing; skipping revocation check.',
          'AuthRemoteDataSource',
        );
        return;
      }

      AppLogger.error(
        'Failed to read session revocation timestamp',
        error,
        stackTrace,
        'AuthRemoteDataSource',
      );
      rethrow;
    }

    final revokedRaw = row?[_sessionRevokedAtColumn] as String?;
    final revokedAt = DateTime.tryParse(revokedRaw ?? '')?.toUtc();
    if (revokedAt == null) {
      return;
    }

    if (!issuedAt.isAfter(revokedAt)) {
      await supabase.auth.signOut(scope: SignOutScope.local);
      throw Exception(
        'Session revoked by security policy. Please login again.',
      );
    }
  }

  bool _isMissingRevocationColumnError(Object error) {
    final normalized = error.toString().toLowerCase();
    return normalized.contains('column') &&
        normalized.contains(_sessionRevokedAtColumn.toLowerCase()) &&
        (normalized.contains('does not exist') ||
            normalized.contains('schema cache') ||
            normalized.contains('could not find'));
  }

  DateTime? _jwtIssuedAt(String? accessToken) {
    final token = accessToken?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return null;
      }

      final normalizedPayload = base64.normalize(
        parts[1].replaceAll('-', '+').replaceAll('_', '/'),
      );
      final payloadMap = jsonDecode(
        utf8.decode(base64Decode(normalizedPayload)),
      ) as Map<String, dynamic>;
      final iatSeconds = (payloadMap['iat'] as num?)?.toInt();
      if (iatSeconds == null || iatSeconds <= 0) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(
        iatSeconds * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }
}
