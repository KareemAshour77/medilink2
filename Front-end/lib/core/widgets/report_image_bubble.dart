// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// widgets/report_image_bubble.dart
//
// Renders a generated report/image (brain MRI, chest X-ray,
// lab analysis, prescription/OCR) inside the chat conversation.
//
//   • Resolves relative URLs via AppConfig.resolveReportImageUrl.
//   • Tap → full-screen, zoomable preview.
//   • Download/save action (fetches bytes, saves to a temp file,
//     then opens it with the system viewer so the user can save).
//   • Reserves a sensible aspect box so large images load without
//     jumping the conversation.
// ─────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'app_snack_bar.dart';
import 'typing_indicator.dart'; // re-uses BotAvatar

class ReportImageBubble extends StatelessWidget {
  final String imageUrl;
  final String? downloadUrl;

  const ReportImageBubble({
    required this.imageUrl,
    this.downloadUrl,
    super.key,
  });

  String get _resolved =>
      AppConfig.resolveReportImageUrl(imageUrl) ?? imageUrl;

  String get _resolvedDownload =>
      AppConfig.resolveReportImageUrl(downloadUrl ?? imageUrl) ?? _resolved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const BotAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
                border: context.isDark
                    ? Border.all(color: context.divider)
                    : null,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Tappable image ─────────────────────────
                  GestureDetector(
                    onTap: () => _openFullScreen(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 260,
                          minHeight: 160,
                          maxHeight: 340,
                        ),
                        child: Image.network(
                          _resolved,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return _placeholder(
                              context,
                              const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (ctx, _, __) => _placeholder(
                            context,
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image_rounded,
                                      color: context.text.withOpacity(0.4)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Image unavailable',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: context.text.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Actions: open + download ───────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ActionButton(
                        icon: Icons.fullscreen_rounded,
                        label: 'View',
                        onTap: () => _openFullScreen(context),
                      ),
                      _ActionButton(
                        icon: Icons.download_rounded,
                        label: 'Save',
                        onTap: () => _download(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context, Widget child) => Container(
        width: 260,
        height: 180,
        color: context.bg,
        child: child,
      );

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenImage(
          url: _resolved,
          onDownload: () => _download(context),
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    try {
      final res = await http.get(Uri.parse(_resolvedDownload));
      if (res.statusCode != 200) {
        throw 'HTTP ${res.statusCode}';
      }
      // Save into the system temp dir (no extra plugin needed), then hand off
      // to the OS viewer where the user can save/share it.
      final name = 'medilink_report_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = '${Directory.systemTemp.path}${Platform.pathSeparator}$name';
      final file = await File(path).writeAsBytes(res.bodyBytes);
      final opened = await OpenFilex.open(file.path);
      if (opened.type != ResultType.done && context.mounted) {
        AppSnackBar.show(context, 'Saved to: ${file.path}',
            backgroundColor: Colors.black87,
            duration: const Duration(seconds: 3));
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, 'Could not download image ($e)',
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3));
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Full-screen zoomable preview ──────────────────────────
class _FullScreenImage extends StatelessWidget {
  final String url;
  final VoidCallback onDownload;

  const _FullScreenImage({required this.url, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: onDownload,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_rounded, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }
}
