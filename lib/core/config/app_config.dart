import 'env_loader.dart';

class AppConfig {
  const AppConfig({
    required this.appTitle,
    required this.environment,
    required this.apiBaseUrl,
  });

  final String appTitle;
  final String environment;
  final String apiBaseUrl;

  static AppConfig load() {
    return AppConfig(
      appTitle: 'Frontend',
      environment: EnvLoader.currentEnvironment.name,
      apiBaseUrl: EnvLoader.apiBaseUrl,
    );
  }
}

