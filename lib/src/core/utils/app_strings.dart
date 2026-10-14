class AppStrings {
  static const String appName = "SaveTic";
  static const String videoLink = "Enlace del video";
  static const String inputLinkFieldText = "tiktok.com/@autor/video/…";
  static const String download = "Descargar";
  static const String downloading = "Descargando";
  static const String downloads = "Descargas";
  static const String videoLinkRequired = "El enlace del video es requerido";
  static const String downloadSuccess = "Descarga exitosa";
  static const String play = "Reproducir";
  static const String retryDownload = "Reintentar descarga";
  static const String downloadFall = "Error en la descarga";
  static const String permissionsRequired =
      "Se requieren permisos, por favor acepte los permisos e intente nuevamente";
  static const String oldDownloads = "Descargas antiguas";

  // Inicio
  static const String homeTitle = "Pega el enlace del video";
  static const String clipboardFound = "Tienes un enlace copiado";
  static const String useThisLink = "Usar este enlace";
  static const String paste = "Pegar";
  static const String clearField = "Borrar el enlace";
  static const String searchVideo = "Buscar video";
  static const String searching = "Buscando el video…";
  static const String recents = "Recientes";
  static const String seeAll = "Ver todas";
  static const String validLinksLook = "Un enlace que sí funciona se ve así:";
  static const String openDownloads = "Tus descargas";
  static const String linkNotAVideo =
      "Ese enlace es de TikTok, pero no es de un video.";
  static const String linkNotTikTok = "Ese enlace no es de un video de TikTok.";
  static const String videoUnavailable =
      "No pudimos obtener el video. Puede ser privado o haber sido borrado.";
  static String linkOtherPlatform(String platform) =>
      "Ese enlace es de $platform, no de TikTok.";
  static String downloadsInProgress(int n) =>
      n == 1 ? "Tus descargas, 1 en curso" : "Tus descargas, $n en curso";
}
