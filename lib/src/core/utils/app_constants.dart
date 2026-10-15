class AppConstants {
  /// Servicio que analiza los enlaces. Se cambia al compilar con
  /// `--dart-define=API_BASE_URL=...` y `--dart-define=API_ENDPOINT=...`
  /// (por ejemplo, un backend propio o un servidor de prueba).
  ///
  /// Por omisión usa el servicio público de tikwm.com, que no pide clave.
  /// Es un servicio de terceros sin garantías: antes de publicar la app
  /// conviene un backend propio.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: "https://www.tikwm.com",
  );
  static const String getVideoEndpoint = String.fromEnvironment(
    'API_ENDPOINT',
    defaultValue: "/api/",
  );
  static const int navigateTime = 2000;
  static const int animationTime = 1000;
}
