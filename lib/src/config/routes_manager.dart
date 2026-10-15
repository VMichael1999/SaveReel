import 'package:flutter/material.dart';

import '../features/catalog/presentation/screens/catalog_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/tiktok_downloader/presentation/screens/downloader_screen.dart';
import '../features/tiktok_downloader/presentation/models/video_player_args.dart';
import '../features/tiktok_downloader/presentation/screens/downloads_screen.dart';
import '../features/tiktok_downloader/presentation/screens/library_screen.dart';
import '../features/tiktok_downloader/presentation/screens/settings_screen.dart';
import '../features/tiktok_downloader/presentation/screens/video_player_screen.dart';

class Routes {
  static const String splash = "/splash";
  static const String downloader = "/downloader";
  static const String downloads = "/downloads";
  static const String viewVideo = "/viewVideo";
  static const String catalog = "/catalog";
  static const String library = "/library";
  static const String settings = "/settings";
}

class AppRouter {
  static Route? getRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (context) => const SplashScreen());

      case Routes.settings:
        return MaterialPageRoute(builder: (context) => const SettingsScreen());

      case Routes.library:
        return MaterialPageRoute(builder: (context) => const LibraryScreen());

      case Routes.catalog:
        return MaterialPageRoute(builder: (context) => const CatalogScreen());

      case Routes.downloader:
        return MaterialPageRoute(
          builder: (context) => const DownloaderScreen(),
        );
      case Routes.downloads:
        return MaterialPageRoute(builder: (context) => const DownloadsScreen());
      case Routes.viewVideo:
        return MaterialPageRoute(
          builder:
              (context) => VideoPlayerScreen(
                args: routeSettings.arguments as VideoPlayerArgs,
              ),
        );
    }
    return null;
  }
}
