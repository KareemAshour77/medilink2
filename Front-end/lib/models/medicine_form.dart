import 'package:flutter/foundation.dart';

enum MedicineForm {
  tablets,
  capsules,
  syrups,
  dropsEye,
  dropsEar,
  dropsNasal,
  injection,
  inhaler,
  cream,
  powder,
  suppository,
  lozenge,
  sublingual,
}

extension MedicineFormMapper on MedicineForm {
  String get dbValue {
    switch (this) {
      case MedicineForm.tablets:
        return 'tablets';
      case MedicineForm.capsules:
        return 'capsules';
      case MedicineForm.syrups:
        return 'syrups';
      case MedicineForm.dropsEye:
        return 'drops_eye';
      case MedicineForm.dropsEar:
        return 'drops_ear';
      case MedicineForm.dropsNasal:
        return 'drops_nasal';
      case MedicineForm.injection:
        return 'injection';
      case MedicineForm.inhaler:
        return 'inhaler';
      case MedicineForm.cream:
        return 'cream';
      case MedicineForm.powder:
        return 'powder';
      case MedicineForm.suppository:
        return 'suppository';
      case MedicineForm.lozenge:
        return 'lozenge';
      case MedicineForm.sublingual:
        return 'sublingual';
    }
  }
}

class MedicineFormParser {
  static const MedicineForm fallback = MedicineForm.tablets;

  static const Map<String, MedicineForm> _dbValues = {
    'tablets': MedicineForm.tablets,
    'capsules': MedicineForm.capsules,
    'syrups': MedicineForm.syrups,
    'drops_eye': MedicineForm.dropsEye,
    'drops_ear': MedicineForm.dropsEar,
    'drops_nasal': MedicineForm.dropsNasal,
    'injection': MedicineForm.injection,
    'inhaler': MedicineForm.inhaler,
    'cream': MedicineForm.cream,
    'powder': MedicineForm.powder,
    'suppository': MedicineForm.suppository,
    'lozenge': MedicineForm.lozenge,
    'sublingual': MedicineForm.sublingual,
  };

  static MedicineForm? tryParse(dynamic raw) {
    final normalized = _normalize(raw);
    if (normalized == null) return null;

    return _dbValues[normalized];
  }

  static MedicineForm parseOrFallback(
    dynamic raw, {
    MedicineForm fallback = MedicineFormParser.fallback,
  }) {
    final parsed = tryParse(raw);
    if (parsed != null) return parsed;

    if (raw != null && raw.toString().trim().isNotEmpty) {
      debugPrint('Unknown medicine form from database: "$raw"');
    }
    return fallback;
  }

  static String? _normalize(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim().toLowerCase();
    if (value.isEmpty) return null;
    return value.replaceAll(RegExp(r'[\s-]+'), '_');
  }
}
