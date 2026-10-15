class AppStrings {
  static const String appName = "SaveTic";
  static const String videoLink = "Enlace del video";
  static const String inputLinkFieldText = "Enlace de TikTok o Instagram";
  static const String download = "Descargar";
  static const String downloading = "Descargando";
  static const String downloads = "Descargas";
  static const String downloadSuccess = "Descarga exitosa";
  static const String play = "Reproducir";
  static const String downloadFall = "Error en la descarga";

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
      "Ese enlace es de TikTok o Instagram, pero no es de un video.";
  static const String linkUnsupported =
      "Ese enlace no es de un video de TikTok ni de Instagram.";
  static const String videoUnavailable =
      "No pudimos obtener el video. Puede ser privado o haber sido borrado.";
  static String linkOtherPlatform(String platform) =>
      "Ese enlace es de $platform, y por ahora solo bajamos de TikTok e Instagram.";
  static String downloadsInProgress(int n) =>
      n == 1 ? "Tus descargas, 1 en curso" : "Tus descargas, $n en curso";

  // Vista previa
  static const String previewSheetLabel = "Vista previa del video";
  static const String formatLabel = "Formato";
  static const String formatWithCredits = "Video con créditos";
  static const String formatNoWatermark = "Video sin marca de agua";
  static const String formatInstagramVideo = "Video";
  static const String formatInstagramVideoHint =
      "En la mejor calidad que entrega Instagram";
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
  static const String share = "Compartir";
  static const String withCreditsShort = "con créditos";
  static const String noWatermarkShort = "sin marca";
  static const String audioShort = "solo audio";
  static String stoppedAt(int percent) => "se quedó en $percent %";
  static String shareText(String handle) => "Video de @$handle";

  // Reproductor
  static const String back = "Volver";
  static const String playVideo = "Reproducir";
  static const String saveToGallery = "Guardar en galería";
  static const String inGallery = "En galería";
  static const String delete = "Eliminar";
  static const String cancel = "Cancelar";
  static const String deleteTitle = "¿Eliminar este video?";
  static const String deleteBodyCopy =
      "Se borrará de SaveTic. La copia que guardaste en tu galería no se toca.";
  static const String deleteBody = "Se borrará de SaveTic para siempre.";
  static const String videoDeleted = "Video eliminado";
  static const String cannotPlay = "No pudimos reproducir este video.";
  static const String galleryFailed =
      "No pudimos guardarlo en la galería. Revisa el permiso de Fotos.";
  static const String galleryDone = "Guardado en tu galería";
  static String playerPosition(String now, String total) => "$now de $total";

  // Biblioteca
  static const String libraryTitle = "Tus descargas";
  static const String libraryAll = "Todo";
  static const String libraryVideos = "Videos";
  static const String libraryAudio = "Audio";
  static const String libraryFilterEmpty = "No hay nada en este filtro.";
  static const String openLibrary = "Tu biblioteca";
  static const String audioBadge = "Audio";
  static String filesSummary(int count, String size) =>
      "${count == 1 ? '1 archivo' : '$count archivos'} · $size";
  static String libraryTile(
    String? title, {
    bool isAudio = false,
    String? duration,
  }) {
    final base =
        title == null ? "Reproducir video guardado" : "Reproducir $title";
    return [
      base,
      if (isAudio) "audio",
      if (duration != null) duration,
    ].join(", ");
  }

  // Primer uso
  static const String firstUseTitle = "Guarda cualquier video en 3 pasos";
  static const String step1Title = "En TikTok, toca Compartir";
  static const String step1Body = "Es la flecha en el lado derecho del video.";
  static const String step2Title = "Elige «Copiar enlace»";
  static const String step2Body = "Aparece en la fila de opciones que se abre.";
  static const String step3Title = "Vuelve aquí";
  static const String step3Body =
      "Detectamos el enlace copiado y te lo ofrecemos.";
  static const String galleryTipLead = "Los videos van a tu ";
  static const String galleryTipBold = "Galería";
  static const String galleryTipTail =
      ', al álbum "SaveTic". No pedimos acceso a tus archivos.';
  static const String openTikTok = "Abrir TikTok";
  static const String haveALink = "Ya tengo un enlace";
  static const String tikTokNotFound = "No encontramos TikTok en tu teléfono.";
  static String stepLabel(int n, String title) => "Paso $n: $title";

  // Ajustes
  static const String settingsTitle = "Ajustes";
  static const String settingsOpen = "Ajustes";
  static const String sectionOnDownload = "Al descargar";
  static const String sectionSpace = "Espacio";
  static const String sectionAppearance = "Apariencia";
  static const String settingsFormat = "Formato";
  static const String settingsFormatValueCredits = "Con créditos";
  static const String settingsFormatValueNoWatermark = "Sin marca de agua";
  static const String settingsFormatValueAudio = "Solo audio";
  static const String settingsFormatHintCredits =
      "Muestra al autor al compartir";
  static const String settingsGallery = "Guardar en la Galería";
  static const String settingsGalleryHint = 'Álbum "SaveTic"';
  static const String settingsDownloads = "Descargas";
  static const String settingsClearCache = "Borrar miniaturas en caché";
  static const String settingsCacheCleared = "Miniaturas borradas";
  static const String settingsTheme = "Tema";
  static const String themeSystem = "Sistema";
  static const String themeSystemHint = "Sigue el tema de tu teléfono";
  static const String themeLight = "Claro";
  static const String themeDark = "Oscuro";
  static const String legalNotice =
      "SaveTic no está afiliada a TikTok. Descarga solo videos que tengas "
      "permiso de guardar y respeta a sus autores.";
  static const String noActiveDownloads = "No hay descargas en curso.";
}
