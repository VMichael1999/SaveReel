import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../domain/entities/video_item.dart';
import 'text_btn_with_icon.dart';

class OldDownloadItem extends StatelessWidget {
  final VideoItem videoItem;
  const OldDownloadItem({super.key, required this.videoItem});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image(
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            image: FileImage(File(videoItem.thumbnailPath!)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextBtnWithIcon(
            icon: Icons.play_circle,
            label: AppStrings.play,
            color: AppColors.primaryColor,
            onPressed: () {
              Navigator.of(context).pushNamed(
                Routes.viewVideo,
                arguments: videoItem.path,
              );
            },
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (String result) {
            if (result == 'share') {
              SharePlus.instance.share(
                ShareParams(
                  files: [XFile(videoItem.path)],
                  text: 'Check out this video!',
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'share',
              child: Text('Compartir'),
            ),
          ],
        ),
      ],
    );
  }
}
