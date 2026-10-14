part of 'library_cubit.dart';

enum LibraryStatus { loading, ready }

class LibraryState extends Equatable {
  const LibraryState({
    this.status = LibraryStatus.loading,
    this.videos = const [],
  });

  final LibraryStatus status;

  /// Del más nuevo al más viejo.
  final List<SavedVideo> videos;

  int get totalBytes => videos.fold(0, (sum, v) => sum + v.sizeBytes);
  int get videoCount => videos.where((v) => !v.isAudio).length;
  int get audioCount => videos.where((v) => v.isAudio).length;

  @override
  List<Object?> get props => [status, videos];
}
