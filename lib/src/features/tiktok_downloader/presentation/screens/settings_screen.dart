import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_tokens.dart';
import '../../../../config/theme/savetic_colors.dart';
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

  Future<void> _pickMobileData(AppSettings settings) async {
    final cubit = context.read<SettingsCubit>();
    final chosen = await showChoiceSheet<MobileDataPolicy>(
      context,
      title: context.strings.settingsMobileData,
      selected: settings.mobileData,
      options: [
        ChoiceOption(
          value: MobileDataPolicy.ask,
          title: context.strings.settingsMobileDataAsk,
          subtitle: context.strings.settingsMobileDataAskHint,
        ),
        ChoiceOption(
          value: MobileDataPolicy.wifiOnly,
          title: context.strings.settingsMobileDataWifiOnly,
          subtitle: context.strings.settingsMobileDataWifiOnlyHint,
        ),
        ChoiceOption(
          value: MobileDataPolicy.allow,
          title: context.strings.settingsMobileDataAllow,
          subtitle: context.strings.settingsMobileDataAllowHint,
        ),
      ],
    );
    if (chosen != null) await cubit.setMobileData(chosen);
  }

  String _themeName(AppThemeChoice theme) => switch (theme) {
    AppThemeChoice.system => context.strings.themeSystem,
    AppThemeChoice.light => context.strings.themeLight,
    AppThemeChoice.dark => context.strings.themeDark,
  };

  Future<void> _pickFormat(AppSettings settings) async {
    final cubit = context.read<SettingsCubit>();
    final chosen = await showChoiceSheet<DownloadFormat>(
      context,
      title: context.strings.settingsFormat,
      selected: settings.defaultFormat,
      options: [
        ChoiceOption(
          value: DownloadFormat.withCredits,
          title: context.strings.formatWithCredits,
          subtitle: context.strings.settingsFormatHintCredits,
        ),
        ChoiceOption(
          value: DownloadFormat.noWatermark,
          title: context.strings.formatNoWatermark,
          subtitle: context.strings.formatNoWatermarkHint,
        ),
        ChoiceOption(
          value: DownloadFormat.audio,
          title: context.strings.formatAudio,
          subtitle: context.strings.formatAudioHint,
        ),
      ],
    );
    if (chosen != null) await cubit.setDefaultFormat(chosen);
  }

  Future<void> _pickLanguage() async {
    final cubit = context.read<LocaleCubit>();
    final chosen = await showChoiceSheet<String>(
      context,
      title: context.strings.settingsLanguage,
      selected: cubit.state.languageCode,
      options: [
        for (final code in AppLanguages.codes)
          ChoiceOption(value: code, title: AppLanguages.names[code]!),
      ],
    );
    if (chosen != null) await cubit.setLanguage(chosen);
  }

  Future<void> _pickTheme(AppSettings settings) async {
    final cubit = context.read<SettingsCubit>();
    final chosen = await showChoiceSheet<AppThemeChoice>(
      context,
      title: context.strings.settingsTheme,
      selected: settings.theme,
      options: [
        ChoiceOption(
          value: AppThemeChoice.system,
          title: context.strings.themeSystem,
          subtitle: context.strings.themeSystemHint,
        ),
        ChoiceOption(
          value: AppThemeChoice.light,
          title: context.strings.themeLight,
        ),
        ChoiceOption(
          value: AppThemeChoice.dark,
          title: context.strings.themeDark,
        ),
      ],
    );
    if (chosen != null) await cubit.setTheme(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = context.watch<LibraryCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final cache = _cacheBytes;

    return Scaffold(
      appBar: AppBar(title: Text(context.strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          SettingsGroup(
            title: context.strings.sectionOnDownload,
            children: [
              SettingsRow(
                icon: Icons.high_quality_outlined,
                title: context.strings.settingsFormat,
                value: _formatName(settings.defaultFormat),
                showChevron: true,
                onTap: () => _pickFormat(settings),
              ),
              SettingsRow(
                icon: Icons.signal_cellular_alt_rounded,
                title: context.strings.settingsMobileData,
                value: _mobileDataName(settings.mobileData),
                showChevron: true,
                onTap: () => _pickMobileData(settings),
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
                onTap: () => _pickTheme(settings),
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
        ],
      ),
    );
  }
}
