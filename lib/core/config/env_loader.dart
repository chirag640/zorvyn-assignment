import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { dev, stage, prod }

class EnvLoader {
  static AppEnvironment currentEnvironment = AppEnvironment.dev;

  static Future<void> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName, mergeWith: {});
    final envName = dotenv.maybeGet('APP_ENV') ?? 'dev';
    currentEnvironment = AppEnvironment.values.firstWhere(
      (element) => element.name == envName,
      orElse: () => AppEnvironment.dev,
    );
  }

  static String get apiBaseUrl =>
      dotenv.maybeGet('API_BASE_URL') ?? 'https://api.example.com';
}

