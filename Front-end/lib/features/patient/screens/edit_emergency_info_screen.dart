import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/emergency_info_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../models/emergency_info_model.dart';

/// Form to create / edit the patient's emergency information.
/// Pops with `true` when a save succeeds so the caller can refetch.
class EditEmergencyInfoScreen extends StatefulWidget {
  final EmergencyInfoModel? initial;

  const EditEmergencyInfoScreen({super.key, this.initial});

  @override
  State<EditEmergencyInfoScreen> createState() =>
      _EditEmergencyInfoScreenState();
}

class _EditEmergencyInfoScreenState extends State<EditEmergencyInfoScreen> {
  static const _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  // Gender is sourced from the user's account (set at signup / profile),
  // so it is shown read-only here.
  late String _gender;
  DateTime? _dateOfBirth;
  String? _bloodType;
  late List<String> _allergies;
  late List<String> _conditions;
  late List<String> _devices;
  late List<MedicationModel> _medications;
  late bool _organDonor;
  late bool _smoker;
  late bool _isPregnant;
  DateTime? _pregnancyStartDate;
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _languageCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _gender = m?.gender ?? 'male';
    _dateOfBirth = m?.dateOfBirth;
    _bloodType = m?.bloodType;
    _allergies = List<String>.from(m?.allergies ?? const []);
    _conditions = List<String>.from(m?.conditions ?? const []);
    _devices = List<String>.from(m?.medicalDevices ?? const []);
    _medications = List<MedicationModel>.from(m?.medications ?? const []);
    _organDonor = m?.organDonor ?? false;
    _smoker = m?.smoker ?? false;
    _isPregnant = m?.isPregnant ?? false;
    _pregnancyStartDate = m?.pregnancyStartDate;
    if (m?.height != null) _heightCtrl.text = _trimNum(m!.height!);
    if (m?.weight != null) _weightCtrl.text = _trimNum(m!.weight!);
    if (m?.primaryLanguage != null) _languageCtrl.text = m!.primaryLanguage!;
    _loadAccountInfo();
  }

  // The account gender and date of birth (derived from the National ID at
  // registration) live in the `users` table and are the source of truth —
  // both are shown read-only here.
  Future<void> _loadAccountInfo() async {
    final identity = await ApiService.fetchMyIdentity();
    if (!mounted || identity == null) return;
    setState(() {
      final g = identity.gender;
      if (g == 'male' || g == 'female') {
        _gender = g!;
        if (_gender == 'male') {
          _isPregnant = false;
          _pregnancyStartDate = null;
        }
      }
      // Account DOB wins over any previously-saved value.
      if (identity.dateOfBirth != null) _dateOfBirth = identity.dateOfBirth;
    });
  }

  static String _trimNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _languageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final isPregnant = _gender == 'female' && _isPregnant;
    if (isPregnant && _pregnancyStartDate == null) {
      AppSnackBar.show(context, 'Please pick the pregnancy start date.',
          backgroundColor: AppColors.error);
      return;
    }

    final lang = _languageCtrl.text.trim();
    final model = EmergencyInfoModel(
      gender: _gender,
      dateOfBirth: _dateOfBirth,
      bloodType: _bloodType,
      height: double.tryParse(_heightCtrl.text.trim()),
      weight: double.tryParse(_weightCtrl.text.trim()),
      allergies: _allergies,
      conditions: _conditions,
      medications: _medications,
      medicalDevices: _devices,
      organDonor: _organDonor,
      smoker: _smoker,
      isPregnant: isPregnant,
      pregnancyStartDate: isPregnant ? _pregnancyStartDate : null,
      primaryLanguage: lang.isEmpty ? null : lang,
    );

    setState(() => _saving = true);
    try {
      await EmergencyInfoService.save(model);
      if (!mounted) return;
      AppSnackBar.show(context, 'Emergency info saved.',
          backgroundColor: AppColors.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
          context, e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: AppColors.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addMedication() async {
    final med = await showModalBottomSheet<MedicationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MedicationDialog(),
    );
    if (med != null) setState(() => _medications.add(med));
  }

  static int _ageFromDate(DateTime dob) {
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  Future<void> _pickPregnancyDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pregnancyStartDate ?? now,
      // A pregnancy spans up to ~43 weeks; allow a sensible past window.
      firstDate: now.subtract(const Duration(days: 320)),
      lastDate: now,
    );
    if (picked != null) setState(() => _pregnancyStartDate = picked);
  }

  static int _weeksFromDate(DateTime start) {
    final days = DateTime.now().difference(start).inDays;
    return days < 0 ? 0 : days ~/ 7;
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Emergency Info', style: TextStyle(color: context.text)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          _label('Gender'),
          _ReadOnlyField(
            icon: _gender == 'female'
                ? Icons.female_rounded
                : Icons.male_rounded,
            text: _gender == 'female' ? 'Female' : 'Male',
            note: 'From your account',
          ),
          const SizedBox(height: 18),

          _label('Date of Birth'),
          _ReadOnlyField(
            icon: Icons.cake_rounded,
            text: _dateOfBirth == null
                ? 'Not set'
                : '${_formatDate(_dateOfBirth!)}  (${_ageFromDate(_dateOfBirth!)} yrs)',
            note: 'From your account',
          ),
          const SizedBox(height: 18),

          _label('Blood Type'),
          DropdownButtonFormField<String>(
            value: _bloodType,
            isExpanded: true,
            decoration: _fieldDecoration(context, hint: 'Select blood type'),
            items: _bloodTypes
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _bloodType = v),
          ),
          const SizedBox(height: 18),

          _label('Height & Weight'),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _heightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _fieldDecoration(context, hint: 'Height (cm)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _fieldDecoration(context, hint: 'Weight (kg)'),
              ),
            ),
          ]),
          const SizedBox(height: 18),

          _ChipInput(
            title: 'Allergies',
            hint: 'Add an allergy',
            values: _allergies,
            accent: AppColors.warning,
            onChanged: (v) => setState(() => _allergies = v),
          ),
          const SizedBox(height: 18),

          _ChipInput(
            title: 'Chronic Conditions',
            hint: 'Add a condition',
            values: _conditions,
            accent: AppColors.error,
            onChanged: (v) => setState(() => _conditions = v),
          ),
          const SizedBox(height: 18),

          _label('Current Medications'),
          ..._medications.asMap().entries.map((e) => _medicationTile(e.key, e.value)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addMedication,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Medication'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),

          _ChipInput(
            title: 'Medical Devices',
            hint: 'Add a device (e.g. Pacemaker)',
            values: _devices,
            accent: AppColors.primary,
            onChanged: (v) => setState(() => _devices = v),
          ),
          const SizedBox(height: 18),

          _label('Organ Donor'),
          _switchTile(
            title: 'Registered organ donor',
            value: _organDonor,
            onChanged: (v) => setState(() => _organDonor = v),
          ),
          const SizedBox(height: 18),

          _label('Smoking'),
          _switchTile(
            title: 'Smoker',
            value: _smoker,
            onChanged: (v) => setState(() => _smoker = v),
          ),
          const SizedBox(height: 18),

          if (_gender == 'female') ...[
            _label('Pregnancy'),
            _switchTile(
              title: 'Currently pregnant',
              value: _isPregnant,
              onChanged: (v) => setState(() => _isPregnant = v),
            ),
            if (_isPregnant) ...[
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickPregnancyDate,
                child: InputDecorator(
                  decoration: _fieldDecoration(context),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _pregnancyStartDate == null
                          ? 'Pick first day of last period'
                          : _formatDate(_pregnancyStartDate!),
                      style: TextStyle(
                        color: _pregnancyStartDate == null
                            ? AppColors.grey
                            : context.text,
                      ),
                    ),
                  ]),
                ),
              ),
              if (_pregnancyStartDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  '≈ ${_weeksFromDate(_pregnancyStartDate!)} weeks pregnant',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ],
            const SizedBox(height: 18),
          ],

          _label('Primary Language'),
          TextFormField(
            controller: _languageCtrl,
            decoration: _fieldDecoration(context, hint: 'e.g. Arabic'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving…' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                color: context.text,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      );

  Widget _medicationTile(int index, MedicationModel m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divider),
      ),
      child: Row(children: [
        const Icon(Icons.medication_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name,
                  style: TextStyle(
                      color: context.text, fontWeight: FontWeight.w600)),
              if (m.detail.isNotEmpty)
                Text(m.detail,
                    style: const TextStyle(color: AppColors.grey, fontSize: 12.5)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.grey, size: 20),
          onPressed: () => setState(() => _medications.removeAt(index)),
        ),
      ]),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divider),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.primary,
        title: Text(title, style: TextStyle(color: context.text, fontSize: 14)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.grey),
    filled: true,
    fillColor: context.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.divider),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
  );
}

// ─── Read-only field (e.g. account gender) ───────────────────────────────────
class _ReadOnlyField extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? note;
  const _ReadOnlyField({required this.icon, required this.text, this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: context.isDark ? context.card : AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divider),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.grey),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: context.text, fontWeight: FontWeight.w600)),
        ),
        const Spacer(),
        if (note != null)
          Row(children: [
            const Icon(Icons.lock_outline_rounded,
                size: 14, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(note!,
                style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          ]),
      ]),
    );
  }
}

// ─── Chip input (add / remove list of strings) ────────────────────────────────
class _ChipInput extends StatefulWidget {
  final String title;
  final String hint;
  final List<String> values;
  final Color accent;
  final ValueChanged<List<String>> onChanged;

  const _ChipInput({
    required this.title,
    required this.hint,
    required this.values,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<_ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<_ChipInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (widget.values.any((v) => v.toLowerCase() == text.toLowerCase())) {
      _ctrl.clear();
      return;
    }
    widget.onChanged([...widget.values, text]);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title,
            style: TextStyle(
                color: context.text,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
              decoration: _fieldDecoration(context, hint: widget.hint),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 50,
            width: 50,
            child: ElevatedButton(
              onPressed: _add,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ]),
        if (widget.values.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.values
                .map((v) => Chip(
                      label: Text(v),
                      labelStyle: TextStyle(color: context.text),
                      backgroundColor: widget.accent.withOpacity(0.12),
                      side: BorderSide(color: widget.accent.withOpacity(0.4)),
                      deleteIconColor: AppColors.grey,
                      onDeleted: () => widget
                          .onChanged(widget.values.where((x) => x != v).toList()),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Add-medication dialog ────────────────────────────────────────────────────
class _MedicationDialog extends StatefulWidget {
  const _MedicationDialog();

  @override
  State<_MedicationDialog> createState() => _MedicationDialogState();
}

class _MedicationDialogState extends State<_MedicationDialog> {
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _freq = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _freq.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      MedicationModel(
        name: name,
        dose: _dose.text.trim(),
        frequency: _freq.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Text('Add Medication',
                style: TextStyle(
                    color: context.text,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: _fieldDecoration(context, hint: 'Name (e.g. Metformin)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dose,
              decoration: _fieldDecoration(context, hint: 'Dose (e.g. 500 mg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _freq,
              decoration:
                  _fieldDecoration(context, hint: 'Frequency (e.g. Twice Daily)'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
