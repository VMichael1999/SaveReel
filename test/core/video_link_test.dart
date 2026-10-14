import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/core/utils/video_link.dart';

void main() {
  group('VideoLink.check', () {
    test('acepta los enlaces cortos y largos de TikTok', () {
      for (final link in [
        'https://vm.tiktok.com/ZMh7K2pQx/',
        'vt.tiktok.com/ZSabc123/',
        'https://www.tiktok.com/@cocinaconlucia/video/7412345678901234567',
        'tiktok.com/@autor/video/7412',
      ]) {
        expect(VideoLink.check(link).isValid, isTrue, reason: link);
      }
    });

    test('un campo vacío no es un error de enlace', () {
      expect(VideoLink.check('   ').status, VideoLinkStatus.empty);
    });

    test('reconoce enlaces de otras plataformas por su nombre', () {
      final check = VideoLink.check('https://instagram.com/reel/C9xQ2/');
      expect(check.status, VideoLinkStatus.otherPlatform);
      expect(check.platform, 'Instagram');
    });

    test('distingue la portada de TikTok de un video', () {
      expect(
        VideoLink.check('https://www.tiktok.com/').status,
        VideoLinkStatus.notAVideo,
      );
    });

    test(
      'rechaza texto que no es un enlace y dominios que solo se parecen',
      () {
        expect(VideoLink.check('hola').status, VideoLinkStatus.notTikTok);
        expect(
          VideoLink.check('https://faketiktok.com/@a/video/1').status,
          VideoLinkStatus.notTikTok,
        );
        expect(
          VideoLink.check('https://tiktok.com.malo.com/@a/video/1').status,
          VideoLinkStatus.notTikTok,
        );
      },
    );
  });

  group('VideoLink.find', () {
    test('extrae el enlace de un texto copiado desde la app', () {
      expect(
        VideoLink.find('Mira este video https://vm.tiktok.com/ZMh7K2pQx/ 🔥'),
        'https://vm.tiktok.com/ZMh7K2pQx/',
      );
    });

    test('devuelve nulo si no hay un enlace de TikTok', () {
      expect(VideoLink.find('https://instagram.com/reel/C9xQ2/'), isNull);
      expect(VideoLink.find('nada por aquí'), isNull);
    });
  });

  group('VideoLink.normalize', () {
    test('quita los parámetros de seguimiento del enlace de la versión web', () {
      expect(
        VideoLink.normalize(
          'https://www.tiktok.com/@frutinoveladrama9/video/7689496424051952910'
          '?is_from_webapp=1&sender_device=pc',
        ),
        'https://www.tiktok.com/@frutinoveladrama9/video/7689496424051952910',
      );
    });

    test('quita también el fragmento y los espacios', () {
      expect(
        VideoLink.normalize('  https://vm.tiktok.com/ZMh7K2pQx/?a=1#x  '),
        'https://vm.tiktok.com/ZMh7K2pQx/',
      );
    });

    test('completa el esquema cuando falta', () {
      expect(
        VideoLink.normalize('tiktok.com/@autor/video/7412?lang=es'),
        'https://tiktok.com/@autor/video/7412',
      );
    });

    test('un enlace limpio queda igual', () {
      const link = 'https://vm.tiktok.com/ZMh7K2pQx/';
      expect(VideoLink.normalize(link), link);
    });

    test('lo que no es un enlace válido se devuelve sin tocar', () {
      expect(VideoLink.normalize(' hola '), 'hola');
      expect(
        VideoLink.normalize('https://instagram.com/reel/C9xQ2/?x=1'),
        'https://instagram.com/reel/C9xQ2/?x=1',
      );
    });
  });
}
