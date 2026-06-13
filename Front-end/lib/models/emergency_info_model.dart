// Models for the patient Emergency Card.
//
// JSON keys use snake_case to match the NestJS `emergency-profile` backend
// (e.g. `blood_type`, `medical_devices`, `pregnancy_weeks`).

class MedicationModel {
  final String name;
  final String dose;
  final String frequency;

  const MedicationModel({
    required this.name,
    this.dose = '',
    this.frequency = '',
  });

  factory MedicationModel.fromJson(Map<String, dynamic> j) => MedicationModel(
        name: (j['name'] ?? '').toString(),
        dose: (j['dose'] ?? '').toString(),
        frequency: (j['frequency'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'dose': dose,
        'frequency': frequency,
      };

  /// "500 mg • Twice Daily", "500 mg", "Twice Daily" or '' depending on data.
  String get detail {
    final parts = [dose.trim(), frequency.trim()]
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.join(' • ');
  }
}

class EmergencyInfoModel {
  final String gender; // 'male' | 'female'
  final DateTime? dateOfBirth;
  final String? bloodType;
  final double? height; // centimeters
  final double? weight; // kilograms
  final List<String> allergies;
  final List<String> conditions;
  final List<MedicationModel> medications;
  final List<String> medicalDevices;
  final bool organDonor;
  final bool smoker;
  final bool isPregnant;
  final DateTime? pregnancyStartDate;
  final String? primaryLanguage;
  final DateTime? updatedAt;

  const EmergencyInfoModel({
    this.gender = 'male',
    this.dateOfBirth,
    this.bloodType,
    this.height,
    this.weight,
    this.allergies = const [],
    this.conditions = const [],
    this.medications = const [],
    this.medicalDevices = const [],
    this.organDonor = false,
    this.smoker = false,
    this.isPregnant = false,
    this.pregnancyStartDate,
    this.primaryLanguage,
    this.updatedAt,
  });

  bool get isFemale => gender == 'female';

  /// Age in whole years, derived live from [dateOfBirth] so it stays current
  /// without re-saving. Null when no birth date is set.
  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    // Subtract a year if this year's birthday hasn't occurred yet.
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  /// Current pregnancy weeks derived live from [pregnancyStartDate], so the
  /// value advances over time without re-saving. Null when not applicable.
  int? get pregnancyWeeks {
    if (!isFemale || !isPregnant || pregnancyStartDate == null) return null;
    final days = DateTime.now().difference(pregnancyStartDate!).inDays;
    if (days < 0) return 0;
    return days ~/ 7;
  }

  static List<String> _strList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    // Tolerate legacy comma-separated TEXT values.
    if (v is String && v.trim().isNotEmpty) {
      return v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory EmergencyInfoModel.fromJson(Map<String, dynamic> j) {
    return EmergencyInfoModel(
      gender: (j['gender'] ?? 'male').toString(),
      dateOfBirth: j['date_of_birth'] != null
          ? DateTime.tryParse(j['date_of_birth'].toString())
          : null,
      bloodType: (j['blood_type'] as String?)?.trim().isNotEmpty == true
          ? (j['blood_type'] as String).trim()
          : null,
      height: _toDouble(j['height']),
      weight: _toDouble(j['weight']),
      allergies: _strList(j['allergies']),
      conditions: _strList(j['chronic_diseases']),
      medications: (j['medications'] is List)
          ? (j['medications'] as List)
              .whereType<Map>()
              .map((m) => MedicationModel.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const [],
      medicalDevices: _strList(j['medical_devices']),
      organDonor: j['organ_donor'] == true,
      smoker: j['smoker'] == true,
      isPregnant: j['is_pregnant'] == true,
      pregnancyStartDate: j['pregnancy_start_date'] != null
          ? DateTime.tryParse(j['pregnancy_start_date'].toString())
          : null,
      primaryLanguage:
          (j['primary_language'] as String?)?.trim().isNotEmpty == true
              ? (j['primary_language'] as String).trim()
              : null,
      updatedAt: j['updated_at'] != null
          ? DateTime.tryParse(j['updated_at'].toString())
          : null,
    );
  }

  /// Body for POST/PATCH. Sends snake_case keys the backend expects.
  Map<String, dynamic> toJson() => {
        'gender': gender,
        'date_of_birth':
            dateOfBirth != null ? _dateOnly(dateOfBirth!) : null,
        'blood_type': bloodType,
        'height': height,
        'weight': weight,
        'allergies': allergies,
        'chronic_diseases': conditions,
        'medications': medications.map((m) => m.toJson()).toList(),
        'medical_devices': medicalDevices,
        'organ_donor': organDonor,
        'smoker': smoker,
        'is_pregnant': isFemale ? isPregnant : false,
        // Persist the start date (YYYY-MM-DD); weeks are derived on read.
        'pregnancy_start_date': (isFemale && isPregnant && pregnancyStartDate != null)
            ? _dateOnly(pregnancyStartDate!)
            : null,
        'primary_language': primaryLanguage,
      };

  static String _dateOnly(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  EmergencyInfoModel copyWith({
    String? gender,
    DateTime? dateOfBirth,
    String? bloodType,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? conditions,
    List<MedicationModel>? medications,
    List<String>? medicalDevices,
    bool? organDonor,
    bool? smoker,
    bool? isPregnant,
    DateTime? pregnancyStartDate,
    String? primaryLanguage,
    DateTime? updatedAt,
  }) {
    return EmergencyInfoModel(
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      medications: medications ?? this.medications,
      medicalDevices: medicalDevices ?? this.medicalDevices,
      organDonor: organDonor ?? this.organDonor,
      smoker: smoker ?? this.smoker,
      isPregnant: isPregnant ?? this.isPregnant,
      pregnancyStartDate: pregnancyStartDate ?? this.pregnancyStartDate,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
