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

  // Vista previa
  static const String previewSheetLabel = "Vista previa del video";
  static const String formatLabel = "Formato";
  static const String formatWithCredits = "Video con créditos";
  static const String formatNoWatermark = "Video sin marca de agua";
  static const String formatAudio = "Solo el audio";
  static const String formatNoWatermarkHint = "Para verlo tú, sin conexión";
  static const String formatAudioHint = "Archivo de música";
  static const String formatWithCreditsNoAuthor = "Incluye el nombre del autor";
  static const String downloadVideo = "Descargar video";
  static const String downloadAudio = "Descargar audio";
  static const String durationLabel = "de duración";
  static const String playsLabel = "reproducciones";
  static const String downloadsLabel = "descargas";
  static const String coverLabel = "Portada del video";
  static const String untitledVideo = "Video sin título";
  static String formatWithCreditsHint(String handle) =>
      "Muestra @$handle al compartir";
  static String creditNote(String handle) =>
      "Si lo compartes, menciona a @$handle.";

  // Descargas
  static const String inProgress = "En curso";
  static const String today = "Hoy";
  static const String savedBefore = "Guardados antes";
  static const String cancelDownload = "Cancelar descarga";
  static const String viewVideo = "Ver video";
  static const String retry = "Reintentar";
  static const String savedInGallery = "En tu galería";
  static const String savedInApp = "Guardado en la app";
  static const String downloadingNow = "Descargando…";
  static const String downloadCancelled = "Descarga cancelada";
  static const String emptyDownloadsTitle = "Aún no has guardado nada";
  static const String emptyDownloadsBody =
      "Cuando guardes un video, lo verás aquí.";
  static const String pasteALink = "Pegar un enlace";
  static const String savedVideo = "Video guardado";
  static const String share = "Compartir";
  static const String shareVideo = "Compartir video";
  static const String withCreditsShort = "con créditos";
  static const String noWatermarkShort = "sin marca";
  static const String audioShort = "solo audio";
  static String stoppedAt(int percent) => "se quedó en $percent %";
  static String shareText(String handle) => "Video de @$handle";
}
