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
      final check = VideoLink.check('https://youtu.be/abc123');
      expect(check.status, VideoLinkStatus.otherPlatform);
      expect(check.platform, 'YouTube');
    });

    test('acepta reels, publicaciones y IGTV de Instagram', () {
      for (final link in [
        'https://www.instagram.com/reel/C9xQ2abc/',
        'https://instagram.com/reels/C9xQ2abc/?igsh=MWx',
        'https://www.instagram.com/p/C9xQ2abc/',
        'https://www.instagram.com/tv/C9xQ2abc/',
        'https://www.instagram.com/usuario/reel/C9xQ2abc/',
      ]) {
        final check = VideoLink.check(link);
        expect(check.isValid, isTrue, reason: link);
        expect(check.network, VideoNetwork.instagram, reason: link);
      }
    });

    test('un perfil o la portada de Instagram no son un video', () {
      for (final link in [
        'https://www.instagram.com/',
        'https://www.instagram.com/usuario/',
        'https://www.instagram.com/stories/usuario/123/',
      ]) {
        expect(
          VideoLink.check(link).status,
          VideoLinkStatus.notAVideo,
          reason: link,
        );
      }
    });

    test('dice de qué red es cada enlace y su código en Instagram', () {
      expect(
        VideoLink.networkOf('https://vm.tiktok.com/ZMh7K2pQx/'),
        VideoNetwork.tiktok,
      );
      expect(
        VideoLink.networkOf('https://www.instagram.com/reel/C9xQ2abc/'),
        VideoNetwork.instagram,
      );
      expect(VideoLink.networkOf('https://youtu.be/abc'), isNull);
      expect(
        VideoLink.shortcodeOf('https://www.instagram.com/p/C9xQ2abc/?x=1'),
        'C9xQ2abc',
      );
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
        expect(VideoLink.check('hola').status, VideoLinkStatus.unsupported);
        expect(
          VideoLink.check('https://faketiktok.com/@a/video/1').status,
          VideoLinkStatus.unsupported,
        );
        expect(
          VideoLink.check('https://tiktok.com.malo.com/@a/video/1').status,
          VideoLinkStatus.unsupported,
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

    test('también encuentra enlaces de Instagram en un texto', () {
      expect(
        VideoLink.find(
          'mira https://www.instagram.com/reel/C9xQ2abc/?igsh=1 !',
        ),
        'https://www.instagram.com/reel/C9xQ2abc/?igsh=1',
      );
    });

    test('devuelve nulo si no hay un enlace compatible', () {
      expect(VideoLink.find('https://youtu.be/abc123'), isNull);
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

    test('en Instagram conserva el código y quita igsh', () {
      expect(
        VideoLink.normalize(
          'https://www.instagram.com/reel/C9xQ2abc/?igsh=MWx',
        ),
        'https://www.instagram.com/reel/C9xQ2abc/',
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
        VideoLink.normalize('https://youtu.be/abc?x=1'),
        'https://youtu.be/abc?x=1',
      );
    });
  });
}
