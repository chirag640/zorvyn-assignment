import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app.dart';
import 'package:frontend/core/providers/app_providers.dart';
import 'package:frontend/core/storage/local_storage.dart';
import 'package:frontend/features/auth/domain/entities/user_entity.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ReadySupabaseBootstrapNotifier extends SupabaseBootstrapNotifier {
  _ReadySupabaseBootstrapNotifier() : super() {
    state = const SupabaseBootstrapState(
      isChecking: false,
      isReady: true,
    );
  }

  @override
  Future<void> bootstrap() async {
    // no-op for route-state tests
  }
}

class _NoopAuthRepository implements AuthRepository {
  _NoopAuthRepository(this.currentUser);

  final UserEntity? currentUser;

  @override
  Future<UserEntity?> getCurrentUser() async {
    return currentUser;
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> resendSignupVerification(String email) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> isAuthenticated() async {
    return currentUser != null;
  }

  @override
  Future<bool> refreshToken() async {
    return false;
  }
}

class _StubGetCurrentUserUsecase extends GetCurrentUserUsecase {
  _StubGetCurrentUserUsecase(UserEntity? user)
      : _user = user,
        super(_NoopAuthRepository(user));

  final UserEntity? _user;

  @override
  Future<UserEntity?> call() async {
    return _user;
  }
}

Future<LocalStorage> _localStorageWithSettings({
  required bool biometricsEnabled,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.getInstance();
  await storage.clear();
  await storage.setJson(
    'app_settings',
    {
      'themeMode': ThemeMode.system.name,
      'notificationsEnabled': true,
      'biometricsEnabled': biometricsEnabled,
      'language': 'en',
      'currencyCode': 'USD',
      'updatedAt': DateTime.now().toIso8601String(),
    },
  );
  return storage;
}

void main() {
  testWidgets('routes to login when user is not authenticated', (tester) async {
    final localStorage = await _localStorageWithSettings(
      biometricsEnabled: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          supabaseBootstrapProvider
              .overrideWith((ref) => _ReadySupabaseBootstrapNotifier()),
          getCurrentUserUsecaseProvider
              .overrideWithValue(_StubGetCurrentUserUsecase(null)),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('app-ready-/login')),
      findsOneWidget,
    );
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('routes to biometric unlock when authenticated and enabled',
      (tester) async {
    final localStorage = await _localStorageWithSettings(
      biometricsEnabled: true,
    );

    const user = UserEntity(
      id: 'user-1',
      email: 'demo@example.com',
      name: 'Demo User',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          supabaseBootstrapProvider
              .overrideWith((ref) => _ReadySupabaseBootstrapNotifier()),
          getCurrentUserUsecaseProvider
              .overrideWithValue(_StubGetCurrentUserUsecase(user)),
        ],
        child: const App(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey<String>('app-ready-/biometric-unlock')),
      findsOneWidget,
    );
    expect(find.text('Biometric Unlock'), findsOneWidget);
  });
}
