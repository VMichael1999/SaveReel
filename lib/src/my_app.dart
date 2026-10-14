import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/routes_manager.dart';
import 'config/theme/app_theme.dart';
import 'container_injector.dart';
import 'features/tiktok_downloader/domain/entities/saved_video.dart';
import 'features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'features/tiktok_downloader/presentation/bloc/first_use_cubit/first_use_cubit.dart';
import 'features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'features/tiktok_downloader/presentation/models/app_settings.dart';

/// En depuración, `--dart-define=CATALOG=true` abre el catálogo de componentes.
const bool _showCatalog = kDebugMode && bool.fromEnvironment('CATALOG');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<DownloaderBloc>()),
        BlocProvider(create: (context) => sl<LibraryCubit>()..load()),
        BlocProvider(create: (context) => sl<FirstUseCubit>()..load()),
        BlocProvider(create: (context) => sl<SettingsCubit>()..load()),
      ],
      child: BlocListener<DownloaderBloc, DownloaderState>(
        listener: _syncLibrary,
        child: BlocBuilder<SettingsCubit, AppSettings>(
          buildWhen: (a, b) => a.theme != b.theme,
          builder:
              (context, settings) => MaterialApp(
                debugShowCheckedModeBanner: false,
                initialRoute: _showCatalog ? Routes.catalog : Routes.splash,
                onGenerateRoute: AppRouter.getRoute,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: settings.theme.themeMode,
              ),
        ),
      ),
    );
  }

  /// Mantiene la biblioteca al día con lo que pasa en las descargas.
  void _syncLibrary(BuildContext context, DownloaderState state) {
    final library = context.read<LibraryCubit>();
    switch (state) {
      case DownloaderSaveVideoSuccess(:final path):
        final data =
            context
                .read<DownloaderBloc>()
                .newDownloads
                .where((d) => d.path == path)
                .firstOrNull
                ?.video
                .videoData;
        library.record(
          SavedVideoMetadata(
            path: path,
            title: data?.title,
            authorHandle: data?.authorHandle,
            durationSeconds: data?.duration,
          ),
        );
      case DownloaderVideoDeleted(:final path):
        library.forget(path);
      default:
        break;
    }
  }
}
