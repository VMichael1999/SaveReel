import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savetic/src/config/routes_manager.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../domain/entities/download_item.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import 'text_btn_with_icon.dart';
import 'video_status_widget.dart';

class DownloadItemStatus extends StatelessWidget {
  final DownloadItem item;

  const DownloadItemStatus({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    switch (item.status) {
      case DownloadStatus.downloading:
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Text(AppStrings.downloading, textAlign: TextAlign.center),
                Icon(Icons.cloud_download, color: AppColors.primaryColor),
              ],
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
          ],
        );
      case DownloadStatus.success:
        return Column(
          children: [
            const VideoStatusWidget(
              label: AppStrings.downloadSuccess,
              icon: Icons.cloud_done,
              color: AppColors.primaryColor,
            ),
            TextBtnWithIcon(
              icon: Icons.play_circle,
              label: AppStrings.play,
              color: AppColors.primaryColor,
              onPressed: () {
                Navigator.of(context).pushNamed(
                  Routes.viewVideo,
                  arguments: item.path,
                );
              },
            ),
          ],
        );
      case DownloadStatus.error:
        return Column(
          children: [
            const VideoStatusWidget(
              label: AppStrings.downloadFall,
              icon: Icons.cloud_off,
              color: AppColors.error,
            ),
            TextBtnWithIcon(
              icon: Icons.restart_alt,
              label: AppStrings.retryDownload,
              color: AppColors.error,
              onPressed: () {
                context.read<DownloaderBloc>().add(
                      DownloaderSaveVideo(tikTokVideo: item.video),
                    );
              },
            ),
          ],
        );
    }
  }
}
