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
          'author': {'unique_id': 'cocinaconlucia', 'nickname': 'Lucía'},
        },
      });

      expect(video.videoData, isNotNull);
      expect(video.videoData!.id, '123');
      expect(video.videoData!.duration, 34);
      expect(video.videoData!.authorHandle, 'cocinaconlucia');
    });

    test('deja el autor en nulo cuando la API no lo informa', () {
      final video = TiktokVideoModel.fromJson({
        'code': 0,
        'msg': 'success',
        'processed_time': 0.5,
        'data': {
          'id': '123',
          'duration': 34,
          'title': 'Sin autor',
          'origin_cover': '',
          'play': '',
          'wmplay': '',
          'music': '',
          'play_count': 0,
          'download_count': 0,
        },
      });

      expect(video.videoData!.authorHandle, isNull);
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

  group('respuesta de tikwm.com', () {
    // Recorte de una respuesta real del servicio, con otros datos de ejemplo.
    final json = {
      'code': 0,
      'msg': 'success',
      'processed_time': 0.59,
      'data': {
        'id': '7689496424051952910',
        'title': 'La nieve de Mango Parte 1.2.3 #frutinovelas',
        'cover': 'https://cdn.ejemplo.pe/cover.jpeg',
        'origin_cover': 'https://cdn.ejemplo.pe/origin.jpeg',
        'duration': 218,
        'play': 'https://cdn.ejemplo.pe/play.mp4',
        'wmplay': '/video/media/wmplay/7689496424051952910.mp4',
        'hdplay': '',
        'size': 79585360,
        'wm_size': 65062252,
        'music': 'https://cdn.ejemplo.pe/musica.mp3',
        'play_count': 2225973,
        'download_count': 487,
        'author': {'id': '1', 'unique_id': 'frutinoveladrama9'},
      },
    };

    test('lee el autor, la duración y el peso de cada versión', () {
      final video = TiktokVideoModel.fromJson(json).videoData!;

      expect(video.authorHandle, 'frutinoveladrama9');
      expect(video.duration, 218);
      expect(video.playBytes, 79585360);
      expect(video.wmPlayBytes, 65062252);
      expect(video.playCount, 2225973);
    });

    test('completa las rutas relativas con el servidor del servicio', () {
      final video = TiktokVideoModel.fromJson(json).videoData!;

      expect(
        video.wmPlayVideo,
        'https://www.tikwm.com/video/media/wmplay/7689496424051952910.mp4',
      );
      expect(video.playVideo, 'https://cdn.ejemplo.pe/play.mp4');
    });

    test('un campo vacío o ausente no rompe la lectura', () {
      final data =
          Map<String, dynamic>.from(json['data'] as Map)
            ..remove('size')
            ..remove('music')
            ..['duration'] = '34'
            ..['id'] = 7412;
      final video =
          TiktokVideoModel.fromJson({
            'code': 0,
            'msg': 'success',
            'processed_time': 0.1,
            'data': data,
          }).videoData!;

      expect(video.playBytes, isNull);
      expect(video.music, '');
      expect(video.duration, 34);
      expect(video.id, '7412');
    });

    test('un enlace que el servicio no entiende llega sin datos', () {
      final video = TiktokVideoModel.fromJson({
        'code': -1,
        'msg': 'Url parsing is failed! Please check url.',
        'processed_time': 0.01,
      });

      expect(video.videoData, isNull);
      expect(video.code, -1);
    });
  });
}
