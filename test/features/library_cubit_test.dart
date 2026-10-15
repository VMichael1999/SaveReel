import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';

import '../support/fake_library.dart';

SavedVideo _video(String name, {int? seconds, int size = 1048576}) =>
    SavedVideo(
      path: '/app/$name',
      sizeBytes: size,
      modified: DateTime(2026, 1, 1),
      durationSeconds: seconds,
    );

void main() {
  test(
    'carga los videos y suma cuántos hay de cada tipo y cuánto pesan',
    () async {
      final cubit = fakeLibraryCubit(
        FakeSavedVideosRepo(
          videos: [
            _video('a.mp4', seconds: 10),
            _video('b.mp4', seconds: 20),
            _video('c.mp3', seconds: 30),
          ],
        ),
      );

      expect(cubit.state.status, LibraryStatus.loading);
      await cubit.load();

      expect(cubit.state.status, LibraryStatus.ready);
      expect(cubit.state.videoCount, 2);
      expect(cubit.state.audioCount, 1);
      expect(cubit.state.totalBytes, 3 * 1048576);
      await cubit.close();
    },
  );

  test(
    'completa las duraciones que faltan leyéndolas de cada archivo',
    () async {
      final cubit = fakeLibraryCubit(
        FakeSavedVideosRepo(
          videos: [
            _video('a.mp4'),
            _video('b.mp4', seconds: 5),
            _video('c.mp4'),
          ],
          durations: {'/app/a.mp4': 34, '/app/c.mp4': null},
        ),
      );

      await cubit.load();

      final byName = {for (final v in cubit.state.videos) v.path: v};
      expect(byName['/app/a.mp4']!.durationSeconds, 34);
      expect(byName['/app/b.mp4']!.durationSeconds, 5);
      expect(byName['/app/c.mp4']!.durationSeconds, isNull);
      await cubit.close();
    },
  );

  test('anotar una descarga la agrega a la biblioteca', () async {
    final repo = FakeSavedVideosRepo();
    final cubit = fakeLibraryCubit(repo);
    await cubit.load();
    expect(cubit.state.videos, isEmpty);

    await cubit.record(
      const SavedVideoMetadata(
        path: '/app/nuevo.mp4',
        title: 'Lomo saltado',
        authorHandle: 'cocinaconlucia',
        durationSeconds: 34,
      ),
    );

    expect(repo.recorded.single.title, 'Lomo saltado');
    expect(cubit.state.videos.single.authorHandle, 'cocinaconlucia');
    await cubit.close();
  });

  test('olvidar un video lo quita de la lista y de los datos', () async {
    final repo = FakeSavedVideosRepo(
      videos: [_video('a.mp4', seconds: 1), _video('b.mp4', seconds: 2)],
    );
    final cubit = fakeLibraryCubit(repo);
    await cubit.load();

    await cubit.forget('/app/a.mp4');

    expect(cubit.state.videos.map((v) => v.path), ['/app/b.mp4']);
    expect(repo.forgotten, ['/app/a.mp4']);
    await cubit.close();
  });

  test('informa el peso de las portadas y las borra', () async {
    final repo = FakeSavedVideosRepo()..cacheBytes = 3200000;
    final cubit = fakeLibraryCubit(repo);

    expect(await cubit.thumbnailCacheBytes(), 3200000);

    await cubit.clearThumbnailCache();

    expect(repo.cacheClears, 1);
    expect(await cubit.thumbnailCacheBytes(), 0);
    await cubit.close();
  });
}
