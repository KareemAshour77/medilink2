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
// Single bottom sheet with 3 direct action buttons.
// No category step — the server router classifies the image.
// ══════════════════════════════════════════════════════════
class _AttachmentSheet extends StatelessWidget {
  final VoidCallback onPdf;
  final VoidCallback onXray;
  final VoidCallback onBrain;
  final VoidCallback onOcr;

  const _AttachmentSheet({
    required this.onPdf,
    required this.onXray,
    required this.onBrain,
    required this.onOcr,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            const Text(
              'Test AI Models',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a model to test with an image or send a PDF',
              style: TextStyle(
                  fontSize: 12, color: context.text.withOpacity(0.45)),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Send PDF',
                  color: Colors.red,
                  onTap: onPdf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SourceButton(
                  icon: Icons.healing_rounded,
                  label: 'Test X-Ray',
                  color: Colors.blue,
                  onTap: onXray,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.psychology_rounded,
                  label: 'Test Brain MRI',
                  color: Colors.purple,
                  onTap: onBrain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SourceButton(
                  icon: Icons.text_snippet_rounded,
                  label: 'Test OCR',
                  color: Colors.orange,
                  onTap: onOcr,
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

/// A row tile inside the attachment category picker.
class _AttachmentTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AttachmentTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12, color: context.text.withOpacity(0.5))),
      trailing: Icon(Icons.chevron_right_rounded,
          color: context.text.withOpacity(0.3)),
      onTap: onTap,
    );
  }
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