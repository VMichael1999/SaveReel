import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/routes_manager.dart';
import 'config/theme/app_theme.dart';
import 'container_injector.dart';
import 'features/tiktok_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';

/// En depuración, `--dart-define=CATALOG=true` abre el catálogo de componentes.
const bool _showCatalog = kDebugMode && bool.fromEnvironment('CATALOG');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DownloaderBloc>(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: _showCatalog ? Routes.catalog : Routes.splash,
        onGenerateRoute: AppRouter.getRoute,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
      ),
    );
  }
}
