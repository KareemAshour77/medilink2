// lib/screens/home/add_record_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/records_service.dart';
import '../../../core/utils/record_labels.dart';
import '../../../data/records_data.dart';

/// Add New Record. Two modes:
///   • Patient mode (default): all 4 record types, saved via POST /records.
///   • Doctor prescription mode (`prescriptionOnly: true`, with `patientId`):
///     type is locked to Prescription, NO status selector, saved via
///     POST /records/prescription with status auto-set to taking_now.
class AddRecordScreen extends StatefulWidget {
  /// When true → doctor "Create Prescription" mode (prescription only).
  final bool prescriptionOnly;

  /// Required in prescription mode — the patient the prescription is for.
  final String? patientId;
  final String? patientName;

  const AddRecordScreen({
    super.key,
    this.prescriptionOnly = false,
    this.patientId,
    this.patientName,
  });

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _DrugRow {
  final name = TextEditingController();
  final dosage = TextEditingController();
  final frequency = TextEditingController();
  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
  }
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _titleCtrl     = TextEditingController();
  final _doctorCtrl    = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _notesCtrl     = TextEditingController();

  RecordType   _selectedType   = RecordType.labTest;
  RecordStatus _selectedStatus = RecordStatus.stable;
  DateTime     _selectedDate   = DateTime.now();
  final List<String> _attachments = [];
  final List<_DrugRow> _drugRows = [_DrugRow()];
  bool _saving = false;

  String? _titleError;
  String? _doctorError;
  String? _diagnosisError;

  // Fake attachment picker (no real file_picker package needed)
  final List<String> _fakeFiles = [
    'scan_result.pdf',
    'xray_image.jpg',
    'prescription.pdf',
    'lab_report.pdf',
    'mri_image.jpg',
  ];

  bool get _isPrescription =>
      widget.prescriptionOnly || _selectedType == RecordType.prescription;

  @override
  void initState() {
    super.initState();
    if (widget.prescriptionOnly) _selectedType = RecordType.prescription;
  }

  bool _validate() {
    setState(() {
      _titleError    = _titleCtrl.text.trim().isEmpty ? 'Title is required' : null;
      // Doctor/facility + diagnosis are optional for prescriptions.
      _doctorError   = (_isPrescription || _doctorCtrl.text.trim().isNotEmpty)
          ? null : 'Doctor / Facility is required';
      _diagnosisError = (_isPrescription || _diagnosisCtrl.text.trim().isNotEmpty)
          ? null : 'Diagnosis is required';
    });
    return _titleError == null && _doctorError == null && _diagnosisError == null;
  }

  List<({String name, String dosage, String frequency})> _collectItems() => _drugRows
      .where((r) => r.name.text.trim().isNotEmpty)
      .map((r) => (
            name: r.name.text.trim(),
            dosage: r.dosage.text.trim(),
            frequency: r.frequency.text.trim(),
          ))
      .toList();

  Future<void> _save() async {
    if (!_validate()) return;
    if (_isPrescription && _collectItems().isEmpty) {
      AppSnackBar.show(context, context.l.addMedicationFirst);
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.prescriptionOnly) {
        // Doctor creating a prescription for a patient (status auto taking_now).
        await RecordsService.createPrescription(
          patientId: widget.patientId ?? '',
          title: _titleCtrl.text.trim(),
          doctorOrFacility: _doctorCtrl.text.trim().isEmpty ? null : _doctorCtrl.text.trim(),
          description: _diagnosisCtrl.text.trim().isEmpty ? null : _diagnosisCtrl.text.trim(),
          doctorNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          items: _collectItems(),
        );
      } else {
        // Patient creating any record type.
        await RecordsService.create(
          type: recordTypeToApi(_selectedType),
          title: _titleCtrl.text.trim(),
          doctorOrFacility: _doctorCtrl.text.trim().isEmpty ? null : _doctorCtrl.text.trim(),
          date: _selectedDate.toIso8601String(),
          status: _isPrescription ? null : recordStatusToApi(_selectedStatus),
          description: _diagnosisCtrl.text.trim().isEmpty ? null : _diagnosisCtrl.text.trim(),
          doctorNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          attachments: _attachments,
          items: _isPrescription ? _collectItems() : const [],
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      AppSnackBar.show(context, context.l.recordSaved, backgroundColor: AppColors.primary);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _pickAttachment() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Select Attachment', style: TextStyle(
              color: context.text, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._fakeFiles.map((f) => ListTile(
            leading: Icon(
              f.endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              color: f.endsWith('.pdf') ? AppColors.error : AppColors.purple,
            ),
            title: Text(f, style: TextStyle(color: context.text, fontSize: 14)),
            onTap: () {
              setState(() {
                if (!_attachments.contains(f)) _attachments.add(f);
              });
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _doctorCtrl.dispose();
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    for (final r in _drugRows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg     = context.bg;
    final card   = context.card;
    final txt    = context.text;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: txt),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            widget.prescriptionOnly
                ? context.l.recordTypePrescription
                : context.l.addNewRecord,
            style: TextStyle(color: txt, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Record Type (hidden in doctor prescription mode) ─────────────
          if (widget.prescriptionOnly) ...[
            if (widget.patientName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('${context.l.forPatient} ${widget.patientName}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 13)),
              ),
          ] else ...[
            _Label(txt: txt, text: context.l.recordTypeLabel),
            const SizedBox(height: 10),
            _TypeSelector(
              selected: _selectedType,
              onChanged: (t) => setState(() => _selectedType = t),
            ),
            const SizedBox(height: 20),
          ],

          // ── Title ────────────────────────────────────────────────────────
          _Label(txt: txt, text: context.l.recordTitle),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: txt),
            decoration: InputDecoration(
              hintText: 'e.g. Blood Test Results',
              errorText: _titleError,
              prefixIcon: const Icon(Icons.title_rounded, color: AppColors.grey),
            ),
          ),
          const SizedBox(height: 16),

          // ── Doctor / Facility ────────────────────────────────────────────
          _Label(txt: txt, text: context.l.doctorFacility),
          const SizedBox(height: 8),
          TextField(
            controller: _doctorCtrl,
            style: TextStyle(color: txt),
            decoration: InputDecoration(
              hintText: 'e.g. Dr. Ahmed Hassan — Cairo Lab',
              errorText: _doctorError,
              prefixIcon: const Icon(Icons.local_hospital_outlined, color: AppColors.grey),
            ),
          ),
          const SizedBox(height: 16),

          // ── Date ─────────────────────────────────────────────────────────
          _Label(txt: txt, text: context.l.date),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.grey, size: 20),
                const SizedBox(width: 12),
                Text(_formatDate(_selectedDate),
                    style: TextStyle(color: txt, fontSize: 15)),
                const Spacer(),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.grey),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Status (hidden for prescriptions — auto 'Taking now') ────────
          if (!_isPrescription) ...[
            _Label(txt: txt, text: context.l.status),
            const SizedBox(height: 10),
            Row(children: [
              _StatusChip(
                label: context.l.stable, color: AppColors.success,
                selected: _selectedStatus == RecordStatus.stable,
                onTap: () => setState(() => _selectedStatus = RecordStatus.stable),
              ),
              const SizedBox(width: 10),
              _StatusChip(
                label: context.l.critical, color: AppColors.error,
                selected: _selectedStatus == RecordStatus.critical,
                onTap: () => setState(() => _selectedStatus = RecordStatus.critical),
              ),
              const SizedBox(width: 10),
              _StatusChip(
                label: context.l.pending, color: AppColors.warning,
                selected: _selectedStatus == RecordStatus.pending,
                onTap: () => setState(() => _selectedStatus = RecordStatus.pending),
              ),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Medications (prescriptions only) ─────────────────────────────
          if (_isPrescription) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _Label(txt: txt, text: context.l.medications),
              TextButton.icon(
                onPressed: () => setState(() => _drugRows.add(_DrugRow())),
                icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                label: Text(context.l.addLabel,
                    style: const TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 4),
            for (var i = 0; i < _drugRows.length; i++) _drugCard(i, txt, card),
            const SizedBox(height: 20),
          ],

          // ── Diagnosis ────────────────────────────────────────────────────
          _Label(txt: txt, text: _isPrescription
              ? context.l.notesDescriptionOptional
              : context.l.diagnosisDescription),
          const SizedBox(height: 8),
          TextField(
            controller: _diagnosisCtrl,
            style: TextStyle(color: txt),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe the diagnosis or findings…',
              errorText: _diagnosisError,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // ── Doctor Notes ─────────────────────────────────────────────────
          _Label(txt: txt, text: context.l.doctorNotesOptional),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            style: TextStyle(color: txt),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Any additional notes from the doctor…',
            ),
          ),
          const SizedBox(height: 24),

          // ── Attachments ──────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _Label(txt: txt, text: context.l.attachments),
            TextButton.icon(
              onPressed: _pickAttachment,
              icon: const Icon(Icons.attach_file_rounded,
                  color: AppColors.primary, size: 18),
              label: Text(context.l.addFile,
                  style: const TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
          ]),
          if (_attachments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    style: BorderStyle.none),
              ),
              child: Column(children: [
                Icon(Icons.cloud_upload_outlined,
                    color: AppColors.grey.withOpacity(0.6), size: 40),
                const SizedBox(height: 8),
                Text('No attachments yet',
                    style: TextStyle(color: AppColors.grey, fontSize: 13)),
              ]),
            )
          else
            ...(_attachments.map((a) => _AttachmentRow(
              name: a, isDark: isDark, txt: txt,
              onRemove: () => setState(() => _attachments.remove(a)),
            ))),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(widget.prescriptionOnly
                    ? context.l.createPrescription
                    : context.l.saveRecord),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _drugCard(int i, Color txt, Color card) {
    final r = _drugRows[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divider),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: _drugField(r.name, context.l.drugName, txt)),
          if (_drugRows.length > 1)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.grey),
              onPressed: () => setState(() => _drugRows.removeAt(i).dispose()),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _drugField(r.dosage, context.l.dosageHint, txt)),
          const SizedBox(width: 8),
          Expanded(child: _drugField(r.frequency, context.l.frequencyHint, txt)),
        ]),
      ]),
    );
  }

  Widget _drugField(TextEditingController c, String hint, Color txt) {
    return TextField(
      controller: c,
      style: TextStyle(color: txt, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}

// ── Type selector chips ───────────────────────────────────────────────────────
class _TypeSelector extends StatelessWidget {
  final RecordType selected;
  final ValueChanged<RecordType> onChanged;
  const _TypeSelector({required this.selected, required this.onChanged});

  static const _types = [
    (RecordType.labTest,      'Lab Test',     Icons.biotech_outlined,           AppColors.cyan),
    (RecordType.imaging,      'Imaging',      Icons.document_scanner_outlined,  AppColors.purple),
    (RecordType.prescription, 'Prescription', Icons.receipt_long_outlined,      AppColors.success),
    (RecordType.diagnosis,    'Diagnosis',    Icons.medical_information_outlined,AppColors.error),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10, crossAxisSpacing: 10,
      childAspectRatio: 3,
      children: _types.map((t) {
        final isSelected = selected == t.$1;
        return GestureDetector(
          onTap: () => onChanged(t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? t.$4.withOpacity(0.15) : context.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSelected ? t.$4 : context.divider, width: 1.5),
            ),
            child: Row(children: [
              Icon(t.$3, color: isSelected ? t.$4 : AppColors.grey, size: 18),
              const SizedBox(width: 8),
              Text(recordTypeLabelL10n(context.l, recordTypeToApi(t.$1)),
                  style: TextStyle(
                      color: isSelected ? t.$4 : AppColors.grey,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.color,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : context.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : context.divider, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : AppColors.grey,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

// ── Attachment row ────────────────────────────────────────────────────────────
class _AttachmentRow extends StatelessWidget {
  final String name;
  final bool isDark;
  final Color txt;
  final VoidCallback onRemove;
  const _AttachmentRow({required this.name, required this.isDark,
      required this.txt, required this.onRemove});

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
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, color: AppColors.grey, size: 18),
        ),
      ]),
    );
  }
}

// ── Label widget ──────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final Color txt;
  final String text;
  const _Label({required this.txt, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(color: txt, fontSize: 14, fontWeight: FontWeight.w600));
  }
}
