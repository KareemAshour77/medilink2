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
  // Use _form directly for selection — no separate _formIndex that can
  // drift out of sync when editing an existing reminder.
  MedicineForm _form = MedicineForm.tablets;
  MealRelation _meal = MealRelation.after;
  Priority _priority = Priority.normal;
  double _dose = 1.0;
  Color _color = AppColors.primary;
  TimeOfDay _time = TimeOfDay.now();
  DateTime _start = DateTime.now();
  DateTime? _end;
  List<bool> _days = List.filled(7, true);

  // ── Static form definitions ──────────────────────────────────────────────
  // Built once per build so context-dependent labels stay reactive.
  List<(MedicineForm, String, String)> _forms(BuildContext ctx) => [
        (MedicineForm.tablets, ctx.l.tablets, 'assets/images/tablets.png'),
        (MedicineForm.capsules, ctx.l.capsules, 'assets/images/capsule.png'),
        (MedicineForm.syrups, ctx.l.syrups, 'assets/images/syrup.png'),
        (MedicineForm.dropsEye, ctx.l.dropsEye, 'assets/images/drops.png'),
        (MedicineForm.dropsEar, ctx.l.dropsEar, 'assets/images/drops.png'),
        (MedicineForm.dropsNasal, ctx.l.dropsNasal, 'assets/images/drops.png'),
        (MedicineForm.injection, ctx.l.injections, 'assets/images/injection.png'),
        (MedicineForm.inhaler, ctx.l.inhalers, 'assets/images/inhaler.png'),
        (MedicineForm.cream,ctx.l.creamsOintmentsGel,'assets/images/cream.png'),
        (MedicineForm.powder, ctx.l.powders, 'assets/images/effervescent.png'),
        (MedicineForm.suppository,ctx.l.suppositories,'assets/images/suppository.png'),
        (MedicineForm.lozenge, ctx.l.lozenges, 'assets/images/lozenge.png'),
        (MedicineForm.sublingual, ctx.l.sublingualTablets,'assets/images/Sublingual.png'),
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
      _form = r.form ?? MedicineFormParser.fallback; // safe fallback
      _meal = r.mealRelation ?? MealRelation.after;
      _priority = r.priority;
      _dose = r.dose;
      _color = r.color;
      _time = r.time;
      _start = r.startDate;
      _end = r.endDate;
      _days = List<bool>.from(r.weekDays);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Formatters ────────────────────────────────────────────────────────────

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period.name.toUpperCase()}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final forms = _forms(context);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle bar ────────────────────────────────
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
              const SizedBox(height: 16),

              Text(
                widget.existing == null
                    ? context.l.newReminder
                    : context.l.editReminder,
                style: TextStyle(
                  color: context.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // ── 1. Type ───────────────────────────────────
              _sectionLabel(context.l.type),
              Row(children: [
                _typeBtn(ReminderType.medicine, context.l.medicine),
                const SizedBox(width: 10),
                _typeBtn(ReminderType.doctor, context.l.docicon),
              ]),
              const SizedBox(height: 16),

              // ── 2. Name ───────────────────────────────────
              _sectionLabel(context.l.nameMedi),
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: context.text),
                decoration: InputDecoration(
                  hintText: _type == ReminderType.medicine
                      ? 'e.g. Panadol Extra'
                      : 'e.g. Dr. Johnson',
                  hintStyle: const TextStyle(color: AppColors.grey),
                ),
              ),
              const SizedBox(height: 16),

              // ── Medicine-only fields ───────────────────────
              if (_type == ReminderType.medicine) ...[
                // Form picker — uses _form enum value directly, no index drift.
                _sectionLabel(context.l.form),
                SizedBox(
                  height: 46,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: forms.length,
                    itemBuilder: (_, i) {
                      final f = forms[i];
                      final sel = _form == f.$1; // compare by enum, not index
                      return GestureDetector(
                        onTap: () => setState(() => _form = f.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? _color : _color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            Image.asset(f.$3,
                                width: 15,
                                height: 15,
                                color: sel ? Colors.white : _color),
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
                ),
                const SizedBox(height: 16),

                // Dose picker
                _sectionLabel(context.l.dosePerIntake),
                Row(
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
                ),
                const SizedBox(height: 16),

                // Meal relation
                _sectionLabel(context.l.takeIt),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _mealBtn(MealRelation.before, context.l.beforeMeal),
                  _mealBtn(MealRelation.after, context.l.afterMeal),
                  _mealBtn(MealRelation.withFood, context.l.withFood),
                  _mealBtn(MealRelation.anytime, context.l.anytime),
                ]),
                const SizedBox(height: 16),

                // Priority
                _sectionLabel(context.l.priority),
                Row(children: [
                  _priorityBtn(Priority.high, context.l.high),
                  const SizedBox(width: 8),
                  _priorityBtn(Priority.normal, context.l.normal),
                  const SizedBox(width: 8),
                  _priorityBtn(Priority.low, context.l.low),
                ]),
                const SizedBox(height: 16),
              ],

              // ── 3. Color ──────────────────────────────────
              _sectionLabel(context.l.color),
              GestureDetector(
                onTap: _pickColor,
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _color,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.grey.withOpacity(0.3), width: 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(context.l.tapToChangeColor,
                      style: TextStyle(color: context.text, fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 16),

              // ── 4. Time ───────────────────────────────────
              _sectionLabel(context.l.reminderTime),
              _infoTile(
                icon: Icons.access_time_outlined,
                label: _fmtTime(_time),
                color: _color,
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _time,
                    initialEntryMode: TimePickerEntryMode.input,
                  );

                  if (t != null) {
                    setState(() => _time = t);
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── 5. Days of the week ───────────────────────
              _sectionLabel(context.l.repeatOn),
              Row(
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
              ),
              const SizedBox(height: 16),

              // ── 6. Start / End dates ──────────────────────
              _sectionLabel(context.l.duration),
              Row(children: [
                Expanded(
                  child: _infoTile(
                    icon: Icons.play_circle_outline,
                    label: context.l.start(_fmt(_start)),
                    color: _color,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _start,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 1)),
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
                        ? (isArabic
                            ? 'النهاية: ${_fmt(_end!)}'
                            : 'End: ${_fmt(_end!)}')
                        : (isArabic ? 'لا يوجد تاريخ انتهاء' : 'No end date'),
                    color: _color,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _end ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: _start,
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (d != null) setState(() => _end = d);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 28),

              // ── Save button ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _save,
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
              color: context.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            )),
      );

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

  Widget _mealBtn(MealRelation m, String label) {
    final sel = _meal == m;
    return GestureDetector(
      onTap: () => setState(() => _meal = m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? _color : _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: sel ? Colors.white : _color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
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
        title:
            Text(context.l.pickAColor, style: TextStyle(color: context.text)),
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

  // ── Save / pop ────────────────────────────────────────────────────────────

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final r = ReminderModel(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: _type,
      form: _type == ReminderType.medicine ? _form : null,
      mealRelation: _type == ReminderType.medicine ? _meal : null,
      priority: _priority,
      dose: _dose,
      color: _color,
      time: _time,
      startDate: _start,
      endDate: _end,
      weekDays: List<bool>.from(_days),
      // Preserve taken/eaten from the existing entry — the tab will merge them.
      taken: widget.existing?.taken ?? false,
      eaten: widget.existing?.eaten ?? false,
    );

    Navigator.pop(context, r);
  }
}
