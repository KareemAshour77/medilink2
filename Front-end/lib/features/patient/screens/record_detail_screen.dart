// lib/screens/home/record_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/records_data.dart';

class RecordDetailScreen extends StatelessWidget {
  final MedicalRecord record;
  const RecordDetailScreen({super.key, required this.record});

  Color get _statusColor {
    switch (record.status) {
      case RecordStatus.critical: return AppColors.error;
      case RecordStatus.pending:  return AppColors.warning;
      default:                    return AppColors.success;
    }
  }

  Color get _typeColor {
    switch (record.type) {
      case RecordType.labTest:     return AppColors.cyan;
      case RecordType.imaging:     return AppColors.purple;
      case RecordType.prescription:return AppColors.success;
      case RecordType.diagnosis:   return AppColors.error;
      default:                     return AppColors.primary;
    }
  }

  IconData get _typeIcon {
    switch (record.type) {
      case RecordType.labTest:     return Icons.biotech_outlined;
      case RecordType.imaging:     return Icons.document_scanner_outlined;
      case RecordType.prescription:return Icons.receipt_long_outlined;
      case RecordType.diagnosis:   return Icons.medical_information_outlined;
      default:                     return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg     = context.bg;
    final card   = context.card;
    final txt    = context.text;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── App bar with gradient ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () => _showShareSheet(context),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_typeIcon, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(record.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(record.doctorOrFacility,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          _Chip(label: record.typeLabel,   color: Colors.white.withOpacity(0.25), textColor: Colors.white),
                          const SizedBox(width: 8),
                          _Chip(label: record.statusLabel, color: _statusColor.withOpacity(0.85),  textColor: Colors.white),
                          const Spacer(),
                          Text(_formatDate(record.date),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Diagnosis
                  _SectionCard(
                    isDark: isDark, card: card, txt: txt,
                    icon: Icons.medical_information_outlined,
                    iconColor: AppColors.primary,
                    title: 'Diagnosis',
                    child: Text(record.diagnosis,
                        style: TextStyle(color: txt, fontSize: 14, height: 1.6)),
                  ),
                  const SizedBox(height: 16),

                  // Symptoms
                  _SectionCard(
                    isDark: isDark, card: card, txt: txt,
                    icon: Icons.sick_outlined,
                    iconColor: AppColors.warning,
                    title: 'Symptoms',
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: record.symptoms.map((s) =>
                        _Chip(label: s, color: AppColors.warning.withOpacity(0.12), textColor: AppColors.warning),
                      ).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Treatment
                  _SectionCard(
                    isDark: isDark, card: card, txt: txt,
                    icon: Icons.medication_outlined,
                    iconColor: AppColors.success,
                    title: 'Treatment & Medications',
                    child: Column(
                      children: record.treatments.map((t) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  color: AppColors.success, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(t,
                                  style: TextStyle(color: txt, fontSize: 14, height: 1.5))),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Doctor notes
                  _SectionCard(
                    isDark: isDark, card: card, txt: txt,
                    icon: Icons.note_outlined,
                    iconColor: AppColors.purple,
                    title: 'Doctor Notes',
                    child: Text(record.doctorNotes,
                        style: TextStyle(
                            color: txt.withOpacity(0.8),
                            fontSize: 14,
                            height: 1.6,
                            fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 16),

                  // Attachments
                  _SectionCard(
                    isDark: isDark, card: card, txt: txt,
                    icon: Icons.attach_file_rounded,
                    iconColor: AppColors.cyan,
                    title: 'Attachments (${record.attachments.length})',
                    child: record.attachments.isEmpty
                        ? Text('No attachments',
                            style: TextStyle(color: AppColors.grey, fontSize: 14))
                        : Column(
                            children: record.attachments.map((a) =>
                              _AttachmentTile(name: a, isDark: isDark, txt: txt),
                            ).toList(),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Set reminder button
                  OutlinedButton.icon(
                    onPressed: () => _showReminderSheet(context),
                    icon: const Icon(Icons.alarm_add_outlined),
                    label: const Text('Set Reminder for Follow-up'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${_month(d.month)} ${d.day}, ${d.year}';

  String _month(int m) => const [
    '', 'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ][m];

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Share Record', style: TextStyle(
              color: context.text, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _ShareOption(icon: Icons.picture_as_pdf_outlined, label: 'Export as PDF',   color: AppColors.error),
          _ShareOption(icon: Icons.email_outlined,          label: 'Send via Email',   color: AppColors.primary),
          _ShareOption(icon: Icons.share_outlined,          label: 'Share with Doctor',color: AppColors.success),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24,
            MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Set Reminder', style: TextStyle(
              color: context.text, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _ShareOption(icon: Icons.today_outlined,       label: 'Tomorrow morning',  color: AppColors.primary),
          _ShareOption(icon: Icons.date_range_outlined,  label: 'In 1 week',         color: AppColors.purple),
          _ShareOption(icon: Icons.calendar_month_outlined, label: 'In 1 month',     color: AppColors.warning),
          _ShareOption(icon: Icons.edit_calendar_outlined,  label: 'Custom date…',   color: AppColors.grey),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Section card widget ───────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Color card, txt;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark, required this.card, required this.txt,
    required this.icon, required this.iconColor,
    required this.title, required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: context.divider) : null,
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(color: txt,
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

// ── Chip widget ───────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color, textColor;
  const _Chip({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(color: textColor,
              fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Attachment tile ───────────────────────────────────────────────────────────
class _AttachmentTile extends StatelessWidget {
  final String name;
  final bool isDark;
  final Color txt;
  const _AttachmentTile({required this.name, required this.isDark, required this.txt});

  @override
  Widget build(BuildContext context) {
    final isPdf = name.endsWith('.pdf');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            color: isPdf ? AppColors.error : AppColors.purple, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(name,
            style: TextStyle(color: txt, fontSize: 13),
            overflow: TextOverflow.ellipsis)),
        Icon(Icons.download_outlined, color: AppColors.primary, size: 18),
      ]),
    );
  }
}

// ── Share option tile ─────────────────────────────────────────────────────────
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ShareOption({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(color: context.text,
              fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: AppColors.grey, size: 14),
      onTap: () => Navigator.pop(context),
    );
  }
}
