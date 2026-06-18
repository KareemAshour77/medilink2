import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/record_labels.dart';

/// Opens a READ-ONLY list of a patient's records (doctor view). Tapping a row
/// opens the single-record details sheet. Used after access is granted.
Future<void> showPatientRecordsListSheet(
  BuildContext context,
  String patientName,
  List<Map<String, dynamic>> entries,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => _RecordsList(
        scrollController: ctrl,
        patientName: patientName,
        entries: entries,
      ),
    ),
  );
}

class _RecordsList extends StatelessWidget {
  final ScrollController scrollController;
  final String patientName;
  final List<Map<String, dynamic>> entries;
  const _RecordsList({
    required this.scrollController,
    required this.patientName,
    required this.entries,
  });

  String _fmtDate(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'prescription': return Icons.receipt_long_outlined;
      case 'lab_test':     return Icons.biotech_outlined;
      case 'imaging':      return Icons.document_scanner_outlined;
      case 'diagnosis':    return Icons.medical_information_outlined;
      default:             return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(children: [
      const SizedBox(height: 12),
      Center(
        child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.grey.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(children: [
          const Icon(Icons.folder_outlined, color: RoleTheme.doctor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$patientName — ${l.records}',
                style: TextStyle(color: context.text, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: entries.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l.noRecordsForPatient,
                      style: const TextStyle(color: AppColors.grey)),
                ),
              )
            : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final rec = entries[i];
                  final type = rec['type'] as String? ?? '';
                  final isRx = type == 'prescription';
                  final status = rec['status'] as String? ?? '';
                  return ListTile(
                    onTap: () => showRecordDetailsSheet(context, rec),
                    leading: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: RoleTheme.doctor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(_iconFor(type), color: RoleTheme.doctor, size: 20),
                    ),
                    title: Text(rec['title'] as String? ?? l.recordDetails,
                        style: TextStyle(color: context.text, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      '${recordTypeLabelL10n(l, type)}  •  ${_fmtDate(rec['record_date'] ?? rec['created_at'])}',
                      style: const TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                    trailing: isRx && status.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: RoleTheme.doctor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(rxStatusLabelL10n(l, status),
                                style: const TextStyle(
                                    color: RoleTheme.doctor, fontSize: 10, fontWeight: FontWeight.w700)),
                          )
                        : const Icon(Icons.chevron_right_rounded, color: AppColors.grey, size: 18),
                  );
                },
              ),
      ),
    ]);
  }
}

/// Opens a READ-ONLY details sheet for a single record entry (doctor view).
/// All data comes from the backend `/records` entry passed in.
Future<void> showRecordDetailsSheet(
  BuildContext context,
  Map<String, dynamic> entry,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => _RecordDetails(scrollController: ctrl, entry: entry),
    ),
  );
}

class _RecordDetails extends StatelessWidget {
  final ScrollController scrollController;
  final Map<String, dynamic> entry;
  const _RecordDetails({required this.scrollController, required this.entry});

  String _fmtDate(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'prescription': return Icons.receipt_long_outlined;
      case 'lab_test':     return Icons.biotech_outlined;
      case 'imaging':      return Icons.document_scanner_outlined;
      case 'diagnosis':    return Icons.medical_information_outlined;
      default:             return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final type = entry['type'] as String? ?? '';
    final isRx = type == 'prescription';
    final status = entry['status'] as String? ?? '';
    final items = (entry['items'] as List?) ?? const [];
    final attachments = (entry['attachments'] as List?) ?? const [];
    final docFacility = (entry['doctor_or_facility'] as String?) ?? '';
    final description = (entry['description'] as String?) ?? '';
    final notes = (entry['doctor_notes'] as String?) ?? '';

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: RoleTheme.doctor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(type), color: RoleTheme.doctor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry['title'] as String? ?? l.recordDetails,
                  style: TextStyle(
                      color: context.text, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                '${recordTypeLabelL10n(l, type)}  •  ${_fmtDate(entry['record_date'] ?? entry['created_at'])}',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 18),

        // Prescription status — read-only (only the patient can change it).
        if (isRx && status.isNotEmpty)
          _section(context, l.medicationStatus, Icons.medication_liquid_outlined,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(rxStatusLabelL10n(l, status),
                    style: const TextStyle(
                        color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w700)),
              )),

        // Medications.
        if (items.isNotEmpty)
          _section(context, l.medications, Icons.medication_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.whereType<Map>().map((m) {
                  final name = (m['name'] ?? '').toString();
                  final dosage = (m['dosage'] ?? '').toString();
                  final freq = (m['frequency'] ?? '').toString();
                  final sub = [dosage, freq].where((s) => s.isNotEmpty).join(' · ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name,
                              style: TextStyle(color: context.text, fontSize: 14, fontWeight: FontWeight.w600)),
                          if (sub.isNotEmpty)
                            Text(sub, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                        ]),
                      ),
                    ]),
                  );
                }).toList(),
              )),

        if (docFacility.isNotEmpty)
          _section(context, l.doctorFacility, Icons.local_hospital_outlined,
              child: Text(docFacility,
                  style: TextStyle(color: context.text, fontSize: 14, height: 1.5))),

        if (description.isNotEmpty)
          _section(context, l.diagnosisDescription, Icons.medical_information_outlined,
              child: Text(description,
                  style: TextStyle(color: context.text, fontSize: 14, height: 1.6))),

        if (notes.isNotEmpty)
          _section(context, l.doctorNotesOptional, Icons.note_outlined,
              child: Text(notes,
                  style: TextStyle(color: context.text.withOpacity(0.8), fontSize: 14, height: 1.6))),

        if (attachments.isNotEmpty)
          _section(context, l.attachments, Icons.attach_file_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: attachments.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        const Icon(Icons.insert_drive_file_outlined,
                            color: AppColors.grey, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(a.toString(),
                            style: TextStyle(color: context.text, fontSize: 13))),
                      ]),
                    )).toList(),
              )),
      ],
    );
  }

  Widget _section(BuildContext context, String title, IconData icon, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: RoleTheme.doctor, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(color: context.text, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}
