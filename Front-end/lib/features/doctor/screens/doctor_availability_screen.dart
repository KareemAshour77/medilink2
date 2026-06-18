import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/availability_service.dart';

/// Doctor sets the weekly availability template that drives patient booking
/// slots (working days, hours, slot length, optional break).
class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  // Backend weekday tokens (lowercase). Display labels alongside.
  static const _days = [
    ('saturday', 'Sat'),
    ('sunday', 'Sun'),
    ('monday', 'Mon'),
    ('tuesday', 'Tue'),
    ('wednesday', 'Wed'),
    ('thursday', 'Thu'),
    ('friday', 'Fri'),
  ];

  final Set<String> _workDays = {};
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  int _slotMinutes = 30;
  bool _hasBreak = false;
  TimeOfDay _breakStart = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _breakEnd = const TimeOfDay(hour: 14, minute: 0);

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final a = await AvailabilityService.getMine();
      if (!mounted) return;
      if (a != null) {
        setState(() {
          _workDays
            ..clear()
            ..addAll(((a['work_days'] as List?) ?? []).map((e) => e.toString()));
          _start = _parse(a['start_time'] as String?) ?? _start;
          _end = _parse(a['end_time'] as String?) ?? _end;
          _slotMinutes = (a['slot_minutes'] as int?) ?? 30;
          final bs = _parse(a['break_start'] as String?);
          final be = _parse(a['break_end'] as String?);
          if (bs != null && be != null) {
            _hasBreak = true;
            _breakStart = bs;
            _breakEnd = be;
          }
        });
      }
    } catch (_) {
      // first-time setup — keep defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TimeOfDay? _parse(String? hhmm) {
    if (hhmm == null || !hhmm.contains(':')) return null;
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _save() async {
    if (_workDays.isEmpty) {
      AppSnackBar.show(context, 'Pick at least one working day.');
      return;
    }
    if (_mins(_start) >= _mins(_end)) {
      AppSnackBar.show(context, 'Start time must be before end time.');
      return;
    }
    if (_hasBreak && _mins(_breakStart) >= _mins(_breakEnd)) {
      AppSnackBar.show(context, 'Break start must be before break end.');
      return;
    }
    setState(() => _saving = true);
    try {
      await AvailabilityService.setMine(
        workDays: _workDays.toList(),
        startTime: _fmt(_start),
        endTime: _fmt(_end),
        slotMinutes: _slotMinutes,
        breakStart: _hasBreak ? _fmt(_breakStart) : null,
        breakEnd: _hasBreak ? _fmt(_breakEnd) : null,
      );
      if (!mounted) return;
      AppSnackBar.show(context, context.l.availabilitySaved,
          backgroundColor: AppColors.primary);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pick(TimeOfDay current, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.availability, style: TextStyle(color: context.text)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _label(context.l.workingDays),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _days.map((d) {
                    final sel = _workDays.contains(d.$1);
                    return GestureDetector(
                      onTap: () => setState(() {
                        sel ? _workDays.remove(d.$1) : _workDays.add(d.$1);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel ? RoleTheme.doctor : context.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? RoleTheme.doctor : context.divider),
                        ),
                        child: Text(d.$2,
                            style: TextStyle(
                                color: sel ? Colors.white : context.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                _label(context.l.workingHours),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _timeTile(context.l.startLabel, _start,
                      () => _pick(_start, (t) => setState(() => _start = t)))),
                  const SizedBox(width: 12),
                  Expanded(child: _timeTile(context.l.endLabel, _end,
                      () => _pick(_end, (t) => setState(() => _end = t)))),
                ]),
                const SizedBox(height: 22),
                _label(context.l.slotDuration),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [15, 20, 30, 45, 60].map((m) {
                    final sel = _slotMinutes == m;
                    return ChoiceChip(
                      label: Text('$m min'),
                      selected: sel,
                      onSelected: (_) => setState(() => _slotMinutes = m),
                      selectedColor: RoleTheme.doctor,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : context.text),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l.dailyBreak),
                  value: _hasBreak,
                  activeColor: RoleTheme.doctor,
                  onChanged: (v) => setState(() => _hasBreak = v),
                ),
                if (_hasBreak)
                  Row(children: [
                    Expanded(child: _timeTile(context.l.breakStart, _breakStart,
                        () => _pick(_breakStart, (t) => setState(() => _breakStart = t)))),
                    const SizedBox(width: 12),
                    Expanded(child: _timeTile(context.l.breakEnd, _breakEnd,
                        () => _pick(_breakEnd, (t) => setState(() => _breakEnd = t)))),
                  ]),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: RoleTheme.doctor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(context.l.saveAvailability,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(
          color: context.text, fontSize: 15, fontWeight: FontWeight.w700));

  Widget _timeTile(String label, TimeOfDay value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.divider),
        ),
        child: Row(children: [
          const Icon(Icons.access_time_rounded, color: RoleTheme.doctor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
              const SizedBox(height: 2),
              Text(_fmt(value),
                  style: TextStyle(
                      color: context.text, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    );
  }
}
