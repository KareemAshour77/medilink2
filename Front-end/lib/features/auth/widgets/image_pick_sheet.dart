import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';

/// Shows the "Take a photo / Choose from gallery" bottom sheet and returns the
/// picked [File], or null if cancelled. Shared by the profile avatar and the
/// doctor document upload tiles.
Future<File?> showImagePickSheet(BuildContext context) {
  return showModalBottomSheet<File?>(
    context: context,
    backgroundColor: context.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: sheetContext.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        _pickTile(
          sheetContext,
          icon: Icons.camera_alt_outlined,
          label: 'Take a photo',
          source: ImageSource.camera,
        ),
        _pickTile(
          sheetContext,
          icon: Icons.photo_library_outlined,
          label: 'Choose from gallery',
          source: ImageSource.gallery,
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

Widget _pickTile(
  BuildContext context, {
  required IconData icon,
  required String label,
  required ImageSource source,
}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primary),
    ),
    title: Text(label, style: TextStyle(color: context.text)),
    onTap: () async {
      final x = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (context.mounted) {
        Navigator.pop(context, x != null ? File(x.path) : null);
      }
    },
  );
}
