import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/features/tiktok_downloader/data/models/tiktok_video_model.dart';

void main() {
  group('TiktokVideoModel.fromJson', () {
    test('lee los datos del video cuando la respuesta es correcta', () {
      final video = TiktokVideoModel.fromJson({
        'code': 0,
        'msg': 'success',
        'processed_time': 0.5,
        'data': {
          'id': '123',
          'duration': 34,
          'title': 'Lomo saltado en 10 minutos',
          'origin_cover': 'https://ejemplo.pe/portada.jpg',
          'play': 'https://ejemplo.pe/video',
          'wmplay': 'https://ejemplo.pe/video-con-marca',
          'music': 'https://ejemplo.pe/audio',
          'play_count': 1200000,
          'download_count': 300,
        },
      });

      expect(video.videoData, isNotNull);
      expect(video.videoData!.id, '123');
      expect(video.videoData!.duration, 34);
    });

    test('deja videoData en nulo cuando la respuesta trae un error', () {
      final video = TiktokVideoModel.fromJson({
        'code': -1,
        'msg': 'Url parsing is failed!',
        'processed_time': 0.1,
      });

      expect(video.videoData, isNull);
    });
  });
}
