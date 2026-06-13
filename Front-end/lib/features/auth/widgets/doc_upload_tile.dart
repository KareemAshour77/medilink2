import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'image_pick_sheet.dart';

/// Upload tile for a verification document (National ID image, Syndicate card).
/// Shows a thumbnail once picked; tapping re-opens the camera/gallery sheet.
class DocUploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final File? file;
  final ValueChanged<File> onPicked;

  const DocUploadTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final picked = file != null;
    return GestureDetector(
      onTap: () async {
        final f = await showImagePickSheet(context);
        if (f != null) onPicked(f);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: picked ? AppColors.success : context.divider,
            width: picked ? 1.6 : 1.2,
          ),
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: picked
                ? Image.file(file!, fit: BoxFit.cover)
                : const Icon(Icons.cloud_upload_outlined,
                    color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: context.text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  picked ? 'Tap to replace' : subtitle,
                  style: TextStyle(
                    color: picked ? AppColors.success : AppColors.grey,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            picked ? Icons.check_circle_rounded : Icons.add_a_photo_outlined,
            color: picked ? AppColors.success : AppColors.grey,
          ),
        ]),
      ),
    );
  }
}
