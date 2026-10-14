import 'package:flutter/material.dart';

import '../../../../core/helpers/app_launcher.dart';
import '../widgets/downloader_screen/downloader_screen_app_bar.dart';
import '../widgets/downloader_screen/downloader_screen_body.dart';

class DownloaderScreen extends StatelessWidget {
  const DownloaderScreen({super.key, this.openTikTok = AppLauncher.openTikTok});

  /// Cómo se abre TikTok; las pruebas lo reemplazan.
  final Future<bool> Function() openTikTok;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DownloaderScreenAppBar(),
      body: DownloaderScreenBody(openTikTok: openTikTok),
    );
  }
}
