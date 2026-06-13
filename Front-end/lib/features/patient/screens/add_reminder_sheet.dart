import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../models/reminder_model.dart';
import '../../../core/theme/app_theme.dart';

class AddReminderSheet extends StatefulWidget {
  final ReminderModel? existing;
  const AddReminderSheet({super.key, this.existing});

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  final _nameCtrl = TextEditingController();

  ReminderType _type = ReminderType.medicine;
  MedicineForm _form = MedicineForm.tablets;
  Priority _priority = Priority.normal;
  double _dose = 1.0;
  Color _color = AppColors.primary;

  // Multiple intakes per day: each has its own time + meal + taken state.
  List<DoseTime> _doseTimes = [];

  DateTime _start = DateTime.now();
  DateTime? _end;
  List<bool> _days = List.filled(7, true);

  bool _nameTouched = false;

  // ── Static form definitions ──────────────────────────────────────────────
  List<(MedicineForm, String, String)> _forms(BuildContext ctx) => [
        (MedicineForm.tablets, ctx.l.tablets, 'assets/images/tablets.png'),
        (MedicineForm.capsules, ctx.l.capsules, 'assets/images/capsule.png'),
        (MedicineForm.syrups, ctx.l.syrups, 'assets/images/syrup.png'),
        (MedicineForm.dropsEye, ctx.l.dropsEye, 'assets/images/drops.png'),
        (MedicineForm.dropsEar, ctx.l.dropsEar, 'assets/images/drops.png'),
        (MedicineForm.dropsNasal, ctx.l.dropsNasal, 'assets/images/drops.png'),
        (MedicineForm.injection, ctx.l.injections, 'assets/images/injection.png'),
        (MedicineForm.inhaler, ctx.l.inhalers, 'assets/images/inhaler.png'),
        (MedicineForm.cream, ctx.l.creamsOintmentsGel, 'assets/images/cream.png'),
        (MedicineForm.powder, ctx.l.powders, 'assets/images/effervescent.png'),
        (MedicineForm.suppository, ctx.l.suppositories, 'assets/images/suppository.png'),
        (MedicineForm.lozenge, ctx.l.lozenges, 'assets/images/lozenge.png'),
        (MedicineForm.sublingual, ctx.l.sublingualTablets, 'assets/images/Sublingual.png'),
      ];

  List<String> _dayLabels(BuildContext ctx) => [
        ctx.l.sat,
        ctx.l.sun,
        ctx.l.mon,
        ctx.l.tue,
        ctx.l.wed,
        ctx.l.thu,
        ctx.l.fri,
      ];

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    if (r != null) {
      _nameCtrl.text = r.name;
      _type = r.type;
      _form = r.form ?? MedicineFormParser.fallback;
      _priority = r.priority;
      _dose = r.dose;
      _color = r.color;
      _doseTimes = r.doseTimes
          .map((d) => DoseTime(time: d.time, meal: d.meal, taken: d.taken))
          .toList();
      _start = r.startDate;
      _end = r.endDate;
      _days = List<bool>.from(r.weekDays);
    }
    if (_doseTimes.isEmpty) {
      _doseTimes = [DoseTime(time: TimeOfDay.now(), meal: MealRelation.afterBreakfast)];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Formatters / validation ─────────────────────────────────────────────────

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period.name.toUpperCase()}';
  }

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _days.any((d) => d) &&
      _doseTimes.isNotEmpty;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header + close
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null
                          ? context.l.newReminder
                          : context.l.editReminder,
                      style: TextStyle(
                        color: context.text,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: context.text),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Type ──────────────────────────────────────
              _section(Icons.category_outlined, context.l.type, Row(children: [
                _typeBtn(ReminderType.medicine, context.l.medicine),
                const SizedBox(width: 10),
                _typeBtn(ReminderType.doctor, context.l.docicon),
              ])),

              // ── Name ──────────────────────────────────────
              _section(
                Icons.edit_outlined,
                context.l.nameMedi,
                TextField(
                  controller: _nameCtrl,
                  style: TextStyle(color: context.text),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: _type == ReminderType.medicine
                        ? 'e.g. Panadol Extra'
                        : 'e.g. Dr. Johnson',
                    hintStyle: const TextStyle(color: AppColors.grey),
                    errorText: _nameTouched && _nameCtrl.text.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                ),
              ),

              // ── Medicine-only: form / dose ────────────────
              if (_type == ReminderType.medicine) ...[
                _section(Icons.medication_outlined, context.l.form, _formPicker()),
                _section(Icons.scale_outlined, context.l.dosePerIntake, _dosePicker()),
              ],

              // ── Schedule (multi-time) ─────────────────────
              _section(Icons.schedule_outlined, 'Schedule', _scheduleSection()),

              // ── Priority (medicine) ───────────────────────
              if (_type == ReminderType.medicine)
                _section(Icons.flag_outlined, context.l.priority, Row(children: [
                  _priorityBtn(Priority.high, context.l.high),
                  const SizedBox(width: 8),
                  _priorityBtn(Priority.normal, context.l.normal),
                  const SizedBox(width: 8),
                  _priorityBtn(Priority.low, context.l.low),
                ])),

              // ── Color ─────────────────────────────────────
              _section(Icons.palette_outlined, context.l.color, _colorRow()),

              // ── Days ──────────────────────────────────────
              _section(Icons.event_repeat_outlined, context.l.repeatOn, _daysRow()),

              // ── Duration ──────────────────────────────────
              _section(Icons.date_range_outlined, context.l.duration,
                  _durationRow(isArabic)),

              const SizedBox(height: 8),

              // ── Save ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _valid ? _color : AppColors.grey.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _valid ? _save : _onInvalidTap,
                  child: Text(
                    widget.existing == null
                        ? context.l.addReminder
                        : context.l.saveChanges,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section card ────────────────────────────────────────────────────────────

  Widget _section(IconData icon, String label, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: context.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── Schedule section: dose-time rows + add button ────────────────────────────

  Widget _scheduleSection() {
    return Column(
      children: [
        for (var i = 0; i < _doseTimes.length; i++) _doseRow(i),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _doseTimes.add(
                  DoseTime(time: TimeOfDay.now(), meal: MealRelation.afterBreakfast),
                )),
            icon: Icon(Icons.add_circle_outline_rounded, color: _color, size: 20),
            label: Text(
              _type == ReminderType.medicine ? 'Add another time' : 'Add time',
              style: TextStyle(color: _color, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _doseRow(int i) {
    final slot = _doseTimes[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        // Time pill
        GestureDetector(
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: slot.time,
              initialEntryMode: TimePickerEntryMode.input,
            );
            if (t != null) {
              setState(() => _doseTimes[i] = slot.copyWith(time: t));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(Icons.access_time_outlined, color: _color, size: 16),
              const SizedBox(width: 6),
              Text(_fmtTime(slot.time),
                  style: TextStyle(
                      color: _color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(width: 10),

        // Meal relation (medicine only)
        if (_type == ReminderType.medicine)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MealRelation>(
                  isExpanded: true,
                  value: slot.meal,
                  dropdownColor: context.card,
                  iconEnabledColor: _color,
                  style: TextStyle(color: context.text, fontSize: 13),
                  items: MealRelation.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.label,
                                style: TextStyle(
                                    color: context.text, fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (m) {
                    if (m != null) {
                      setState(() => _doseTimes[i] = slot.copyWith(meal: m));
                    }
                  },
                ),
              ),
            ),
          )
        else
          const Spacer(),

        // Remove row (only when more than one)
        if (_doseTimes.length > 1)
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: AppColors.grey, size: 20),
            onPressed: () => setState(() => _doseTimes.removeAt(i)),
          ),
      ]),
    );
  }

  // ── Pickers (extracted from the old inline build) ────────────────────────────

  Widget _formPicker() {
    final forms = _forms(context);
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forms.length,
        itemBuilder: (_, i) {
          final f = forms[i];
          final sel = _form == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _form = f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _color : _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Image.asset(f.$3,
                    width: 15, height: 15, color: sel ? Colors.white : _color),
                const SizedBox(width: 6),
                Text(f.$2,
                    style: TextStyle(
                      color: sel ? Colors.white : _color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _dosePicker() {
    return Row(
      children: [0.5, 1.0, 1.5, 2.0, 3.0].map((d) {
        final sel = _dose == d;
        final label = d == 0.5
            ? '½'
            : d == 1.5
                ? '1½'
                : d == d.truncateToDouble()
                    ? d.toInt().toString()
                    : d.toString();
        return GestureDetector(
          onTap: () => setState(() => _dose = d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            width: 54,
            height: 46,
            decoration: BoxDecoration(
              color: sel ? _color : _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                  color: sel ? Colors.white : _color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
          ),
        );
      }).toList(),
    );
  }

  Widget _colorRow() {
    return GestureDetector(
      onTap: _pickColor,
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border:
                Border.all(color: AppColors.grey.withOpacity(0.3), width: 2),
          ),
        ),
        const SizedBox(width: 12),
        Text(context.l.tapToChangeColor,
            style: TextStyle(color: context.text, fontSize: 14)),
      ]),
    );
  }

  Widget _daysRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final sel = _days[i];
        return GestureDetector(
          onTap: () => setState(() => _days[i] = !_days[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: sel ? _color : _color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _dayLabels(context)[i],
              style: TextStyle(
                color: sel ? Colors.white : _color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _durationRow(bool isArabic) {
    return Row(children: [
      Expanded(
        child: _infoTile(
          icon: Icons.play_circle_outline,
          label: context.l.start(_fmt(_start)),
          color: _color,
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _start,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) setState(() => _start = d);
          },
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _infoTile(
          icon: Icons.stop_circle_outlined,
          label: _end != null
              ? (isArabic ? 'النهاية: ${_fmt(_end!)}' : 'End: ${_fmt(_end!)}')
              : (isArabic ? 'لا يوجد تاريخ انتهاء' : 'No end date'),
          color: _color,
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _end ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: _start,
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (d != null) setState(() => _end = d);
          },
        ),
      ),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _typeBtn(ReminderType t, String label) {
    final sel = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                color: sel ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
        ),
      ),
    );
  }

  Widget _priorityBtn(Priority p, String label) {
    final sel = _priority == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? _color : _color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                color: sel ? Colors.white : _color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ]),
      ),
    );
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.bg,
        title: Text(context.l.pickAColor, style: TextStyle(color: context.text)),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _color,
            onColorChanged: (c) => setState(() => _color = c),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l.doneTick),
          ),
        ],
      ),
    );
  }

  void _onInvalidTap() {
    setState(() => _nameTouched = true);
  }

  // ── Save / pop ────────────────────────────────────────────────────────────

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameTouched = true);
      return;
    }

    final r = ReminderModel(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: _type,
      form: _type == ReminderType.medicine ? _form : null,
      priority: _priority,
      dose: _dose,
      color: _color,
      doseTimes: _doseTimes
          .map((d) => DoseTime(time: d.time, meal: d.meal, taken: d.taken))
          .toList(),
      startDate: _start,
      endDate: _end,
      weekDays: List<bool>.from(_days),
      eaten: widget.existing?.eaten ?? false,
    );

    Navigator.pop(context, r);
  }
}
