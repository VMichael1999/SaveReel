import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/savetic_colors.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import '../../bloc/library_cubit/library_cubit.dart';
import '../../models/video_player_args.dart';
import '../../../domain/entities/saved_video.dart';

/// Datos para abrir un video guardado en el reproductor.
VideoPlayerArgs videoPlayerArgsFor(BuildContext context, SavedVideo video) {
  return VideoPlayerArgs(
    path: video.path,
    title: video.title,
    authorHandle: video.authorHandle,
    inGallery: context.read<DownloaderBloc>().isInGallery(video.path),
  );
}

/// Portada de un video guardado. Se calcula una vez y queda en caché.
class LibraryThumbnail extends StatelessWidget {
  const LibraryThumbnail({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAudio = path.toLowerCase().endsWith('.mp3');
    final placeholder = ColoredBox(
      color: colors.raised,
      child: Icon(
        isAudio ? Icons.music_note_rounded : Icons.movie_outlined,
        color: colors.muted,
      ),
    );
    if (isAudio) return placeholder;

    return FutureBuilder<String?>(
      future: context.read<LibraryCubit>().thumbnailFor(path),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null || !File(file).existsSync()) return placeholder;
        return Image.file(
          File(file),
          fit: BoxFit.cover,
          cacheWidth: 360,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => placeholder,
        );
      },
    );
  }
}
