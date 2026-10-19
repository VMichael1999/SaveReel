import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_tokens.dart';
import '../../../../config/theme/savetic_colors.dart';
import '../../../../core/layout/duo_context.dart';
import '../../../../core/layout/duo_layout.dart';
import '../../../../core/layout/duo_side_bar.dart';
import '../../../../core/layout/duo_split.dart';
import '../../../../core/utils/app_enums.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_message.dart';
import '../../../../localization/app_texts.dart';
import '../bloc/library_cubit/library_cubit.dart';
import '../bloc/locale_cubit/locale_cubit.dart';
import '../bloc/settings_cubit/settings_cubit.dart';
import '../models/app_settings.dart';
import '../models/download_format.dart';
import '../widgets/settings_screen/choice_sheet.dart';
import '../widgets/video_preview/format_option.dart';
import '../widgets/settings_screen/settings_group.dart';
import '../widgets/settings_screen/settings_row.dart';

/// Formato al descargar, copia a la galería, espacio usado y tema.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _cacheBytes;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final bytes = await context.read<LibraryCubit>().thumbnailCacheBytes();
    if (mounted) setState(() => _cacheBytes = bytes);
  }

  Future<void> _clearCache() async {
    await context.read<LibraryCubit>().clearThumbnailCache();
    await _loadCacheSize();
    if (!mounted) return;
    showAppMessage(
      context,
      msg: context.strings.settingsCacheCleared,
      type: MessageType.info,
    );
  }

  String _formatName(DownloadFormat format) => switch (format) {
    DownloadFormat.withCredits => context.strings.settingsFormatValueCredits,
    DownloadFormat.noWatermark =>
      context.strings.settingsFormatValueNoWatermark,
    DownloadFormat.audio => context.strings.settingsFormatValueAudio,
    DownloadFormat.gallery => context.strings.settingsFormatValueCredits,
  };

  String _mobileDataName(MobileDataPolicy policy) => switch (policy) {
    MobileDataPolicy.ask => context.strings.settingsMobileDataAskShort,
    MobileDataPolicy.allow => context.strings.settingsMobileDataAllowShort,
    MobileDataPolicy.wifiOnly =>
      context.strings.settingsMobileDataWifiOnlyShort,
  };

  /// La opción que se muestra en la mitad derecha (Duo abierto) o en una
  /// hoja; la misma en los dos, para que abrir o cerrar el teléfono no pierda
  /// lo que se estaba eligiendo.
  _Choice? _choice;

  /// La hoja que está abierta, si la hay.
  _Choice? _sheetChoice;

  DuoLayout? _lastLayout;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final layout = context.duoLayout;
    final previous = _lastLayout;
    _lastLayout = layout;
    if (previous == null || previous == layout) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onLayoutChanged(previous, layout);
    });
  }

  void _onLayoutChanged(DuoLayout previous, DuoLayout next) {
    if (next == DuoLayout.openLandscape) {
      final open = _sheetChoice;
      if (open == null) return;
      _sheetChoice = null;
      Navigator.of(context).pop();
      setState(() => _choice = open);
    } else if (previous == DuoLayout.openLandscape) {
      final shown = _choice;
      if (shown == null) return;
      setState(() => _choice = null);
      _showSheet(shown);
    }
  }

  Future<void> _showSheet(_Choice choice) async {
    _sheetChoice = choice;
    final chosen = await showChoiceSheet<int>(
      context,
      title: choice.title,
      selected: choice.options.indexWhere((o) => o.isSelected()),
      options: [
        for (var i = 0; i < choice.options.length; i++)
          ChoiceOption(
            value: i,
            title: choice.options[i].title,
            subtitle: choice.options[i].subtitle,
          ),
      ],
    );
    if (_sheetChoice == choice) _sheetChoice = null;
    if (chosen != null) await choice.options[chosen].apply();
  }

  void _open(_Choice choice) {
    if (context.duoLayout == DuoLayout.openLandscape) {
      setState(() => _choice = choice);
    } else {
      _showSheet(choice);
    }
  }

  void _pickMobileData() {
    final cubit = context.read<SettingsCubit>();
    bool is_(MobileDataPolicy p) => cubit.state.mobileData == p;
    _open(
      _Choice(
        id: 'mobileData',
        title: context.strings.settingsMobileData,
        options: [
          _Option(
            title: context.strings.settingsMobileDataAsk,
            subtitle: context.strings.settingsMobileDataAskHint,
            isSelected: () => is_(MobileDataPolicy.ask),
            apply: () => cubit.setMobileData(MobileDataPolicy.ask),
          ),
          _Option(
            title: context.strings.settingsMobileDataWifiOnly,
            subtitle: context.strings.settingsMobileDataWifiOnlyHint,
            isSelected: () => is_(MobileDataPolicy.wifiOnly),
            apply: () => cubit.setMobileData(MobileDataPolicy.wifiOnly),
          ),
          _Option(
            title: context.strings.settingsMobileDataAllow,
            subtitle: context.strings.settingsMobileDataAllowHint,
            isSelected: () => is_(MobileDataPolicy.allow),
            apply: () => cubit.setMobileData(MobileDataPolicy.allow),
          ),
        ],
      ),
    );
  }

  String _themeName(AppThemeChoice theme) => switch (theme) {
    AppThemeChoice.system => context.strings.themeSystem,
    AppThemeChoice.light => context.strings.themeLight,
    AppThemeChoice.dark => context.strings.themeDark,
  };

  void _pickFormat() {
    final cubit = context.read<SettingsCubit>();
    bool is_(DownloadFormat f) => cubit.state.defaultFormat == f;
    _open(
      _Choice(
        id: 'format',
        title: context.strings.settingsFormat,
        options: [
          _Option(
            title: context.strings.formatWithCredits,
            subtitle: context.strings.settingsFormatHintCredits,
            isSelected: () => is_(DownloadFormat.withCredits),
            apply: () => cubit.setDefaultFormat(DownloadFormat.withCredits),
          ),
          _Option(
            title: context.strings.formatNoWatermark,
            subtitle: context.strings.formatNoWatermarkHint,
            isSelected: () => is_(DownloadFormat.noWatermark),
            apply: () => cubit.setDefaultFormat(DownloadFormat.noWatermark),
          ),
          _Option(
            title: context.strings.formatAudio,
            subtitle: context.strings.formatAudioHint,
            isSelected: () => is_(DownloadFormat.audio),
            apply: () => cubit.setDefaultFormat(DownloadFormat.audio),
          ),
        ],
      ),
    );
  }

  void _pickLanguage() {
    final cubit = context.read<LocaleCubit>();
    _open(
      _Choice(
        id: 'language',
        title: context.strings.settingsLanguage,
        options: [
          for (final code in AppLanguages.codes)
            _Option(
              title: AppLanguages.names[code]!,
              isSelected: () => cubit.state.languageCode == code,
              apply: () => cubit.setLanguage(code),
            ),
        ],
      ),
    );
  }

  void _pickTheme() {
    final cubit = context.read<SettingsCubit>();
    bool is_(AppThemeChoice t) => cubit.state.theme == t;
    _open(
      _Choice(
        id: 'theme',
        title: context.strings.settingsTheme,
        options: [
          _Option(
            title: context.strings.themeSystem,
            subtitle: context.strings.themeSystemHint,
            isSelected: () => is_(AppThemeChoice.system),
            apply: () => cubit.setTheme(AppThemeChoice.system),
          ),
          _Option(
            title: context.strings.themeLight,
            isSelected: () => is_(AppThemeChoice.light),
            apply: () => cubit.setTheme(AppThemeChoice.light),
          ),
          _Option(
            title: context.strings.themeDark,
            isSelected: () => is_(AppThemeChoice.dark),
            apply: () => cubit.setTheme(AppThemeChoice.dark),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = context.watch<LibraryCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final cache = _cacheBytes;

    final children = <Widget>[
      SettingsGroup(
        title: context.strings.sectionOnDownload,
        children: [
          SettingsRow(
            icon: Icons.high_quality_outlined,
            title: context.strings.settingsFormat,
            value: _formatName(settings.defaultFormat),
            showChevron: true,
            selected: _choice?.id == 'format',
            onTap: _pickFormat,
          ),
          SettingsRow(
            icon: Icons.signal_cellular_alt_rounded,
            title: context.strings.settingsMobileData,
            value: _mobileDataName(settings.mobileData),
            showChevron: true,
            selected: _choice?.id == 'mobileData',
            onTap: _pickMobileData,
          ),
          // Mismo ritmo que las demás filas: ícono, 12 de espacio y texto.
          ListTileTheme(
            data: const ListTileThemeData(
              minLeadingWidth: 24,
              horizontalTitleGap: AppSpacing.md,
            ),
            child: SwitchListTile(
              secondary: Icon(
                Icons.photo_library_outlined,
                color: context.colors.muted,
              ),
              title: Text(
                context.strings.settingsGallery,
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                context.strings.settingsGalleryHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.muted,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              value: settings.saveToGallery,
              onChanged:
                  (v) => context.read<SettingsCubit>().setSaveToGallery(v),
            ),
          ),
        ],
      ),
      SettingsGroup(
        title: context.strings.sectionSpace,
        children: [
          SettingsRow(
            icon: Icons.storage_outlined,
            title: context.strings.settingsDownloads,
            subtitle:
                library.videos.length == 1
                    ? '1 archivo'
                    : '${library.videos.length} archivos',
            value: formatMegabytes(library.totalBytes),
          ),
          SettingsRow(
            icon: Icons.delete_outline_rounded,
            title: context.strings.settingsClearCache,
            value: cache == null ? null : formatMegabytes(cache),
            onTap: cache == 0 ? null : _clearCache,
          ),
        ],
      ),
      SettingsGroup(
        title: context.strings.sectionAppearance,
        children: [
          SettingsRow(
            icon: Icons.brightness_6_outlined,
            title: context.strings.settingsTheme,
            value: _themeName(settings.theme),
            showChevron: true,
            selected: _choice?.id == 'theme',
            onTap: _pickTheme,
          ),
          SettingsRow(
            icon: Icons.language,
            title: context.strings.settingsLanguage,
            value:
                AppLanguages.names[context
                    .watch<LocaleCubit>()
                    .state
                    .languageCode],
            showChevron: true,
            selected: _choice?.id == 'language',
            onTap: _pickLanguage,
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.xs,
          0,
        ),
        child: Text(
          context.strings.legalNotice,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.colors.muted,
          ),
        ),
      ),
    ];

    if (context.duoLayout == DuoLayout.openLandscape) {
      return Scaffold(
        body: DuoSplit(
          left: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    context.strings.settingsTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                ...children,
              ],
            ),
          ),
          right:
              _choice == null ? const SizedBox.shrink() : _ChoicePane(_choice!),
          sideBar: DuoSideBar(
            top: [
              DuoAction(
                icon: Icons.arrow_back_rounded,
                tooltip: context.strings.back,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: children,
      ),
    );
  }
}

/// Una opción de la lista de elecciones.
class _Option {
  const _Option({
    required this.title,
    required this.isSelected,
    required this.apply,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool Function() isSelected;
  final Future<void> Function() apply;
}

/// Lo que se elige en una fila de Ajustes, con sus opciones.
class _Choice {
  const _Choice({required this.id, required this.title, required this.options});

  final String id;
  final String title;
  final List<_Option> options;
}

/// Las opciones de la fila elegida, en la mitad derecha.
class _ChoicePane extends StatelessWidget {
  const _ChoicePane(this.choice);

  final _Choice choice;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              choice.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final option in choice.options) ...[
            FormatOption(
              title: option.title,
              subtitle: option.subtitle,
              selected: option.isSelected(),
              onTap: () => option.apply(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
