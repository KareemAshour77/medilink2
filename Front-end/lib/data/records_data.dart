// lib/data/records_data.dart
// ─── Data models + sample records for the Medical Records feature ─────────────

enum RecordType { all, labTest, imaging, prescription, diagnosis }
enum RecordStatus { stable, critical, pending }

class MedicalRecord {
  final String id;
  final String title;
  final String doctorOrFacility;
  final DateTime date;
  final RecordType type;
  final RecordStatus status;
  final String diagnosis;
  final List<String> symptoms;
  final List<String> treatments;
  final String doctorNotes;
  final List<String> attachments; // file names / paths
  final String condition; // for insights (most frequent condition)

  // ── Backend-backed fields (null for the legacy sample data) ────────────────
  /// Server id of the record entry; null for local/sample records.
  final String? serverId;

  /// Prescription effectiveness status: taking_now | effective | not_effective.
  /// Only set for prescription records loaded from the backend.
  final String? prescriptionStatus;

  /// Prescription medications: [{name, dosage, frequency}].
  final List<Map<String, String>> items;

  /// 'patient' or 'doctor' — who created the record (backend records only).
  final String createdByRole;

  const MedicalRecord({
    required this.id,
    required this.title,
    required this.doctorOrFacility,
    required this.date,
    required this.type,
    required this.status,
    required this.diagnosis,
    required this.symptoms,
    required this.treatments,
    required this.doctorNotes,
    required this.attachments,
    required this.condition,
    this.serverId,
    this.prescriptionStatus,
    this.items = const [],
    this.createdByRole = 'patient',
  });

  bool get isPrescription => type == RecordType.prescription;

  String get typeLabel {
    switch (type) {
      case RecordType.labTest:     return 'Lab Test';
      case RecordType.imaging:     return 'Imaging';
      case RecordType.prescription:return 'Prescription';
      case RecordType.diagnosis:   return 'Diagnosis';
      default:                     return 'All';
    }
  }

  String get statusLabel {
    switch (status) {
      case RecordStatus.stable:   return 'Stable';
      case RecordStatus.critical: return 'Critical';
      case RecordStatus.pending:  return 'Pending';
    }
  }

  MedicalRecord copyWith({String? prescriptionStatus}) => MedicalRecord(
        id: id,
        title: title,
        doctorOrFacility: doctorOrFacility,
        date: date,
        type: type,
        status: status,
        diagnosis: diagnosis,
        symptoms: symptoms,
        treatments: treatments,
        doctorNotes: doctorNotes,
        attachments: attachments,
        condition: condition,
        serverId: serverId,
        prescriptionStatus: prescriptionStatus ?? this.prescriptionStatus,
        items: items,
        createdByRole: createdByRole,
      );

  /// Builds a record from the unified backend `/records` JSON shape.
  factory MedicalRecord.fromApi(Map<String, dynamic> j) {
    final type = recordTypeFromApi(j['type']?.toString());
    final rawStatus = j['status']?.toString();
    final isRx = type == RecordType.prescription;
    final items = ((j['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => {
              'name': (e['name'] ?? '').toString(),
              'dosage': (e['dosage'] ?? '').toString(),
              'frequency': (e['frequency'] ?? '').toString(),
            })
        .toList();
    return MedicalRecord(
      id: (j['id'] ?? '').toString(),
      serverId: (j['id'] ?? '').toString(),
      title: (j['title'] ?? 'Record').toString(),
      doctorOrFacility: (j['doctor_or_facility'] ?? '').toString(),
      date: DateTime.tryParse(
              (j['record_date'] ?? j['created_at'] ?? '').toString()) ??
          DateTime.now(),
      type: type,
      status: isRx ? RecordStatus.stable : recordStatusFromApi(rawStatus),
      diagnosis: (j['description'] ?? '').toString(),
      symptoms: const [],
      treatments: [for (final it in items) it['name'] ?? ''],
      doctorNotes: (j['doctor_notes'] ?? '').toString(),
      attachments: ((j['attachments'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      condition: (j['title'] ?? '').toString(),
      prescriptionStatus: isRx ? (rawStatus ?? 'taking_now') : null,
      items: items,
      createdByRole: (j['created_by_role'] ?? 'patient').toString(),
    );
  }
}

// ── Backend <-> frontend mapping helpers ─────────────────────────────────────

RecordType recordTypeFromApi(String? t) {
  switch (t) {
    case 'lab_test':     return RecordType.labTest;
    case 'imaging':      return RecordType.imaging;
    case 'prescription': return RecordType.prescription;
    case 'diagnosis':    return RecordType.diagnosis;
    default:             return RecordType.diagnosis;
  }
}

String recordTypeToApi(RecordType t) {
  switch (t) {
    case RecordType.labTest:      return 'lab_test';
    case RecordType.imaging:      return 'imaging';
    case RecordType.prescription: return 'prescription';
    case RecordType.diagnosis:    return 'diagnosis';
    default:                      return 'diagnosis';
  }
}

RecordStatus recordStatusFromApi(String? s) {
  switch (s) {
    case 'critical': return RecordStatus.critical;
    case 'pending':  return RecordStatus.pending;
    default:         return RecordStatus.stable;
  }
}

String recordStatusToApi(RecordStatus s) {
  switch (s) {
    case RecordStatus.critical: return 'critical';
    case RecordStatus.pending:  return 'pending';
    case RecordStatus.stable:   return 'stable';
  }
}

/// Prescription status label (id → bilingual).
const kRxStatuses = <(String, String, String)>[
  ('taking_now', 'Taking now', 'يتناوله الآن'),
  ('effective', 'Effective', 'فعّال'),
  ('not_effective', 'Not effective', 'غير فعّال'),
];

String rxStatusLabel(String? id, {bool arabic = false}) {
  for (final s in kRxStatuses) {
    if (s.$1 == id) return arabic ? s.$3 : s.$2;
  }
  return id ?? '';
}

// ─── Sample data ──────────────────────────────────────────────────────────────
final List<MedicalRecord> sampleRecords = [
  MedicalRecord(
    id: '1',
    title: 'Blood Test Results',
    doctorOrFacility: 'Dr. Ahmed Hassan — Cairo Lab',
    date: DateTime(2024, 11, 20),
    type: RecordType.labTest,
    status: RecordStatus.stable,
    diagnosis: 'Normal blood count with slight iron deficiency.',
    symptoms: ['Fatigue', 'Mild headache'],
    treatments: ['Iron supplements 200mg daily', 'Increase leafy greens in diet'],
    doctorNotes: 'Recheck in 3 months. Patient responding well to diet changes.',
    attachments: ['blood_test_nov2024.pdf'],
    condition: 'Iron Deficiency',
  ),
  MedicalRecord(
    id: '2',
    title: 'X-Ray Chest',
    doctorOrFacility: 'Radiology Center — Maadi',
    date: DateTime(2024, 11, 15),
    type: RecordType.imaging,
    status: RecordStatus.stable,
    diagnosis: 'Clear lungs. No abnormalities detected.',
    symptoms: ['Mild chest discomfort', 'Occasional cough'],
    treatments: ['Rest', 'Steam inhalation'],
    doctorNotes: 'Chest clear. Cough likely viral. Follow up if persists > 2 weeks.',
    attachments: ['xray_chest_nov2024.jpg'],
    condition: 'Viral Cough',
  ),
  MedicalRecord(
    id: '3',
    title: 'Panadol Prescription',
    doctorOrFacility: 'Dr. Sara Mahmoud — Clinic 5',
    date: DateTime(2024, 11, 10),
    type: RecordType.prescription,
    status: RecordStatus.stable,
    diagnosis: 'Acute fever and body aches.',
    symptoms: ['Fever 38.5°C', 'Body aches', 'Chills'],
    treatments: ['Panadol 500mg every 6 hrs', 'Rest', 'Fluids'],
    doctorNotes: 'Viral flu. Should resolve in 5-7 days. Emergency visit if fever > 39.5.',
    attachments: ['prescription_nov2024.pdf'],
    condition: 'Flu',
  ),
  MedicalRecord(
    id: '4',
    title: 'Cardiology Report',
    doctorOrFacility: 'Dr. Omar Khalil — Heart Clinic',
    date: DateTime(2024, 10, 30),
    type: RecordType.diagnosis,
    status: RecordStatus.critical,
    diagnosis: 'Mild arrhythmia detected. Requires monitoring.',
    symptoms: ['Palpitations', 'Shortness of breath', 'Dizziness'],
    treatments: ['Beta-blocker 25mg daily', 'Avoid caffeine', 'Low-stress lifestyle'],
    doctorNotes: 'Holter monitor for 24hrs scheduled. Avoid strenuous exercise until cleared.',
    attachments: ['cardiology_report_oct2024.pdf', 'ecg_oct2024.jpg'],
    condition: 'Arrhythmia',
  ),
  MedicalRecord(
    id: '5',
    title: 'MRI Brain Scan',
    doctorOrFacility: 'Scan Center — Heliopolis',
    date: DateTime(2024, 10, 10),
    type: RecordType.imaging,
    status: RecordStatus.stable,
    diagnosis: 'No structural abnormalities. Migraine-related changes noted.',
    symptoms: ['Severe headache', 'Nausea', 'Light sensitivity'],
    treatments: ['Sumatriptan 50mg as needed', 'Avoid triggers'],
    doctorNotes: 'MRI confirms migraine pattern. No tumors or lesions. Annual scan recommended.',
    attachments: ['mri_brain_oct2024.jpg'],
    condition: 'Migraine',
  ),
  MedicalRecord(
    id: '6',
    title: 'Diabetes Checkup',
    doctorOrFacility: 'Dr. Layla Nour — Diabetes Center',
    date: DateTime(2025, 2, 5),
    type: RecordType.labTest,
    status: RecordStatus.critical,
    diagnosis: 'HbA1c elevated at 8.2%. Diabetes management required.',
    symptoms: ['Increased thirst', 'Frequent urination', 'Fatigue'],
    treatments: ['Metformin 500mg twice daily', 'Low-carb diet', 'Daily walking 30min'],
    doctorNotes: 'HbA1c must drop below 7 in next 3 months. Dietitian referral given.',
    attachments: ['diabetes_labs_feb2025.pdf'],
    condition: 'Diabetes',
  ),
  MedicalRecord(
    id: '7',
    title: 'Flu Diagnosis',
    doctorOrFacility: 'Dr. Ahmed Hassan — Clinic 3',
    date: DateTime(2025, 3, 12),
    type: RecordType.diagnosis,
    status: RecordStatus.stable,
    diagnosis: 'Seasonal influenza Type A.',
    symptoms: ['Fever', 'Runny nose', 'Sore throat', 'Body aches'],
    treatments: ['Tamiflu 75mg twice daily for 5 days', 'Rest', 'Fluids'],
    doctorNotes: 'Patient advised to stay home. Flu shot recommended next season.',
    attachments: [],
    condition: 'Flu',
  ),
];
