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

/// Lo que el usuario puede ajustar. Por omisión: oscuro, con créditos y
/// copiando a la galería.
class AppSettings extends Equatable {
  const AppSettings({
    this.defaultFormat = DownloadFormat.withCredits,
    this.saveToGallery = true,
    this.theme = AppThemeChoice.dark,
  });

  final DownloadFormat defaultFormat;
  final bool saveToGallery;
  final AppThemeChoice theme;

  AppSettings copyWith({
    DownloadFormat? defaultFormat,
    bool? saveToGallery,
    AppThemeChoice? theme,
  }) => AppSettings(
    defaultFormat: defaultFormat ?? this.defaultFormat,
    saveToGallery: saveToGallery ?? this.saveToGallery,
    theme: theme ?? this.theme,
  );

  Map<String, dynamic> toJson() => {
    'defaultFormat': defaultFormat.name,
    'saveToGallery': saveToGallery,
    'theme': theme.name,
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
    );
  }

  @override
  List<Object?> get props => [defaultFormat, saveToGallery, theme];
}
