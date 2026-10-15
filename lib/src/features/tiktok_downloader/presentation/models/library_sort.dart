import '../../../../core/utils/text_search.dart';
import '../../domain/entities/saved_video.dart';

/// Cómo se ordena la biblioteca.
enum LibrarySort {
  newest,
  oldest,
  biggest,
  title;

  List<SavedVideo> apply(List<SavedVideo> videos) {
    final sorted = [...videos];
    switch (this) {
      case LibrarySort.newest:
        sorted.sort((a, b) => b.modified.compareTo(a.modified));
      case LibrarySort.oldest:
        sorted.sort((a, b) => a.modified.compareTo(b.modified));
      case LibrarySort.biggest:
        sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      case LibrarySort.title:
        // Los que no tienen título van al final, no al principio.
        sorted.sort((a, b) {
          final ta = _key(a);
          final tb = _key(b);
          if (ta.isEmpty != tb.isEmpty) return ta.isEmpty ? 1 : -1;
          return ta.compareTo(tb);
        });
    }
    return sorted;
  }

  static String _key(SavedVideo video) =>
      TextSearch.normalize(video.title ?? '');
}
