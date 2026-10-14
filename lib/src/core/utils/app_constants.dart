class AppConstants {
  /// Servicio que analiza los enlaces. Se puede cambiar al compilar con
  /// `--dart-define=API_BASE_URL=...` (un backend propio o un servidor de prueba).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: "https://tiktok-download-without-watermark.p.rapidapi.com",
  );
  static const String getVideoEndpoint = "/analysis";
  static const int navigateTime = 2000;
  static const int animationTime = 1000;
}
