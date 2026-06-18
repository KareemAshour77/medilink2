// ─────────────────────────────────────────────────────────
// widgets/_attachment_sheet_widgets.dart  (part of chat_screen.dart)
//
// Small, purely-presentational widgets used by the two
// bottom sheets in ChatScreen.  Declared as a `part` so
// they can access ChatScreen's private types while still
// keeping the main file uncluttered.
// ─────────────────────────────────────────────────────────

part of '../../features/patient/screens/chatbot_screen.dart';

// ══════════════════════════════════════════════════════════
// _AttachmentSheet
// Single bottom sheet with TWO direct upload actions:
//   • Upload PDF
//   • Upload / Take Image
// The user never picks X-Ray / Brain / OCR / Lab — the unified
// FastAPI /chat endpoint classifies the file by itself.
// ══════════════════════════════════════════════════════════
class _AttachmentSheet extends StatelessWidget {
  final VoidCallback onPdf;
  final VoidCallback onImage;

  const _AttachmentSheet({
    required this.onPdf,
    required this.onImage,
  });

  @override
  Widget build(BuildContext context) {
    final ar = isArabic;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            Text(
              ar ? 'إرفاق ملف' : 'Attach a file',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              ar
                  ? 'ارفع تقريرًا أو صورة ودع المساعد يحللها'
                  : 'Upload a report or image and let the assistant analyze it',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: context.text.withOpacity(0.45)),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.picture_as_pdf_rounded,
                  label: ar ? 'رفع PDF' : 'Upload PDF',
                  color: Colors.red,
                  onTap: onPdf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SourceButton(
                  icon: Icons.image_rounded,
                  label: ar ? 'رفع / التقاط صورة' : 'Upload / Take Image',
                  color: AppColors.primary,
                  onTap: onImage,
                ),
              ),
            ]),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── Shared tiny widgets ────────────────────────────────────

/// The grey pill handle at the top of every bottom sheet.
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.grey.withOpacity(0.4),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
}

/// Tappable icon+label block inside the source picker row.
class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500),
          ),
        ]),
      ),
    );
  }
}