import 'dart:io';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class DirHelper {
  static const String _albumName = 'SaveTic';

  static Future<String> getAppPath() async {
    final Directory base = Platform.isAndroid
        ? (await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory())
        : await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_albumName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<void> saveVideoToGallery(String videoPath) async {
    await Gal.putVideo(videoPath, album: _albumName);
  }

  static Future<void> removeFileFromDownloadsDir(String videoPath) async {
    await File(videoPath).delete();
  }
}
