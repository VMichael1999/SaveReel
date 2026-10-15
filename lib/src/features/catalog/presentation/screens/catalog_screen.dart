import 'package:flutter/material.dart';

import '../../../../config/theme/app_text.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/theme/app_tokens.dart';
import '../../../../config/theme/savetic_colors.dart';
import '../../../../core/widgets/app_message.dart';
import '../../../../core/widgets/savetic_mark.dart';
import '../../../../core/utils/app_enums.dart';
import '../../../tiktok_downloader/domain/entities/download_item.dart';
import '../../../tiktok_downloader/domain/entities/tiktok_video.dart';
import '../../../tiktok_downloader/domain/entities/video_data.dart';
import '../../../tiktok_downloader/presentation/widgets/downloads_screen/active_download_tile.dart';
import '../../../tiktok_downloader/presentation/widgets/downloads_screen/finished_download_tile.dart';
import '../../../tiktok_downloader/presentation/widgets/video_preview/video_preview_sheet.dart';
import '../../../tiktok_downloader/presentation/widgets/video_preview/video_preview_skeleton.dart';

/// Catálogo de componentes. Solo se abre en depuración:
/// `flutter run --dart-define=CATALOG=true`.
/// Video inventado para ver la vista previa sin llamar a la API.
const _sampleVideo = TikTokVideo(
  code: 0,
  msg: 'success',
  processedTime: 0.4,
  videoData: VideoData(
    id: 'ejemplo',
    duration: 34,
    title: 'Lomo saltado en 10 minutos, versión fácil',
    originCover: 'https://ejemplo.invalid/portada.jpg',
    playVideo: 'https://ejemplo.invalid/limpio',
    wmPlayVideo: 'https://ejemplo.invalid/con-marca',
    music: 'https://ejemplo.invalid/audio',
    playCount: 1200000,
    downloadCount: 18600,
    authorHandle: 'cocinaconlucia',
  ),
);

final _activeItem = DownloadItem(
  video: _sampleVideo,
  status: DownloadStatus.downloading,
  path: 'ejemplo/en-curso.mp4',
  receivedBytes: 4928307,
  totalBytes: 7969177,
  startedAt: DateTime.now().subtract(const Duration(seconds: 6)),
);

const _doneItem = DownloadItem(
  video: _sampleVideo,
  status: DownloadStatus.success,
  path: 'ejemplo/listo.mp4',
  receivedBytes: 9542041,
  totalBytes: 9542041,
);

const _failedItem = DownloadItem(
  video: _sampleVideo,
  status: DownloadStatus.error,
  path: 'ejemplo/fallida.mp4',
  receivedBytes: 34,
  totalBytes: 100,
  failureMessage: 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
);

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool _dark = true;
  int _chip = 0;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    // El catálogo puede alternar entre claro y oscuro sin cambiar la app.
    final theme = _dark ? AppTheme.dark : AppTheme.light;
    return Theme(
      data: theme.copyWith(platform: base.platform),
      child: Builder(builder: (context) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            tooltip: _dark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            onPressed: () => setState(() => _dark = !_dark),
            icon: Icon(
              _dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          const _Section('Marca'),
          Row(
            children: [
              const SaveticMark(size: AppSizes.markLarge),
              const SizedBox(width: AppSpacing.lg),
              Text('SaveReel', style: text.titleLarge),
            ],
          ),
          const _Section('Colores'),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _Swatch('Acento', colors.accent),
              _Swatch('Descargando', colors.downloading),
              _Swatch('Listo', colors.done),
              _Swatch('Falló', colors.failed),
              _Swatch('Elevada', colors.raised),
              _Swatch('Línea', colors.line),
              _Swatch('Texto 2.º', colors.muted),
            ],
          ),
          const _Section('Tipografía'),
          Text('Pega el enlace del video', style: text.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('Lomo saltado en 10 minutos', style: text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Video con créditos', style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Guarda videos en tu teléfono para verlos sin conexión.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '@cocinaconlucia · 0:34 · 1.2 M reproducciones',
            style: text.bodySmall?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('4.7 de 7.6 MB · 62 %', style: text.bodyMedium?.tabular),
          const _Section('Botones'),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded),
            label: const Text('Descargar video · 9.1 MB'),
          ),
          const SizedBox(height: AppSpacing.md),
          const FilledButton(onPressed: null, child: Text('Buscar video')),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Ya tengo un enlace'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              TextButton(onPressed: () {}, child: const Text('Ver las 12')),
              IconButton(
                tooltip: 'Cancelar descarga',
                onPressed: () {},
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const _Section('Campo de texto'),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Enlace del video',
              hintText: 'tiktok.com/@autor/video/…',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Enlace del video',
              errorText: 'Ese enlace es de YouTube, y por ahora solo bajamos de TikTok e Instagram.',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const _Section('Progreso'),
          const LinearProgressIndicator(value: 0.62),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '4.7 de 7.6 MB · 62 % · faltan 3 s',
            style: text.bodySmall?.copyWith(color: colors.muted).tabular,
          ),
          const _Section('Estados de una descarga'),
          const _StateRow(Icons.downloading, 'Descargando'),
          const SizedBox(height: AppSpacing.sm),
          _StateRow(
            Icons.check_circle_outline,
            'En tu galería · 9.1 MB',
            color: colors.done,
          ),
          const SizedBox(height: AppSpacing.sm),
          _StateRow(
            Icons.error_outline,
            'Se cortó la conexión al 34 %',
            color: colors.failed,
          ),
          const _Section('Filtros'),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final (i, label)
                  in ['Todo 12', 'Videos 10', 'Audio 2'].indexed)
                ChoiceChip(
                  label: Text(label),
                  selected: _chip == i,
                  onSelected: (_) => setState(() => _chip = i),
                ),
            ],
          ),
          const _Section('Marcador de posición'),
          const VideoPreviewSkeleton(),
          const _Section('Descargas'),
          ActiveDownloadTile(item: _activeItem),
          const FinishedDownloadTile(item: _doneItem),
          const FinishedDownloadTile(item: _failedItem),
          const _Section('Vista previa del video'),
          OutlinedButton(
            onPressed: () => showVideoPreviewSheet(context, _sampleVideo),
            child: const Text('Abrir la vista previa'),
          ),
          const _Section('Avisos'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton(
                onPressed:
                    () => showAppMessage(
                      context,
                      msg: 'Guardado en tu galería',
                      type: MessageType.success,
                    ),
                child: const Text('Éxito'),
              ),
              OutlinedButton(
                onPressed:
                    () => showAppMessage(
                      context,
                      msg:
                          'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
                      type: MessageType.error,
                    ),
                child: const Text('Error'),
              ),
              OutlinedButton(
                onPressed:
                    () => showAppMessage(
                      context,
                      msg: 'Descarga exitosa',
                      type: MessageType.success,
                      actionLabel: 'Reproducir',
                      onAction: () {},
                    ),
                child: const Text('Con acción'),
              ),
              OutlinedButton(
                onPressed:
                    () => showAppMessage(
                      context,
                      msg: 'Video eliminado',
                      type: MessageType.info,
                    ),
                child: const Text('Info'),
              ),
            ],
          ),
          const _Section('Hojas'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      () => showModalBottomSheet<void>(
                        context: context,
                        builder:
                            (context) => Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.xl,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lomo saltado en 10 minutos, versión fácil',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  FilledButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: const Text(
                                      'Descargar video · 9.1 MB',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                  child: const Text('Hoja'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: context.colors.muted),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: AppSizes.touch,
          height: AppSizes.touch,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: context.colors.line),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: text.bodySmall),
      ],
    );
  }
}

class _StateRow extends StatelessWidget {
  const _StateRow(this.icon, this.label, {this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.downloading;
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconMd, color: c),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c),
        ),
      ],
    );
  }
}
