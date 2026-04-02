import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/exceptions/auth_email_verification_required_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/resend_signup_verification_usecase.dart';

// ========== DATA SOURCES ==========

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);

  return AuthRemoteDataSourceImpl(
    supabaseClient: supabaseClient,
  );
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(
    localStorage: ref.watch(localStorageProvider),
    secureStorage: SecureStorage.instance,
  );
});

// ========== REPOSITORY ==========

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
});

// ========== USE CASES ==========

final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  return LoginUsecase(ref.watch(authRepositoryProvider));
});

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  return RegisterUsecase(ref.watch(authRepositoryProvider));
});

final resendSignupVerificationUsecaseProvider =
    Provider<ResendSignupVerificationUsecase>((ref) {
  return ResendSignupVerificationUsecase(ref.watch(authRepositoryProvider));
});

final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  return LogoutUsecase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUsecaseProvider = Provider<GetCurrentUserUsecase>((ref) {
  return GetCurrentUserUsecase(ref.watch(authRepositoryProvider));
});

// ========== AUTH STATE ==========

/// Authentication state
class AuthState {
  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isInitializing = false,
    this.isSubmitting = false,
    this.isAwaitingEmailVerification = false,
    this.verificationEmail,
    this.verificationPassword,
    this.infoMessage,
    this.error,
  });

  final UserEntity? user;
  final bool isAuthenticated;
  final bool isInitializing;
  final bool isSubmitting;
  final bool isAwaitingEmailVerification;
  final String? verificationEmail;
  final String? verificationPassword;
  final String? infoMessage;
  final String? error;

  bool get isLoading => isInitializing || isSubmitting;

  AuthState copyWith({
    UserEntity? user,
    bool? isAuthenticated,
    bool? isInitializing,
    bool? isSubmitting,
    bool? isAwaitingEmailVerification,
    String? verificationEmail,
    bool clearVerificationEmail = false,
    String? verificationPassword,
    bool clearVerificationPassword = false,
    String? infoMessage,
    bool clearInfoMessage = false,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitializing: isInitializing ?? this.isInitializing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isAwaitingEmailVerification:
          isAwaitingEmailVerification ?? this.isAwaitingEmailVerification,
      verificationEmail: clearVerificationEmail
          ? null
          : (verificationEmail ?? this.verificationEmail),
      verificationPassword: clearVerificationPassword
          ? null
          : (verificationPassword ?? this.verificationPassword),
      infoMessage: clearInfoMessage ? null : (infoMessage ?? this.infoMessage),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ========== AUTH NOTIFIER ==========

/// Authentication state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState(isInitializing: true)) {
    _checkAuthStatus();
  }

  final Ref _ref;

  /// Check if user is authenticated on app start
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(
      isInitializing: true,
      clearError: true,
      clearInfoMessage: true,
      isAwaitingEmailVerification: false,
      clearVerificationEmail: true,
      clearVerificationPassword: true,
    );

    try {
      final usecase = _ref.read(getCurrentUserUsecaseProvider);
      final user = await usecase();

      if (user != null) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isInitializing: false,
          isAwaitingEmailVerification: false,
          clearVerificationEmail: true,
          clearVerificationPassword: true,
          clearError: true,
          clearInfoMessage: true,
        );
      } else {
        state = state.copyWith(
          isInitializing: false,
          isAwaitingEmailVerification: false,
          clearVerificationEmail: true,
          clearVerificationPassword: true,
          clearInfoMessage: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: _toUserMessage(e),
        clearInfoMessage: true,
      );
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearInfoMessage: true,
      isAwaitingEmailVerification: false,
      clearVerificationEmail: true,
      clearVerificationPassword: true,
    );

    try {
      final usecase = _ref.read(loginUsecaseProvider);
      final user = await usecase(email: email, password: password);

      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isSubmitting: false,
        isAwaitingEmailVerification: false,
        clearVerificationEmail: true,
        clearVerificationPassword: true,
        clearError: true,
        clearInfoMessage: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _toUserMessage(e),
        clearInfoMessage: true,
      );
      return false;
    }
  }

  /// Register new user
  Future<bool> register(String email, String password, String name) async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearInfoMessage: true,
      isAwaitingEmailVerification: false,
      clearVerificationEmail: true,
      clearVerificationPassword: true,
    );

    try {
      final usecase = _ref.read(registerUsecaseProvider);
      final user = await usecase(
        email: email,
        password: password,
        name: name,
      );

      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isSubmitting: false,
        isAwaitingEmailVerification: false,
        clearVerificationEmail: true,
        clearVerificationPassword: true,
        clearError: true,
        clearInfoMessage: true,
      );

      return true;
    } on AuthEmailVerificationRequiredException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        isAuthenticated: false,
        isAwaitingEmailVerification: true,
        verificationEmail: e.email,
        verificationPassword: password,
        infoMessage: 'Account created. Please verify your email, then sign in.',
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _toUserMessage(e),
        isAwaitingEmailVerification: false,
        clearVerificationEmail: true,
        clearVerificationPassword: true,
        clearInfoMessage: true,
      );
      return false;
    }
  }

  Future<bool> continueAfterEmailVerification() async {
    if (state.isSubmitting) {
      return false;
    }

    final email = (state.verificationEmail ?? '').trim();
    final password = (state.verificationPassword ?? '').trim();
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        error:
            'Verification session expired. Please login manually with your credentials.',
        clearInfoMessage: true,
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      isAwaitingEmailVerification: true,
      clearError: true,
      clearInfoMessage: true,
      verificationEmail: email,
      verificationPassword: password,
    );

    try {
      final usecase = _ref.read(loginUsecaseProvider);
      final user = await usecase(email: email, password: password);

      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isSubmitting: false,
        isAwaitingEmailVerification: false,
        clearVerificationEmail: true,
        clearVerificationPassword: true,
        clearError: true,
        clearInfoMessage: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        isAuthenticated: false,
        isAwaitingEmailVerification: true,
        verificationEmail: email,
        verificationPassword: password,
        error: _toUserMessage(e),
        clearInfoMessage: true,
      );
      return false;
    }
  }

  Future<bool> resendSignupVerification([String? email]) async {
    final targetEmail = (email ?? state.verificationEmail ?? '').trim();
    if (targetEmail.isEmpty) {
      state = state.copyWith(
        error: 'Enter a valid email to resend verification.',
        clearInfoMessage: true,
      );
      return false;
    }

    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearInfoMessage: true,
      isAwaitingEmailVerification: true,
      verificationEmail: targetEmail,
    );

    try {
      final usecase = _ref.read(resendSignupVerificationUsecaseProvider);
      await usecase(targetEmail);

      state = state.copyWith(
        isSubmitting: false,
        isAwaitingEmailVerification: true,
        verificationEmail: targetEmail,
        infoMessage:
            'Verification email sent. Please check inbox and spam folder.',
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        isAwaitingEmailVerification: true,
        verificationEmail: targetEmail,
        error: _toUserMessage(e),
        clearInfoMessage: true,
      );
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    if (state.isSubmitting) {
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearInfoMessage: true,
      clearVerificationEmail: true,
      clearVerificationPassword: true,
    );

    try {
      final usecase = _ref.read(logoutUsecaseProvider);
      await usecase();

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _toUserMessage(e),
        clearInfoMessage: true,
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearInfo() {
    state = state.copyWith(clearInfoMessage: true);
  }

  String _toUserMessage(Object error) {
    final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    final lower = raw.toLowerCase();

    if (lower.contains('supabase client is unavailable') ||
        lower.contains('supabase not configured') ||
        lower.contains('unable to load asset') ||
        lower.contains('supabase_url') ||
        lower.contains('supabase_anon_key')) {
      return 'Supabase is not initialized. Ensure .env contains SUPABASE_URL '
          'and SUPABASE_ANON_KEY, add .env under flutter assets in pubspec.yaml, '
          'then fully restart the app.';
    }

    if (lower.contains('connection error') ||
        lower.contains('socketexception')) {
      return 'Unable to connect to Supabase right now. Please try again.';
    }

    if (lower.contains('email not confirmed') ||
        lower.contains('email not verified')) {
      return 'Email is not verified yet. Verify your email first, then login.';
    }

    if (lower.contains('too many requests') || lower.contains('rate limit')) {
      return 'Too many attempts right now. Please wait and try again.';
    }

    return raw;
  }
}

/// Provider for authentication state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
