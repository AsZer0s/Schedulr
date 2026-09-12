enum AppEnvironment { development, production }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.enableDemoImporter,
  });

  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );

    return AppConfig(
      environment: environmentName == 'production'
          ? AppEnvironment.production
          : AppEnvironment.development,
      enableDemoImporter: const bool.fromEnvironment(
        'ENABLE_DEMO_IMPORTER',
        defaultValue: true,
      ),
    );
  }

  final AppEnvironment environment;
  final bool enableDemoImporter;
}
