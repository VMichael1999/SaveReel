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

    test('rechaza texto que no es un enlace y dominios que solo se parecen', () {
      expect(VideoLink.check('hola').status, VideoLinkStatus.notTikTok);
      expect(
        VideoLink.check('https://faketiktok.com/@a/video/1').status,
        VideoLinkStatus.notTikTok,
      );
      expect(
        VideoLink.check('https://tiktok.com.malo.com/@a/video/1').status,
        VideoLinkStatus.notTikTok,
      );
    });
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
}
