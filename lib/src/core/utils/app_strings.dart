import 'package:flutter/widgets.dart';

import '../../localization/app_texts.dart';

/// Los textos de la interfaz en el idioma de la app. Se obtienen con
/// `context.strings` (o `AppStrings.of(context)`), así que la pantalla se
/// reconstruye sola cuando el usuario cambia de idioma. Los textos viven en
/// `localization/*.json`; aquí solo está el acceso tipado y la lógica de los
/// que llevan datos o plurales.
class AppStrings {
  const AppStrings(this._texts);

  final AppTexts _texts;

  static AppStrings of(BuildContext context) =>
      AppStrings(AppTexts.of(context));

  /// Para el código que no tiene un [BuildContext] (notificaciones del sistema).
  static AppStrings get current => AppStrings(AppTexts.current);

  String _t(String key, [Map<String, Object?>? args]) => _texts.t(key, args);

  /// Traduce lo que llegó como clave desde otra capa (por ejemplo el mensaje
  /// de un error del servicio).
  String translate(String key) => _t(key);
  String get appName => _t('appName');
  String get videoLink => _t('videoLink');
  String get inputLinkFieldText => _t('inputLinkFieldText');
  String get download => _t('download');
  String get downloading => _t('downloading');
  String get downloads => _t('downloads');
  String get downloadReady => _t('downloadReady');
  String get downloadSuccess => _t('downloadSuccess');
  String get play => _t('play');
  String get downloadFall => _t('downloadFall');

  // Inicio
  String get homeTitle => _t('homeTitle');
  String get clipboardFound => _t('clipboardFound');
  String get useThisLink => _t('useThisLink');
  String get paste => _t('paste');
  String get clipboardNoLink => _t('clipboardNoLink');
  String get clearField => _t('clearField');
  String get searchVideo => _t('searchVideo');
  String get searching => _t('searching');
  String get recents => _t('recents');
  String get seeAll => _t('seeAll');
  String get validLinksLook => _t('validLinksLook');
  String get openDownloads => _t('openDownloads');
  String get linkNotAVideo => _t('linkNotAVideo');
  String get linkUnsupported => _t('linkUnsupported');
  String get videoUnavailableInstagram => _t('videoUnavailableInstagram');
  String get videoUnavailable => _t('videoUnavailable');

  // Vista previa
  String get previewSheetLabel => _t('previewSheetLabel');
  String get formatLabel => _t('formatLabel');
  String get formatWithCredits => _t('formatWithCredits');
  String get formatNoWatermark => _t('formatNoWatermark');
  String get formatInstagramVideo => _t('formatInstagramVideo');
  String get formatInstagramVideoHint => _t('formatInstagramVideoHint');
  String get formatGallery => _t('formatGallery');
  String get formatGalleryMixed => _t('formatGalleryMixed');
  String get formatGalleryHintTikTok => _t('formatGalleryHintTikTok');
  String get formatGalleryHintInstagram => _t('formatGalleryHintInstagram');
  String get formatAudio => _t('formatAudio');
  String get formatNoWatermarkHint => _t('formatNoWatermarkHint');
  String get formatAudioHint => _t('formatAudioHint');
  String get formatWithCreditsNoAuthor => _t('formatWithCreditsNoAuthor');
  String get downloadVideo => _t('downloadVideo');
  String get downloadAudio => _t('downloadAudio');
  String get durationLabel => _t('durationLabel');
  String get playsLabel => _t('playsLabel');
  String get downloadsLabel => _t('downloadsLabel');
  String get coverLabel => _t('coverLabel');
  String get untitledVideo => _t('untitledVideo');

  // Descargas
  String get inProgress => _t('inProgress');
  String get today => _t('today');
  String get cancelDownload => _t('cancelDownload');
  String get viewVideo => _t('viewVideo');
  String get retry => _t('retry');
  String get savedInGallery => _t('savedInGallery');
  String get savedInApp => _t('savedInApp');
  String get downloadingNow => _t('downloadingNow');
  String get downloadCancelled => _t('downloadCancelled');
  String get emptyDownloadsTitle => _t('emptyDownloadsTitle');
  String get emptyDownloadsBody => _t('emptyDownloadsBody');
  String get pasteALink => _t('pasteALink');
  String get share => _t('share');
  String get withCreditsShort => _t('withCreditsShort');
  String get noWatermarkShort => _t('noWatermarkShort');
  String get audioShort => _t('audioShort');

  // Reproductor
  String get back => _t('back');
  String get playVideo => _t('playVideo');
  String get saveToGallery => _t('saveToGallery');
  String get inGallery => _t('inGallery');
  String get delete => _t('delete');
  String get cancel => _t('cancel');
  String get deleteTitle => _t('deleteTitle');
  String get deleteBodyCopy => _t('deleteBodyCopy');
  String get deleteBody => _t('deleteBody');
  String get videoDeleted => _t('videoDeleted');
  String get cannotPlay => _t('cannotPlay');
  String get galleryFailed => _t('galleryFailed');
  String get galleryDone => _t('galleryDone');

  // Biblioteca
  String get libraryTitle => _t('libraryTitle');
  String get libraryAll => _t('libraryAll');
  String get libraryVideos => _t('libraryVideos');
  String get search => _t('search');
  String get searchHint => _t('searchHint');
  String get closeSearch => _t('closeSearch');
  String get clearSearch => _t('clearSearch');
  String get sort => _t('sort');
  String get sortNewest => _t('sortNewest');
  String get sortOldest => _t('sortOldest');
  String get sortBiggest => _t('sortBiggest');
  String get sortTitle => _t('sortTitle');
  String get select => _t('select');
  String get galleryShort => _t('galleryShort');
  String get selectAll => _t('selectAll');
  String get cancelSelection => _t('cancelSelection');
  String get deleteManyBody => _t('deleteManyBody');
  String get libraryPhotos => _t('libraryPhotos');
  String get libraryAudio => _t('libraryAudio');
  String get libraryFilterEmpty => _t('libraryFilterEmpty');
  String get openLibrary => _t('openLibrary');
  String get audioBadge => _t('audioBadge');

  // Primer uso
  String get firstUseTitle => _t('firstUseTitle');
  String get step1Title => _t('step1Title');
  String get step1Body => _t('step1Body');
  String get step2Title => _t('step2Title');
  String get step2Body => _t('step2Body');
  String get step3Title => _t('step3Title');
  String get step3Body => _t('step3Body');
  String get galleryTipLead => _t('galleryTipLead');
  String get galleryTipBold => _t('galleryTipBold');
  String get galleryTipTail => _t('galleryTipTail');
  String get openTikTok => _t('openTikTok');
  String get haveALink => _t('haveALink');
  String get tikTokNotFound => _t('tikTokNotFound');

  // Ajustes
  String get settingsTitle => _t('settingsTitle');
  String get settingsOpen => _t('settingsOpen');
  String get sectionOnDownload => _t('sectionOnDownload');
  String get sectionSpace => _t('sectionSpace');
  String get sectionAppearance => _t('sectionAppearance');
  String get settingsFormat => _t('settingsFormat');
  String get settingsFormatValueCredits => _t('settingsFormatValueCredits');
  String get settingsFormatValueNoWatermark =>
      _t('settingsFormatValueNoWatermark');
  String get settingsFormatValueAudio => _t('settingsFormatValueAudio');
  String get settingsFormatHintCredits => _t('settingsFormatHintCredits');
  String get settingsMobileData => _t('settingsMobileData');
  String get settingsMobileDataAsk => _t('settingsMobileDataAsk');
  String get settingsMobileDataAskShort => _t('settingsMobileDataAskShort');
  String get settingsMobileDataAllowShort => _t('settingsMobileDataAllowShort');
  String get settingsMobileDataWifiOnlyShort =>
      _t('settingsMobileDataWifiOnlyShort');
  String get settingsMobileDataAskHint => _t('settingsMobileDataAskHint');
  String get settingsMobileDataAllow => _t('settingsMobileDataAllow');
  String get settingsMobileDataAllowHint => _t('settingsMobileDataAllowHint');
  String get settingsMobileDataWifiOnly => _t('settingsMobileDataWifiOnly');
  String get settingsMobileDataWifiOnlyHint =>
      _t('settingsMobileDataWifiOnlyHint');
  String get mobileDataTitle => _t('mobileDataTitle');
  String get mobileDataBodyWifiOnly => _t('mobileDataBodyWifiOnly');
  String get downloadAnyway => _t('downloadAnyway');
  String get settingsGallery => _t('settingsGallery');
  String get settingsGalleryHint => _t('settingsGalleryHint');
  String get settingsDownloads => _t('settingsDownloads');
  String get settingsClearCache => _t('settingsClearCache');
  String get settingsCacheCleared => _t('settingsCacheCleared');
  String get settingsTheme => _t('settingsTheme');
  String get themeSystem => _t('themeSystem');
  String get themeSystemHint => _t('themeSystemHint');
  String get themeLight => _t('themeLight');
  String get themeDark => _t('themeDark');
  String get legalNotice => _t('legalNotice');
  String get noActiveDownloads => _t('noActiveDownloads');

  String get settingsLanguage => _t('settingsLanguage');
  String get settingsLanguageHint => _t('settingsLanguageHint');

  // Con datos o plurales
  String downloadsCount(int n) => _t('downloadsCount', {'n': n});
  String linkOtherPlatform(String platform) =>
      _t('linkOtherPlatform', {'platform': platform});
  String downloadsInProgress(int n) =>
      n == 1
          ? _t('downloadsInProgressOne')
          : _t('downloadsInProgressMany', {'n': n});
  String galleryCount(int total, {required bool onlyPhotos}) {
    if (onlyPhotos) {
      return total == 1 ? _t('photoOne') : _t('photoMany', {'n': total});
    }
    return total == 1 ? _t('itemOne') : _t('itemMany', {'n': total});
  }

  String downloadGallery(int total, {required bool onlyPhotos}) => _t(
    'downloadGallery',
    {'count': galleryCount(total, onlyPhotos: onlyPhotos)},
  );
  String galleryPosition(int current, int total) =>
      _t('galleryPosition', {'current': current, 'total': total});
  String galleryProgress(int current, int total) =>
      _t('galleryProgress', {'current': current, 'total': total});
  String formatWithCreditsHint(String handle) =>
      _t('formatWithCreditsHint', {'handle': handle});
  String creditNote(String handle) => _t('creditNote', {'handle': handle});
  String stoppedAt(int percent) => _t('stoppedAt', {'percent': percent});
  String shareText(String handle) => _t('shareText', {'handle': handle});
  String playerPosition(String now, String total) =>
      _t('playerPosition', {'now': now, 'total': total});
  String noMatches(String query) => _t('noMatches', {'query': query});
  String selectedCount(int n) =>
      n == 1 ? _t('selectedCountOne') : _t('selectedCountMany', {'n': n});
  String deleteManyTitle(int n) =>
      n == 1 ? _t('deleteManyTitleOne') : _t('deleteManyTitleMany', {'n': n});
  String filesSummary(int count, String size) =>
      '${count == 1 ? _t('fileOne') : _t('fileMany', {'n': count})} · $size';
  String libraryTile(
    String? title, {
    bool isAudio = false,
    String? duration,
    int? pieces,
  }) {
    if (pieces != null) {
      return [
        title == null ? _t('openGallery') : _t('openTitle', {'title': title}),
        pieces == 1 ? _t('pieceOne') : _t('pieceMany', {'n': pieces}),
      ].join(', ');
    }
    return [
      title == null ? _t('playSaved') : _t('playTitle', {'title': title}),
      if (isAudio) _t('audioWord'),
      if (duration != null) duration,
    ].join(', ');
  }

  String remaining(int seconds) {
    if (seconds < 60) return _t('remainingSeconds', {'s': seconds});
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return rest == 0
        ? _t('remainingMinutes', {'m': minutes})
        : _t('remainingMinutesSeconds', {'m': minutes, 's': rest});
  }

  String bytesOf(String received, String total) =>
      _t('bytesOf', {'received': received, 'total': total});

  String stepLabel(int n, String title) =>
      _t('stepLabel', {'n': n, 'title': title});
  String mobileDataBodyHeavy(String size) =>
      _t('mobileDataBodyHeavy', {'size': size});
}

/// `context.strings.searchVideo`: el atajo para llegar a los textos.
extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
