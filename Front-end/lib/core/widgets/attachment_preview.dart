// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// widgets/attachment_preview.dart
//
// Bottom-sheet content shown after the user picks one or
// more files.  Features:
//   • Horizontal thumbnail strip with animated entry
//   • Remove button per file
//   • Re-take button for camera images
//   • "Add more" → re-opens the picker (callback)
//   • "Send N files" button → triggers send (callback)
//
// NOTE: The sheet itself is presented by ChatScreen via
// showModalBottomSheet.  Only the CONTENT lives here so it
// remains testable and independent of navigation.
// ─────────────────────────────────────────────────────────

// import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../models/chat_models.dart';
import 'chat_animations.dart';

class AttachmentPreview extends StatefulWidget {
  final List<PendingFile> files;

  /// Remove one file from the queue.
  final void Function(int index) onRemove;

  /// Re-take a specific camera shot.
  final void Function(int index) onRetake;

  /// Open the attachment picker to add more files.
  final VoidCallback onAddMore;

  /// Confirm and send all staged files.
  final VoidCallback onSend;

  const AttachmentPreview({
    required this.files,
    required this.onRemove,
    required this.onRetake,
    required this.onAddMore,
    required this.onSend,
    super.key,
  });

  @override
  State<AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<AttachmentPreview> {
  // Local copy so removal triggers rebuild without waiting for parent.
  late List<PendingFile> _files;

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);
  }

  @override
  void didUpdateWidget(AttachmentPreview old) {
    super.didUpdateWidget(old);
    if (old.files != widget.files) {
      _files = List.from(widget.files);
    }
  }

  bool _isImageFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  void _remove(int i) {
    setState(() => _files.removeAt(i));
    widget.onRemove(i);
    if (_files.isEmpty) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Header row ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_files.length} file${_files.length == 1 ? '' : 's'} selected',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                GestureDetector(
                  onTap: widget.onAddMore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded,
                          color: AppColors.primary, size: 15),
                      SizedBox(width: 3),
                      Text('Add more',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Thumbnail strip ──────────────────────────
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _files.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final pf = _files[i];
                  final isImg = _isImageFile(pf.fileName);

                  return AnimatedThumbnail(
                    key: ValueKey('${pf.fileName}_$i'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // ── Thumbnail / icon box ─────
                            _ThumbnailBox(
                                pendingFile: pf, isImg: isImg),

                            // ── Remove button ────────────
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () => _remove(i),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 11),
                                ),
                              ),
                            ),

                            // ── Re-take button (camera only) ──
                            if (pf.fromCamera && isImg)
                              Positioned(
                                bottom: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () => widget.onRetake(i),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // ── File name label ──────────────
                        SizedBox(
                          width: 60,
                          child: Text(
                            pf.fileName,
                            style: TextStyle(
                                fontSize: 9,
                                color: context.text.withOpacity(0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // ── Send button ──────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _files.isEmpty ? null : widget.onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  'Send ${_files.length} file${_files.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private: thumbnail box (image preview or file icon) ───
class _ThumbnailBox extends StatelessWidget {
  final PendingFile pendingFile;
  final bool isImg;

  const _ThumbnailBox({required this.pendingFile, required this.isImg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isImg
            ? Colors.transparent
            : pendingFile.type.bgColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.divider, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: isImg
          ? ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.file(pendingFile.file, fit: BoxFit.cover),
            )
          : Center(
              child: Icon(
                pendingFile.fileName.toLowerCase().endsWith('.pdf')
                    ? Icons.picture_as_pdf_rounded
                    : Icons.description_rounded,
                color: pendingFile.type.accentColor,
                size: 28,
              ),
            ),
    );
  }
}
