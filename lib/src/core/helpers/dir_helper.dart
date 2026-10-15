import 'dart:io';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class DirHelper {
  static const String _albumName = 'SaveReel';

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

  static Future<void> saveImageToGallery(String imagePath) async {
    await Gal.putImage(imagePath, album: _albumName);
  }

  /// Guarda una foto o un video en la galería según su extensión.
  static Future<void> saveMediaToGallery(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov')
        ? saveVideoToGallery(path)
        : saveImageToGallery(path);
  }

  static Future<void> removeFileFromDownloadsDir(String videoPath) async {
    await File(videoPath).delete();
  }
}
