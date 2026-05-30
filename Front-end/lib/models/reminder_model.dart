import 'package:flutter/material.dart';

import 'medicine_form.dart';

export 'medicine_form.dart';

enum ReminderType { medicine, doctor }

enum MealRelation { before, after, withFood, anytime }

enum Priority { high, normal, low }

class ReminderModel {
  final String id;
  final String name;
  final ReminderType type;
  final MedicineForm? form;
  final MealRelation? mealRelation;
  final Priority priority;
  final double dose;
  final Color color;
  final TimeOfDay time;
  final DateTime startDate;
  final DateTime? endDate;

  /// 7 entries: index 0 = Saturday, index 6 = Friday.
  final List<bool> weekDays;
  bool taken;
  bool eaten;

  ReminderModel({
    required this.id,
    required this.name,
    required this.type,
    this.form,
    this.mealRelation,
    required this.priority,
    required this.dose,
    required this.color,
    required this.time,
    required this.startDate,
    this.endDate,
    required this.weekDays,
    this.taken = false,
    this.eaten = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'form': form?.dbValue,
        'mealRelation': mealRelation?.name,
        'priority': priority.name,
        'dose': dose,
        'color': color.value,
        'timeHour': time.hour,
        'timeMinute': time.minute,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'weekDays': weekDays,
        'taken': taken,
        'eaten': eaten,
      };

  factory ReminderModel.fromJson(Map<String, dynamic> j) {
    final type =
        _parseEnum(ReminderType.values, j['type']) ?? ReminderType.medicine;

    return ReminderModel(
      id: _str(j['id']) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _str(j['name']) ?? '',
      type: type,
      form: type == ReminderType.medicine
          ? MedicineFormParser.parseOrFallback(j['form'])
          : null,
      mealRelation: _parseEnum(MealRelation.values, j['mealRelation']),
      priority: _parseEnum(Priority.values, j['priority']) ?? Priority.normal,
      dose: (j['dose'] as num?)?.toDouble() ?? 1.0,
      color: Color((j['color'] as int?) ?? 0xFF6750A4),
      time: TimeOfDay(
        hour: (j['timeHour'] as int?) ?? 8,
        minute: (j['timeMinute'] as int?) ?? 0,
      ),
      startDate: _parseDate(j['startDate']) ?? DateTime.now(),
      endDate: _parseDate(j['endDate']),
      weekDays: _parseBoolList(j['weekDays']),
      taken: (j['taken'] as bool?) ?? false,
      eaten: (j['eaten'] as bool?) ?? false,
    );
  }

  static MedicineForm? parseMedicineForm(dynamic raw) =>
      MedicineFormParser.tryParse(raw);

  static MedicineForm parseMedicineFormOrFallback(dynamic raw) =>
      MedicineFormParser.parseOrFallback(raw);

  static String? medicineFormToApi(MedicineForm? form) => form?.dbValue;

  ReminderModel copyWith({
    String? id,
    String? name,
    ReminderType? type,
    MedicineForm? form,
    MealRelation? mealRelation,
    Priority? priority,
    double? dose,
    Color? color,
    TimeOfDay? time,
    DateTime? startDate,
    DateTime? endDate,
    List<bool>? weekDays,
    bool? taken,
    bool? eaten,
  }) =>
      ReminderModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        form: form ?? this.form,
        mealRelation: mealRelation ?? this.mealRelation,
        priority: priority ?? this.priority,
        dose: dose ?? this.dose,
        color: color ?? this.color,
        time: time ?? this.time,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        weekDays: weekDays ?? List<bool>.from(this.weekDays),
        taken: taken ?? this.taken,
        eaten: eaten ?? this.eaten,
      );

  static T? _parseEnum<T extends Enum>(List<T> values, dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      return (raw >= 0 && raw < values.length) ? values[raw] : null;
    }

    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    final sLower = s.toLowerCase();
    final sStripped = sLower.replaceAll(RegExp(r'[^a-z0-9]'), '');

    try {
      return values.firstWhere((e) => e.name == s);
    } catch (_) {}

    try {
      return values.firstWhere((e) => e.name.toLowerCase() == sLower);
    } catch (_) {}

    try {
      return values.firstWhere(
        (e) =>
            e.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
            sStripped,
      );
    } catch (_) {}

    debugPrint('_parseEnum: no match for "$s" in ${values.runtimeType}');
    return null;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  static String? _str(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  static List<bool> _parseBoolList(dynamic raw) {
    if (raw == null) return List.filled(7, true);
    try {
      final list = (raw as List<dynamic>).map((e) => e == true).toList();
      while (list.length < 7) {
        list.add(true);
      }
      return list.sublist(0, 7);
    } catch (_) {
      return List.filled(7, true);
    }
  }
}
