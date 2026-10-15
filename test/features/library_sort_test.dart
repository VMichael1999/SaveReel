import 'package:flutter_test/flutter_test.dart';
import 'package:savetic/src/features/tiktok_downloader/domain/entities/saved_video.dart';
import 'package:savetic/src/features/tiktok_downloader/presentation/models/library_sort.dart';

SavedVideo _v(String name, {int day = 1, int mb = 1, String? title}) =>
    SavedVideo(
      path: '/app/$name',
      sizeBytes: mb * 1048576,
      modified: DateTime(2026, 1, day),
      title: title,
    );

List<String> _names(List<SavedVideo> videos) =>
    videos.map((v) => v.path.split('/').last).toList();

void main() {
  final videos = [
    _v('a', day: 2, mb: 5, title: 'Zanahoria'),
    _v('b', day: 3, mb: 1, title: 'árbol'),
    _v('c', day: 1, mb: 9),
    _v('d', day: 4, mb: 3, title: 'Mango'),
  ];

  test('más nuevos primero', () {
    expect(_names(LibrarySort.newest.apply(videos)), ['d', 'b', 'a', 'c']);
  });

  test('más antiguos primero', () {
    expect(_names(LibrarySort.oldest.apply(videos)), ['c', 'a', 'b', 'd']);
  });

  test('más pesados primero', () {
    expect(_names(LibrarySort.biggest.apply(videos)), ['c', 'a', 'd', 'b']);
  });

  test('por título sin distinguir tildes y con los sin título al final', () {
    expect(_names(LibrarySort.title.apply(videos)), ['b', 'd', 'a', 'c']);
  });

  test('no modifica la lista original', () {
    final copy = [...videos];
    LibrarySort.title.apply(videos);
    expect(videos, copy);
  });
}
