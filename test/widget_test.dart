import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zorvyn_finance/app/app.dart';
import 'package:zorvyn_finance/core/providers/app_providers.dart';
import 'package:zorvyn_finance/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestSupabaseBootstrapNotifier extends SupabaseBootstrapNotifier {
  _TestSupabaseBootstrapNotifier() : super() {
    state = const SupabaseBootstrapState(
      isChecking: false,
      isReady: true,
    );
  }

  @override
  Future<void> bootstrap() async {
    // Intentionally no-op in widget tests.
  }
}

void main() {
  testWidgets('App renders without issues', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localStorage = await LocalStorage.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          supabaseBootstrapProvider
              .overrideWith((ref) => _TestSupabaseBootstrapNotifier()),
        ],
        child: const App(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
