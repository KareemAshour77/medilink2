import 'package:flutter/material.dart';

import 'medicine_form.dart';

export 'medicine_form.dart';

enum ReminderType { medicine, doctor }

enum MealRelation {
  beforeBreakfast,
  afterBreakfast,
  beforeLunch,
  afterLunch,
  beforeDinner,
  afterDinner,
  withFood,
  anytime,
}

extension MealRelationX on MealRelation {
  /// English label for the picker / hints (avoids editing the 7 .arb files).
  String get label {
    switch (this) {
      case MealRelation.beforeBreakfast:
        return 'Before breakfast';
      case MealRelation.afterBreakfast:
        return 'After breakfast';
      case MealRelation.beforeLunch:
        return 'Before lunch';
      case MealRelation.afterLunch:
        return 'After lunch';
      case MealRelation.beforeDinner:
        return 'Before dinner';
      case MealRelation.afterDinner:
        return 'After dinner';
      case MealRelation.withFood:
        return 'With food';
      case MealRelation.anytime:
        return 'Anytime';
    }
  }

  /// Backend `take_it` enum value, or null for generic relations that the enum
  /// can't store (kept only inside the dose_times JSON).
  String? get takeItValue {
    switch (this) {
      case MealRelation.beforeBreakfast:
        return 'before_breakfast';
      case MealRelation.afterBreakfast:
        return 'after_breakfast';
      case MealRelation.beforeLunch:
        return 'before_lunch';
      case MealRelation.afterLunch:
        return 'after_lunch';
      case MealRelation.beforeDinner:
        return 'before_dinner';
      case MealRelation.afterDinner:
        return 'after_dinner';
      case MealRelation.withFood:
      case MealRelation.anytime:
        return null;
    }
  }

  static MealRelation fromTakeIt(String? v) {
    switch (v) {
      case 'before_breakfast':
        return MealRelation.beforeBreakfast;
      case 'after_breakfast':
        return MealRelation.afterBreakfast;
      case 'before_lunch':
        return MealRelation.beforeLunch;
      case 'after_lunch':
        return MealRelation.afterLunch;
      case 'before_dinner':
        return MealRelation.beforeDinner;
      case 'after_dinner':
        return MealRelation.afterDinner;
      case 'with_food':
      case 'withFood':
        return MealRelation.withFood;
      case 'anytime':
        return MealRelation.anytime;
      // Legacy generic values from the old enum.
      case 'before':
        return MealRelation.beforeBreakfast;
      case 'after':
        return MealRelation.afterBreakfast;
      default:
        return MealRelation.afterBreakfast;
    }
  }
}

enum Priority { high, normal, low }

/// One scheduled intake: a time, its meal relation, and whether it was taken.
class DoseTime {
  final TimeOfDay time;
  final MealRelation meal;
  bool taken;

  DoseTime({required this.time, required this.meal, this.taken = false});

  DoseTime copyWith({TimeOfDay? time, MealRelation? meal, bool? taken}) =>
      DoseTime(
        time: time ?? this.time,
        meal: meal ?? this.meal,
        taken: taken ?? this.taken,
      );

  String get timeString =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'time': timeString,
        'take_it': meal.takeItValue ?? meal.name,
        'taken': taken,
      };

  factory DoseTime.fromJson(Map<String, dynamic> j) {
    final parts = ((j['time'] as String?) ?? '08:00').split(':');
    return DoseTime(
      time: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
      meal: MealRelationX.fromTakeIt(j['take_it']?.toString()),
      taken: (j['taken'] as bool?) ?? false,
    );
  }
}

class ReminderModel {
  final String id;
  final String name;
  final ReminderType type;
  final MedicineForm? form;
  final Priority priority;
  final double dose;
  final Color color;

  /// One or more scheduled intakes (time + meal + taken). Always non-empty.
  final List<DoseTime> doseTimes;

  final DateTime startDate;
  final DateTime? endDate;

  /// 7 entries: index 0 = Saturday, index 6 = Friday.
  final List<bool> weekDays;
  bool eaten;

  ReminderModel({
    required this.id,
    required this.name,
    required this.type,
    this.form,
    required this.priority,
    required this.dose,
    required this.color,
    required this.doseTimes,
    required this.startDate,
    this.endDate,
    required this.weekDays,
    this.eaten = false,
  });

  // ── Convenience (first slot / aggregate) — keeps older call sites working ──
  TimeOfDay get time =>
      doseTimes.isNotEmpty ? doseTimes.first.time : const TimeOfDay(hour: 8, minute: 0);
  MealRelation? get mealRelation =>
      doseTimes.isNotEmpty ? doseTimes.first.meal : null;
  bool get allTaken => doseTimes.isNotEmpty && doseTimes.every((d) => d.taken);
  int get takenSlots => doseTimes.where((d) => d.taken).length;
  int get slotCount => doseTimes.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'form': form?.dbValue,
        'priority': priority.name,
        'dose': dose,
        'color': color.value,
        'doseTimes': doseTimes.map((d) => d.toJson()).toList(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'weekDays': weekDays,
        'eaten': eaten,
      };

  factory ReminderModel.fromJson(Map<String, dynamic> j) {
    final type =
        _parseEnum(ReminderType.values, j['type']) ?? ReminderType.medicine;

    // Parse the dose-time slots; fall back to a single legacy slot.
    List<DoseTime> slots = [];
    final raw = j['doseTimes'];
    if (raw is List) {
      slots = raw
          .whereType<Map>()
          .map((e) => DoseTime.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (slots.isEmpty) {
      slots = [
        DoseTime(
          time: TimeOfDay(
            hour: (j['timeHour'] as int?) ?? 8,
            minute: (j['timeMinute'] as int?) ?? 0,
          ),
          meal: MealRelationX.fromTakeIt(j['mealRelation']?.toString()),
          taken: (j['taken'] as bool?) ?? false,
        ),
      ];
    }

    return ReminderModel(
      id: _str(j['id']) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _str(j['name']) ?? '',
      type: type,
      form: type == ReminderType.medicine
          ? MedicineFormParser.parseOrFallback(j['form'])
          : null,
      priority: _parseEnum(Priority.values, j['priority']) ?? Priority.normal,
      dose: (j['dose'] as num?)?.toDouble() ?? 1.0,
      color: Color((j['color'] as int?) ?? 0xFF6750A4),
      doseTimes: slots,
      startDate: _parseDate(j['startDate']) ?? DateTime.now(),
      endDate: _parseDate(j['endDate']),
      weekDays: _parseBoolList(j['weekDays']),
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
    Priority? priority,
    double? dose,
    Color? color,
    List<DoseTime>? doseTimes,
    DateTime? startDate,
    DateTime? endDate,
    List<bool>? weekDays,
    bool? eaten,
  }) =>
      ReminderModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        form: form ?? this.form,
        priority: priority ?? this.priority,
        dose: dose ?? this.dose,
        color: color ?? this.color,
        doseTimes: doseTimes ?? this.doseTimes,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        weekDays: weekDays ?? List<bool>.from(this.weekDays),
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
