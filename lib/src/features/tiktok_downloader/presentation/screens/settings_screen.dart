import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_tokens.dart';
import '../../../../config/theme/savetic_colors.dart';
import '../../../../core/utils/app_enums.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_message.dart';
import '../bloc/library_cubit/library_cubit.dart';
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
      msg: AppStrings.settingsCacheCleared,
      type: MessageType.info,
    );
  }

  String _formatName(DownloadFormat format) => switch (format) {
    DownloadFormat.withCredits => AppStrings.settingsFormatValueCredits,
    DownloadFormat.noWatermark => AppStrings.settingsFormatValueNoWatermark,
    DownloadFormat.audio => AppStrings.settingsFormatValueAudio,
  };

  String _themeName(AppThemeChoice theme) => switch (theme) {
    AppThemeChoice.system => AppStrings.themeSystem,
    AppThemeChoice.light => AppStrings.themeLight,
    AppThemeChoice.dark => AppStrings.themeDark,
  };

  Future<void> _pickFormat(AppSettings settings) async {
    final cubit = context.read<SettingsCubit>();
    final chosen = await showChoiceSheet<DownloadFormat>(
      context,
      title: AppStrings.settingsFormat,
      selected: settings.defaultFormat,
      options: const [
        ChoiceOption(
          value: DownloadFormat.withCredits,
          title: AppStrings.formatWithCredits,
          subtitle: AppStrings.settingsFormatHintCredits,
        ),
        ChoiceOption(
          value: DownloadFormat.noWatermark,
          title: AppStrings.formatNoWatermark,
          subtitle: AppStrings.formatNoWatermarkHint,
        ),
        ChoiceOption(
          value: DownloadFormat.audio,
          title: AppStrings.formatAudio,
          subtitle: AppStrings.formatAudioHint,
        ),
      ],
    );
    if (chosen != null) await cubit.setDefaultFormat(chosen);
  }

  Future<void> _pickTheme(AppSettings settings) async {
    final cubit = context.read<SettingsCubit>();
    final chosen = await showChoiceSheet<AppThemeChoice>(
      context,
      title: AppStrings.settingsTheme,
      selected: settings.theme,
      options: const [
        ChoiceOption(
          value: AppThemeChoice.system,
          title: AppStrings.themeSystem,
          subtitle: AppStrings.themeSystemHint,
        ),
        ChoiceOption(value: AppThemeChoice.light, title: AppStrings.themeLight),
        ChoiceOption(value: AppThemeChoice.dark, title: AppStrings.themeDark),
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
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          SettingsGroup(
            title: AppStrings.sectionOnDownload,
            children: [
              SettingsRow(
                icon: Icons.high_quality_outlined,
                title: AppStrings.settingsFormat,
                value: _formatName(settings.defaultFormat),
                showChevron: true,
                onTap: () => _pickFormat(settings),
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
                    AppStrings.settingsGallery,
                    style: theme.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    AppStrings.settingsGalleryHint,
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
            title: AppStrings.sectionSpace,
            children: [
              SettingsRow(
                icon: Icons.storage_outlined,
                title: AppStrings.settingsDownloads,
                subtitle:
                    library.videos.length == 1
                        ? '1 archivo'
                        : '${library.videos.length} archivos',
                value: formatMegabytes(library.totalBytes),
              ),
              SettingsRow(
                icon: Icons.delete_outline_rounded,
                title: AppStrings.settingsClearCache,
                value: cache == null ? null : formatMegabytes(cache),
                onTap: cache == 0 ? null : _clearCache,
              ),
            ],
          ),
          SettingsGroup(
            title: AppStrings.sectionAppearance,
            children: [
              SettingsRow(
                icon: Icons.brightness_6_outlined,
                title: AppStrings.settingsTheme,
                value: _themeName(settings.theme),
                showChevron: true,
                onTap: () => _pickTheme(settings),
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
              AppStrings.legalNotice,
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
