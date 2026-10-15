import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/routes_manager.dart';
import 'config/theme/app_theme.dart';
import 'container_injector.dart';
import 'localization/app_texts.dart';
import 'features/tiktok_downloader/domain/entities/saved_video.dart';
import 'features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'features/tiktok_downloader/presentation/bloc/first_use_cubit/first_use_cubit.dart';
import 'features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'features/tiktok_downloader/presentation/bloc/locale_cubit/locale_cubit.dart';
import 'features/tiktok_downloader/presentation/bloc/settings_cubit/settings_cubit.dart';
import 'features/tiktok_downloader/presentation/bloc/shared_link_cubit/shared_link_cubit.dart';
import 'features/tiktok_downloader/presentation/models/app_settings.dart';
import 'features/tiktok_downloader/presentation/widgets/app_lifecycle_bridge.dart';

/// En depuración, `--dart-define=CATALOG=true` abre el catálogo de componentes.
const bool _showCatalog = kDebugMode && bool.fromEnvironment('CATALOG');

/// Para volver a Inicio cuando llega un enlace desde «Compartir».
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<DownloaderBloc>()),
        BlocProvider(create: (context) => sl<LibraryCubit>()..load()),
        BlocProvider(create: (context) => sl<FirstUseCubit>()..load()),
        BlocProvider(create: (context) => sl<LocaleCubit>()..load()),
        BlocProvider(create: (context) => sl<SettingsCubit>()..load()),
        BlocProvider(create: (context) => sl<SharedLinkCubit>()..start()),
      ],
      child: BlocListener<SharedLinkCubit, SharedLinkState>(
        listener: _goHomeForSharedLink,
        child: BlocListener<DownloaderBloc, DownloaderState>(
          listener: _syncLibrary,
          child: AppLifecycleBridge(
            child: BlocBuilder<LocaleCubit, Locale>(
              builder:
                  (context, locale) => BlocBuilder<SettingsCubit, AppSettings>(
                    buildWhen: (a, b) => a.theme != b.theme,
                    builder:
                        (context, settings) => AppLocaleScope(
                          code: locale.languageCode,
                          child: MaterialApp(
                            debugShowCheckedModeBanner: false,
                            initialRoute:
                                _showCatalog ? Routes.catalog : Routes.splash,
                            onGenerateRoute: AppRouter.getRoute,
                            theme: AppTheme.light,
                            darkTheme: AppTheme.dark,
                            themeMode: settings.theme.themeMode,
                            navigatorKey: _navigatorKey,
                            locale: locale,
                            supportedLocales: AppLanguages.supportedLocales,
                            localizationsDelegates: const [
                              GlobalMaterialLocalizations.delegate,
                              GlobalWidgetsLocalizations.delegate,
                              GlobalCupertinoLocalizations.delegate,
                            ],
                          ),
                        ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  /// Si llega un enlace con la app en otra pantalla, vuelve al inicio, donde
  /// el enlace se pone solo y se busca el video.
  void _goHomeForSharedLink(BuildContext context, SharedLinkState state) {
    if (state.pending == null && !state.missing) return;
    _navigatorKey.currentState?.popUntil(
      (route) => route.isFirst || route.settings.name == Routes.downloader,
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
            network: data?.network,
          ),
        );
      case DownloaderVideoDeleted(:final path):
        library.forget(path);
      default:
        break;
    }
  }
}
