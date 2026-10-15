import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/features/tiktok_downloader/data/models/video_data_model.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/media_item.dart';

void main() {
  group('MediaItem.extension', () {
    test('toma la extensión del enlace sin los parámetros', () {
      expect(const MediaItem(url: 'https://cdn/x.webp?a=1').extension, 'webp');
      expect(const MediaItem(url: 'https://cdn/x.jpeg').extension, 'jpeg');
      expect(
        const MediaItem(url: 'https://cdn/x.mp4?z=2', isVideo: true).extension,
        'mp4',
      );
    });

    test('si no la reconoce usa la habitual del tipo', () {
      expect(const MediaItem(url: 'https://cdn/imagen').extension, 'jpg');
      expect(
        const MediaItem(url: 'https://cdn/v', isVideo: true).extension,
        'mp4',
      );
    });

    test('una foto con enlace .mp4 sigue siendo jpg', () {
      expect(const MediaItem(url: 'https://cdn/x.mp4').extension, 'jpg');
    });
  });

  group('VideoDataModel con fotos', () {
    Map<String, dynamic> json(Object? images) => {
      'id': '7412',
      'title': 'Mis fotos',
      'duration': 0,
      'play': '',
      'music': 'https://cdn/musica.mp3',
      'images': images,
    };

    test('un slideshow trae sus fotos en orden', () {
      final data = VideoDataModel.fromJson(
        json(['https://cdn/1.jpeg', 'https://cdn/2.webp']),
      );

      expect(data.isGallery, isTrue);
      expect(data.gallery.map((m) => m.url), [
        'https://cdn/1.jpeg',
        'https://cdn/2.webp',
      ]);
      expect(data.photoCount, 2);
      expect(data.music, 'https://cdn/musica.mp3');
    });

    test('también acepta fotos como objetos con url', () {
      final data = VideoDataModel.fromJson(
        json([
          {'url': 'https://cdn/1.jpg'},
          {'otra': 'cosa'},
        ]),
      );
      expect(data.gallery.map((m) => m.url), ['https://cdn/1.jpg']);
    });

    test('un video suelto no trae galería', () {
      expect(VideoDataModel.fromJson(json(null)).isGallery, isFalse);
      expect(VideoDataModel.fromJson(json(<String>[])).isGallery, isFalse);
    });
  });
}
