import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_text.dart';
import 'app_tokens.dart';
import 'savetic_colors.dart';

/// Temas claro y oscuro de SaveTic (dirección «Marcador»).
abstract final class AppTheme {
  static const _marino = Color(0xFF06152D);

  static final ColorScheme _darkScheme = const ColorScheme.dark(
    primary: Color(0xFF99F2C8),
    onPrimary: _marino,
    secondary: Color(0xFF99F2C8),
    onSecondary: _marino,
    surface: Color(0xFF0D2140),
    onSurface: Color(0xFFEEF3F8),
    onSurfaceVariant: Color(0xFF93A3B8),
    surfaceContainerHighest: Color(0xFF13294D),
    outline: Color(0xFF1C3356),
    outlineVariant: Color(0xFF1C3356),
    error: Color(0xFFFF7A7A),
    onError: _marino,
  );

  static final ColorScheme _lightScheme = const ColorScheme.light(
    primary: _marino,
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF0B7A55),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    onSurface: _marino,
    onSurfaceVariant: Color(0xFF53627A),
    surfaceContainerHighest: Color(0xFFEEF1F5),
    outline: Color(0xFFE1E6ED),
    outlineVariant: Color(0xFFE1E6ED),
    error: Color(0xFFC62828),
    onError: Color(0xFFFFFFFF),
  );

  static ThemeData get dark => _build(
    scheme: _darkScheme,
    extension: SaveticColors.dark,
    scaffold: _marino,
  );

  static ThemeData get light => _build(
    scheme: _lightScheme,
    extension: SaveticColors.light,
    scaffold: const Color(0xFFF4F6F9),
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required SaveticColors extension,
    required Color scaffold,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final textTheme = AppText.scale.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
    );
    const buttonSize = Size.fromHeight(AppSizes.button);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      extensions: [extension],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: scheme.onSurface),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          backgroundColor: extension.accent,
          foregroundColor: extension.onAccent,
          disabledBackgroundColor: extension.accent.withValues(alpha: 0.45),
          disabledForegroundColor: extension.onAccent.withValues(alpha: 0.8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: extension.border, width: AppSizes.borderThin),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.touch, AppSizes.touch),
          textStyle: textTheme.labelMedium,
          foregroundColor: scheme.onSurface,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.touch, AppSizes.touch),
          foregroundColor: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: extension.muted),
        labelStyle: textTheme.labelMedium?.copyWith(color: extension.muted),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: extension.failed,
          fontWeight: FontWeight.w600,
        ),
        border: _inputBorder(extension.border),
        enabledBorder: _inputBorder(extension.border),
        focusedBorder: _inputBorder(scheme.primary),
        errorBorder: _inputBorder(extension.failed),
        focusedErrorBorder: _inputBorder(extension.failed),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: extension.downloading,
        linearTrackColor: extension.line,
        linearMinHeight: AppSizes.progressBar,
        circularTrackColor: extension.line,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: scheme.onSurface,
        side: BorderSide(color: extension.border, width: AppSizes.borderThin),
        labelStyle: textTheme.labelMedium?.copyWith(color: extension.muted),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: scaffold),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: extension.scrim,
        showDragHandle: true,
        dragHandleColor: extension.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: extension.line, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: extension.muted,
        textColor: scheme.onSurface,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected)
                  ? extension.downloading
                  : extension.line,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: BorderSide(color: color, width: AppSizes.borderThin),
  );
}
