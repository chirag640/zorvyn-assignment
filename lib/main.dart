import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config/env_loader.dart';
import 'core/database/hive_database.dart';
import 'core/storage/local_storage.dart';
import 'core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  await HiveDatabase.instance.init();
  final localStorage = await LocalStorage.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
      ],
      child: const App(),
    ),
  );
}

