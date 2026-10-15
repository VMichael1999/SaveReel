import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'download_format.dart';

enum AppThemeChoice {
  system,
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
    AppThemeChoice.system => ThemeMode.system,
    AppThemeChoice.light => ThemeMode.light,
    AppThemeChoice.dark => ThemeMode.dark,
  };
}

/// Qué hacer cuando se va a descargar con datos móviles (o con una red de
/// pago, como un punto de acceso del teléfono).
enum MobileDataPolicy {
  /// Pregunta solo si el archivo es grande.
  ask,

  /// Descarga siempre, sin preguntar.
  allow,

  /// Pregunta siempre antes de descargar con datos móviles.
  wifiOnly;

  /// Desde este peso, con [ask] se pregunta antes de gastar datos.
  static const int heavyBytes = 50 * 1024 * 1024;

  /// Si hay que pedir confirmación antes de descargar [bytes] (nulo si no se
  /// sabe cuánto pesa) con una red de pago o sin ella.
  bool needsConfirmation({required bool metered, required int? bytes}) =>
      switch (this) {
        MobileDataPolicy.allow => false,
        MobileDataPolicy.wifiOnly => metered,
        MobileDataPolicy.ask =>
          metered && bytes != null && bytes >= heavyBytes,
      };
}

/// Lo que el usuario puede ajustar. Por omisión: oscuro, con créditos y
/// copiando a la galería.
class AppSettings extends Equatable {
  const AppSettings({
    this.defaultFormat = DownloadFormat.withCredits,
    this.saveToGallery = true,
    this.theme = AppThemeChoice.dark,
    this.mobileData = MobileDataPolicy.ask,
  });

  final DownloadFormat defaultFormat;
  final bool saveToGallery;
  final AppThemeChoice theme;
  final MobileDataPolicy mobileData;

  AppSettings copyWith({
    DownloadFormat? defaultFormat,
    bool? saveToGallery,
    AppThemeChoice? theme,
    MobileDataPolicy? mobileData,
  }) => AppSettings(
    defaultFormat: defaultFormat ?? this.defaultFormat,
    saveToGallery: saveToGallery ?? this.saveToGallery,
    theme: theme ?? this.theme,
    mobileData: mobileData ?? this.mobileData,
  );

  Map<String, dynamic> toJson() => {
    'defaultFormat': defaultFormat.name,
    'saveToGallery': saveToGallery,
    'theme': theme.name,
    'mobileData': mobileData.name,
  };

  /// Tolerante: un valor desconocido o ausente cae en el valor por omisión.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      return fallback;
    }

    const defaults = AppSettings();
    return AppSettings(
      defaultFormat: pick(
        // «gallery» no es una preferencia: depende de cada publicación.
        [
          DownloadFormat.withCredits,
          DownloadFormat.noWatermark,
          DownloadFormat.audio,
        ],
        json['defaultFormat'],
        defaults.defaultFormat,
      ),
      saveToGallery:
          json['saveToGallery'] is bool
              ? json['saveToGallery'] as bool
              : defaults.saveToGallery,
      theme: pick(AppThemeChoice.values, json['theme'], defaults.theme),
      mobileData: pick(
        MobileDataPolicy.values,
        json['mobileData'],
        defaults.mobileData,
      ),
    );
  }

  @override
  List<Object?> get props => [defaultFormat, saveToGallery, theme, mobileData];
}
