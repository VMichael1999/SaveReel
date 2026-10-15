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
  int get videoCount => videos.where((v) => !v.isAudio && !v.isGallery).length;
  int get galleryCount => videos.where((v) => v.isGallery).length;
  int get audioCount => videos.where((v) => v.isAudio).length;
  int countOf(VideoNetwork network) =>
      videos.where((v) => v.source == network).length;

  @override
  List<Object?> get props => [status, videos];
}
