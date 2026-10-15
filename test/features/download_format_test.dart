import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/media_item.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/video_data.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/download_format.dart';

const _video = VideoData(
  id: '42',
  duration: 34,
  title: 'Lomo saltado',
  originCover: '',
  playVideo: 'https://ejemplo.pe/limpio',
  wmPlayVideo: 'https://ejemplo.pe/con-marca',
  music: 'https://ejemplo.pe/audio',
  playCount: 1,
  downloadCount: 1,
);

void main() {
  test('cada formato usa su propio enlace', () {
    expect(
      DownloadFormat.withCredits.urlOf(_video),
      'https://ejemplo.pe/con-marca',
    );
    expect(
      DownloadFormat.noWatermark.urlOf(_video),
      'https://ejemplo.pe/limpio',
    );
    expect(DownloadFormat.audio.urlOf(_video), 'https://ejemplo.pe/audio');
  });

  test('cada formato guarda en un archivo distinto', () {
    final names = DownloadFormat.values.map((f) => f.fileNameFor('42')).toSet();
    expect(names.length, DownloadFormat.values.length);
    expect(DownloadFormat.audio.fileNameFor('42'), '42.mp3');
  });

  test('un formato sin enlace no está disponible', () {
    const sinAudio = VideoData(
      id: '1',
      duration: 1,
      title: '',
      originCover: '',
      playVideo: 'a',
      wmPlayVideo: 'b',
      music: '',
      playCount: 0,
      downloadCount: 0,
    );
    expect(DownloadFormat.audio.isAvailableIn(sinAudio), isFalse);
    expect(DownloadFormat.withCredits.isAvailableIn(sinAudio), isTrue);
  });

  test('el formato de galería solo está en publicaciones con piezas', () {
    const galeria = VideoData(
      id: '9',
      duration: 0,
      title: '',
      originCover: '',
      playVideo: '',
      wmPlayVideo: '',
      music: 'https://ejemplo.pe/audio',
      playCount: 0,
      downloadCount: 0,
      gallery: [MediaItem(url: 'https://ejemplo.pe/1.jpg')],
    );

    expect(DownloadFormat.gallery.isAvailableIn(galeria), isTrue);
    expect(DownloadFormat.gallery.isAvailableIn(_video), isFalse);
    expect(DownloadFormat.withCredits.isAvailableIn(galeria), isFalse);
    expect(DownloadFormat.audio.isAvailableIn(galeria), isTrue);
    expect(DownloadFormat.gallery.fileNameFor('9'), '9');
    expect(DownloadFormat.gallery.isAudio, isFalse);
  });
}
