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
  /// Instancia de Cobalt que respalda a Instagram cuando su página de
  /// inserción no entrega el video. Vacía por omisión: no hay ninguna pública
  /// de confianza. Se activa con `--dart-define=COBALT_URL=https://…` y,
  /// si la instancia pide clave, `--dart-define=COBALT_KEY=…`.
  static const String cobaltUrl = String.fromEnvironment('COBALT_URL');
  static const String cobaltKey = String.fromEnvironment('COBALT_KEY');
  static const int navigateTime = 2000;
  static const int animationTime = 1000;
}
