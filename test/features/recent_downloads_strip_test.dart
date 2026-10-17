import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/config/theme/app_theme.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/bloc/library_cubit/library_cubit.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/widgets/downloader_screen/recent_downloads_strip.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/widgets/library_screen/library_thumbnail.dart';

import '../support/fake_library.dart';

SavedVideo _video(String name) => SavedVideo(
  path: '/app/$name.mp4',
  sizeBytes: 1048576,
  modified: DateTime(2026, 1, 1),
  durationSeconds: 10,
);

Future<void> _pump(WidgetTester tester, int count) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final cubit = fakeLibraryCubit(
    FakeSavedVideosRepo(
      videos: [for (var i = 0; i < count; i++) _video('v$i')],
    ),
  );
  await cubit.load();
  await tester.pumpWidget(
    BlocProvider<LibraryCubit>.value(
      value: cubit,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SingleChildScrollView(child: RecentDownloadsStrip()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('muestra hasta seis videos, en dos filas de tres', (
    tester,
  ) async {
    await _pump(tester, 9);

    expect(find.byType(LibraryThumbnail), findsNWidgets(6));
    final rows = {
      for (final e in tester.widgetList(find.byType(LibraryThumbnail)))
        tester.getTopLeft(find.byWidget(e)).dy,
    };
    expect(rows, hasLength(2));
  });

  testWidgets('con cuatro videos llena la segunda fila solo a medias', (
    tester,
  ) async {
    await _pump(tester, 4);
    expect(find.byType(LibraryThumbnail), findsNWidgets(4));
  });

  testWidgets('sin videos no muestra nada', (tester) async {
    await _pump(tester, 0);
    expect(find.byType(LibraryThumbnail), findsNothing);
    expect(find.text('Recientes'), findsNothing);
  });
}
