// ─────────────────────────────────────────────────────────────────────────────
// api_ai.dart
//
// Production-grade Flutter service layer for AI inference.
//
// Services:
//   ChatService          — /chat  (text + file messages)
//   PredictionService    — /predict/brain  (quick model test)
//   ChestAnalysisService — /chest/*  (full chest X-ray module)
//
// Chest endpoints:
//   POST /chest/analyze          — X-ray image → top-2 findings + full report
//   POST /chest/followup         — Patient Q&A  (FAISS + Groq)
//   POST /chest/cross-reference  — Compare findings vs symptoms
//   POST /chest/doctor-summary   — Clinical summary for specialist
//   GET  /chest/info/{class_key} — Knowledge base for one condition
//   GET  /chest/health           — Module status
// ─────────────────────────────────────────────────────────────────────────────

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Server base URL
// ──────────────────────────────────────────────────────────────────────────────

// const String kServerBaseUrl = 'http://172.20.10.3:8000';
//  const String kServerBaseUrl = 'http://192.168.1.103:8000';
 const String kServerBaseUrl = 'http://192.168.1.18:8000';

// ──────────────────────────────────────────────────────────────────────────────
// ChatResponse
// ──────────────────────────────────────────────────────────────────────────────

class ChatResponse {
  final String response;
  final String? statusMessage;
  final bool isSuccess;

  const ChatResponse._({
    required this.response,
    this.statusMessage,
    required this.isSuccess,
  });

  factory ChatResponse.success({
    required String response,
    String? statusMessage,
  }) =>
      ChatResponse._(
        response: response,
        statusMessage: statusMessage,
        isSuccess: true,
      );

  factory ChatResponse.failure(String errorDetail) => ChatResponse._(
        response: '⚠️ $errorDetail',
        isSuccess: false,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// PredictionResult  (brain quick-test)
// ──────────────────────────────────────────────────────────────────────────────

class PredictionResult {
  final String model;
  final String prediction;
  final double confidence;
  final int inferenceTimeMs;
  final Map<String, double> probabilities;
  final bool isMultiLabel;
  final List<String> positiveLabels;

  const PredictionResult._({
    required this.model,
    required this.prediction,
    required this.confidence,
    required this.inferenceTimeMs,
    required this.probabilities,
    required this.isMultiLabel,
    required this.positiveLabels,
  });

  factory PredictionResult._brain({
    required String predictionLabel,
    required double confidenceRaw,
    required Map<String, double> probabilities,
    required int inferenceTimeMs,
  }) =>
      PredictionResult._(
        model: 'Brain MRI Classifier',
        prediction: predictionLabel,
        confidence: confidenceRaw * 100,
        inferenceTimeMs: inferenceTimeMs,
        probabilities: probabilities,
        isMultiLabel: false,
        positiveLabels: const [],
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// ChestFinding  — one detected condition inside a ChestAnalysisResult
// ──────────────────────────────────────────────────────────────────────────────

class ChestUrgency {
  final String level;   // "HIGH" | "MODERATE" | "LOW"
  final String icon;
  final String color;
  final String label;
  final String message;

  const ChestUrgency({
    required this.level,
    required this.icon,
    required this.color,
    required this.label,
    required this.message,
  });

  factory ChestUrgency.fromJson(Map<String, dynamic> j) => ChestUrgency(
        level:   j['level']   as String? ?? 'MODERATE',
        icon:    j['icon']    as String? ?? '🟠',
        color:   j['color']   as String? ?? '#DD6B20',
        label:   j['label']   as String? ?? '',
        message: j['message'] as String? ?? '',
      );
}

class ChestTreatmentOption {
  final String name;
  final String description;

  const ChestTreatmentOption({required this.name, required this.description});

  factory ChestTreatmentOption.fromJson(Map<String, dynamic> j) =>
      ChestTreatmentOption(
        name:        j['name']        as String? ?? '',
        description: j['description'] as String? ?? '',
      );
}

class ChestFinding {
  final String className;
  final String classKey;
  final String confidence;
  final String confidenceLabel;
  final String displayName;
  final ChestUrgency urgency;
  final String conditionOverview;
  final List<String> commonSymptoms;
  final List<String> emergencyWarnings;
  final List<ChestTreatmentOption> treatmentOptions;
  final List<String> specialistDoctors;
  final List<String> whatToExpectNext;
  final List<String> informationSources;
  final String disclaimer;

  const ChestFinding({
    required this.className,
    required this.classKey,
    required this.confidence,
    required this.confidenceLabel,
    required this.displayName,
    required this.urgency,
    required this.conditionOverview,
    required this.commonSymptoms,
    required this.emergencyWarnings,
    required this.treatmentOptions,
    required this.specialistDoctors,
    required this.whatToExpectNext,
    required this.informationSources,
    required this.disclaimer,
  });

  factory ChestFinding.fromJson(Map<String, dynamic> j) => ChestFinding(
        className:          j['class']               as String? ?? '',
        classKey:           j['class_key']           as String? ?? '',
        confidence:         j['confidence']          as String? ?? '0%',
        confidenceLabel:    j['confidence_label']    as String? ?? '',
        displayName:        j['display_name']        as String? ?? '',
        urgency:            ChestUrgency.fromJson((j['urgency'] as Map<String, dynamic>?) ?? {}),
        conditionOverview:  j['condition_overview']  as String? ?? '',
        commonSymptoms:     _toStringList(j['common_symptoms']),
        emergencyWarnings:  _toStringList(j['emergency_warnings']),
        treatmentOptions:   ((j['treatment_options'] as List<dynamic>?) ?? [])
            .map((e) => ChestTreatmentOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        specialistDoctors:  _toStringList(j['specialist_doctors']),
        whatToExpectNext:   _toStringList(j['what_to_expect_next']),
        informationSources: _toStringList(j['information_sources']),
        disclaimer:         j['disclaimer'] as String? ?? '',
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// ChestAnalysisResult  — full /chest/analyze response
// ──────────────────────────────────────────────────────────────────────────────

class ChestScanResult {
  final int findingsCount;
  final bool anyDetected;
  final String overallUrgency;
  final String overallUrgencyIcon;
  final List<Map<String, String>> topFindings;   // [{class, confidence}]
  final Map<String, double> allProbabilities;
  final String importantNote;

  const ChestScanResult({
    required this.findingsCount,
    required this.anyDetected,
    required this.overallUrgency,
    required this.overallUrgencyIcon,
    required this.topFindings,
    required this.allProbabilities,
    required this.importantNote,
  });

  factory ChestScanResult.fromJson(Map<String, dynamic> j) => ChestScanResult(
        findingsCount:      j['findings_count']      as int?    ?? 0,
        anyDetected:        j['any_detected']        as bool?   ?? false,
        overallUrgency:     j['overall_urgency']     as String? ?? 'MODERATE',
        overallUrgencyIcon: j['overall_urgency_icon'] as String? ?? '🟠',
        topFindings: ((j['top_findings'] as List<dynamic>?) ?? [])
            .map((e) => Map<String, String>.from(
                  (e as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString())),
                ))
            .toList(),
        allProbabilities: ((j['all_probabilities'] as Map<String, dynamic>?) ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        importantNote: j['important_note'] as String? ?? '',
      );
}

class ChestAnalysisResult {
  final ChestScanResult scanResult;
  final List<ChestFinding> findings;
  final String personalizedIntro;
  final String generatedBy;
  final bool groqAvailable;
  final List<String> groqUsedFor;
  final String language;

  const ChestAnalysisResult({
    required this.scanResult,
    required this.findings,
    required this.personalizedIntro,
    required this.generatedBy,
    required this.groqAvailable,
    required this.groqUsedFor,
    required this.language,
  });

  factory ChestAnalysisResult.fromJson(Map<String, dynamic> j) =>
      ChestAnalysisResult(
        scanResult:       ChestScanResult.fromJson(
            (j['scan_result'] as Map<String, dynamic>?) ?? {}),
        findings:         ((j['findings'] as List<dynamic>?) ?? [])
            .map((e) => ChestFinding.fromJson(e as Map<String, dynamic>))
            .toList(),
        personalizedIntro: j['personalized_intro'] as String? ?? '',
        generatedBy:       j['generated_by']       as String? ?? '',
        groqAvailable:     j['groq_available']      as bool?   ?? false,
        groqUsedFor:       _toStringList(j['groq_used_for']),
        language:          j['language']            as String? ?? 'en',
      );

  /// Formats the result into a readable chat message.
  String toChatMessage() {
    final sb  = StringBuffer();
    final ar  = language == 'ar';

    final labelHeader      = ar ? 'تحليل الأشعة السينية للصدر' : 'Chest X-ray Analysis';
    final labelConfidence  = ar ? 'الثقة'       : 'Confidence';
    final labelUrgency     = ar ? 'الأولوية'    : 'Urgency';
    final labelOverview    = ar ? 'نظرة عامة'   : 'Overview';
    final labelSymptoms    = ar ? 'الأعراض الشائعة'    : 'Common Symptoms';
    final labelTreatment   = ar ? 'خيارات العلاج'      : 'Treatment Options';
    final labelSpecialist  = ar ? 'استشر متخصصاً'      : 'See a Specialist';
    final labelEmergency   = ar ? 'تحذيرات طارئة'      : 'Emergency Warnings';
    final labelExpect      = ar ? 'ماذا تتوقع بعد ذلك' : 'What To Expect Next';
    final labelSources     = ar ? 'المصادر'     : 'Sources';

    // ── Header ───────────────────────────────────────────────
    sb.writeln('${scanResult.overallUrgencyIcon} **$labelHeader**');
    sb.writeln();

    if (personalizedIntro.isNotEmpty) {
      sb.writeln(personalizedIntro);
      sb.writeln();
    }

    // ── Each finding ─────────────────────────────────────────
    for (var i = 0; i < findings.length; i++) {
      final f = findings[i];
      sb.writeln('─────────────────────');
      sb.writeln('**${i + 1}. ${f.displayName}**  ${f.urgency.icon}');
      sb.writeln('$labelConfidence: ${f.confidence} (${f.confidenceLabel})');
      sb.writeln('$labelUrgency: ${f.urgency.label}');
      sb.writeln();

      if (f.conditionOverview.isNotEmpty) {
        sb.writeln('📋 **$labelOverview**');
        sb.writeln(f.conditionOverview);
        sb.writeln();
      }

      if (f.commonSymptoms.isNotEmpty) {
        sb.writeln('🩺 **$labelSymptoms**');
        for (final s in f.commonSymptoms) { sb.writeln('• $s'); }
        sb.writeln();
      }

      if (f.treatmentOptions.isNotEmpty) {
        sb.writeln('💊 **$labelTreatment**');
        for (final t in f.treatmentOptions) { sb.writeln('• **${t.name}**: ${t.description}'); }
        sb.writeln();
      }

      if (f.specialistDoctors.isNotEmpty) {
        sb.writeln('👨‍⚕️ **$labelSpecialist**');
        sb.writeln(f.specialistDoctors.join(' · '));
        sb.writeln();
      }

      if (f.emergencyWarnings.isNotEmpty) {
        sb.writeln('🚨 **$labelEmergency**');
        for (final w in f.emergencyWarnings) { sb.writeln('⚠️ $w'); }
        sb.writeln();
      }

      if (f.whatToExpectNext.isNotEmpty) {
        sb.writeln('📅 **$labelExpect**');
        for (final s in f.whatToExpectNext) { sb.writeln('• $s'); }
        sb.writeln();
      }

      if (f.informationSources.isNotEmpty) {
        sb.writeln('📚 **$labelSources**');
        sb.writeln(f.informationSources.join(' · '));
        sb.writeln();
      }
    }

    // ── Footer ───────────────────────────────────────────────
    sb.writeln('─────────────────────');
    sb.writeln('⚕️ *${scanResult.importantNote}*');
    if (generatedBy.isNotEmpty) {
      sb.writeln();
      sb.writeln('📚 *$generatedBy*');
    }

    return sb.toString().trim();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ChestFollowUpResult
// ──────────────────────────────────────────────────────────────────────────────

class ChestFollowUpResult {
  final String question;
  final String answer;
  final List<String> sourcesUsed;
  final bool groqUsed;

  const ChestFollowUpResult({
    required this.question,
    required this.answer,
    required this.sourcesUsed,
    required this.groqUsed,
  });

  factory ChestFollowUpResult.fromJson(Map<String, dynamic> j) =>
      ChestFollowUpResult(
        question:    j['question']    as String? ?? '',
        answer:      j['answer']      as String? ?? '',
        sourcesUsed: _toStringList(j['sources_used']),
        groqUsed:    j['groq_used']   as bool?   ?? false,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// ChestAnalysisService  — all /chest/* calls
// ──────────────────────────────────────────────────────────────────────────────

class ChestAnalysisService {
  ChestAnalysisService._();

  static final _client = http.Client();

  // ── POST /chest/analyze ──────────────────────────────────────────────────

  /// Upload a chest X-ray with an optional patient note.
  ///
  /// [patientNote]  — free-text the patient typed before sending the photo.
  ///                  Sent as [reported_symptoms] when it looks like symptoms,
  ///                  otherwise forwarded as a context hint.
  /// [language]     — "en" (default) or "ar"
  static Future<ChestAnalysisResult> analyze({
    required File imageFile,
    String patientNote = '',
    String language = 'en',
    bool includeDoctorSummary = false,
  }) async {
    final uri = Uri.parse('$kServerBaseUrl/chest/analyze');

    final request = http.MultipartRequest('POST', uri)
      ..fields['language']                = language
      ..fields['include_doctor_summary']  = includeDoctorSummary.toString();

    if (patientNote.isNotEmpty) {
      request.fields['reported_symptoms'] = patientNote;
    }

    request.files.add(await http.MultipartFile.fromPath(
      'file', imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    try {
      final streamed = await _client.send(request);
      final body     = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        String detail = 'HTTP ${streamed.statusCode}';
        try {
          final d = json.decode(body) as Map<String, dynamic>;
          detail = d['detail']?.toString() ?? detail;
        } catch (_) {}
        throw Exception(detail);
      }

      final decoded = json.decode(body) as Map<String, dynamic>;
      return ChestAnalysisResult.fromJson(decoded);
    } on SocketException catch (e) {
      throw Exception(
        'Cannot reach server at $kServerBaseUrl. '
        'Ensure server.py is running. (${e.message})',
      );
    }
  }

  // ── POST /chest/followup ─────────────────────────────────────────────────

  static Future<ChestFollowUpResult> followUp({
    required String question,
    String? diseaseKey,
    String language = 'en',
  }) async {
    final uri = Uri.parse('$kServerBaseUrl/chest/followup');

    try {
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({
          'question':    question,
          if (diseaseKey != null) 'disease_key': diseaseKey,
          'language':    language,
        }),
      );

      if (res.statusCode != 200) {
        String detail = 'HTTP ${res.statusCode}';
        try {
          final d = json.decode(res.body) as Map<String, dynamic>;
          detail = d['detail']?.toString() ?? detail;
        } catch (_) {}
        throw Exception(detail);
      }

      return ChestFollowUpResult.fromJson(
          json.decode(res.body) as Map<String, dynamic>);
    } on SocketException catch (e) {
      throw Exception('Cannot reach server. (${e.message})');
    }
  }

  // ── POST /chest/cross-reference ──────────────────────────────────────────

  static Future<Map<String, dynamic>> crossReference({
    required List<Map<String, dynamic>> topDetections,
    required List<String> reportedSymptoms,
    Map<String, dynamic>? symptomCheckerResult,
    String language = 'en',
  }) async {
    final uri = Uri.parse('$kServerBaseUrl/chest/cross-reference');

    try {
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({
          'top_detections':         topDetections,
          'reported_symptoms':      reportedSymptoms,
          if (symptomCheckerResult != null)
            'symptom_checker_result': symptomCheckerResult,
          'language': language,
        }),
      );
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return json.decode(res.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw Exception('Cannot reach server. (${e.message})');
    }
  }

  // ── POST /chest/doctor-summary ───────────────────────────────────────────

  static Future<Map<String, dynamic>> doctorSummary({
    required List<Map<String, dynamic>> topDetections,
    List<String>? reportedSymptoms,
    String language = 'en',
  }) async {
    final uri = Uri.parse('$kServerBaseUrl/chest/doctor-summary');

    try {
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({
          'top_detections':    topDetections,
          if (reportedSymptoms != null) 'reported_symptoms': reportedSymptoms,
          'language':          language,
        }),
      );
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return json.decode(res.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw Exception('Cannot reach server. (${e.message})');
    }
  }

  // ── GET /chest/info/{class_key} ──────────────────────────────────────────

  static Future<Map<String, dynamic>> conditionInfo(String classKey) async {
    final uri = Uri.parse('$kServerBaseUrl/chest/info/$classKey');
    try {
      final res = await _client.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return json.decode(res.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw Exception('Cannot reach server. (${e.message})');
    }
  }

  // ── GET /chest/health ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> health() async {
    final uri = Uri.parse('$kServerBaseUrl/chest/health');
    try {
      final res = await _client.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return json.decode(res.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw Exception('Cannot reach server. (${e.message})');
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Brain MRI result models  (/brain/analyze response)
// ──────────────────────────────────────────────────────────────────────────────

class BrainScanResult {
  final String predictedCondition;  // display name e.g. "Glioma Tumor"
  final String modelConfidence;     // e.g. "87.4%"
  final String confidenceLevel;     // "High", "Moderate", …
  final Map<String, double> allClassProbabilities;
  final String importantNote;

  const BrainScanResult({
    required this.predictedCondition,
    required this.modelConfidence,
    required this.confidenceLevel,
    required this.allClassProbabilities,
    required this.importantNote,
  });

  factory BrainScanResult.fromJson(Map<String, dynamic> j) => BrainScanResult(
        predictedCondition:      j['predicted_condition']   as String? ?? '',
        modelConfidence:         j['model_confidence']      as String? ?? '',
        confidenceLevel:         j['confidence_level']      as String? ?? '',
        allClassProbabilities:   ((j['all_class_probabilities'] as Map<String, dynamic>?) ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        importantNote:           j['important_note']        as String? ?? '',
      );
}

class BrainUrgency {
  final String level;
  final String icon;
  final String color;
  final String label;
  final String message;

  const BrainUrgency({
    required this.level,
    required this.icon,
    required this.color,
    required this.label,
    required this.message,
  });

  factory BrainUrgency.fromJson(Map<String, dynamic> j) => BrainUrgency(
        level:   j['level']   as String? ?? 'MODERATE',
        icon:    j['icon']    as String? ?? '🟠',
        color:   j['color']   as String? ?? '#DD6B20',
        label:   j['label']   as String? ?? '',
        message: j['message'] as String? ?? '',
      );
}

class BrainTreatmentOption {
  final String name;
  final String description;
  final String source;

  const BrainTreatmentOption({
    required this.name,
    required this.description,
    required this.source,
  });

  factory BrainTreatmentOption.fromJson(Map<String, dynamic> j) =>
      BrainTreatmentOption(
        name:        j['name']        as String? ?? '',
        description: j['description'] as String? ?? '',
        source:      j['source']      as String? ?? '',
      );
}

class BrainSpecialist {
  final String specialty;
  final String role;

  const BrainSpecialist({required this.specialty, required this.role});

  factory BrainSpecialist.fromJson(Map<String, dynamic> j) => BrainSpecialist(
        specialty: j['specialty'] as String? ?? '',
        role:      j['role']      as String? ?? '',
      );
}

class BrainAnalysisResult {
  final BrainScanResult scanResult;
  final String conditionOverview;
  final BrainUrgency urgency;
  final List<String> commonSymptoms;
  final List<String> emergencyWarnings;
  final List<BrainTreatmentOption> treatmentOptions;
  final List<BrainSpecialist> specialistDoctors;
  final List<String> whatToExpectNext;
  final List<String> informationSources;
  final String disclaimer;
  final String generatedBy;
  final String personalizedIntro;
  final String predictedClass;     // raw class key e.g. "glioma"
  final bool groqAvailable;
  final List<String> groqUsedFor;
  final String language;

  const BrainAnalysisResult({
    required this.scanResult,
    required this.conditionOverview,
    required this.urgency,
    required this.commonSymptoms,
    required this.emergencyWarnings,
    required this.treatmentOptions,
    required this.specialistDoctors,
    required this.whatToExpectNext,
    required this.informationSources,
    required this.disclaimer,
    required this.generatedBy,
    required this.personalizedIntro,
    required this.predictedClass,
    required this.groqAvailable,
    required this.groqUsedFor,
    required this.language,
  });

  factory BrainAnalysisResult.fromJson(Map<String, dynamic> j) =>
      BrainAnalysisResult(
        scanResult:       BrainScanResult.fromJson(
            (j['scan_result'] as Map<String, dynamic>?) ?? {}),
        conditionOverview: j['condition_overview'] as String? ?? '',
        urgency:           BrainUrgency.fromJson(
            (j['urgency'] as Map<String, dynamic>?) ?? {}),
        commonSymptoms:    _extractStrings(j['common_symptoms']),
        emergencyWarnings: _toStringList(j['emergency_warnings']),
        treatmentOptions:  ((j['treatment_options'] as List<dynamic>?) ?? [])
            .map((e) => BrainTreatmentOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        specialistDoctors: ((j['specialist_doctors'] as List<dynamic>?) ?? [])
            .map((e) => BrainSpecialist.fromJson(e as Map<String, dynamic>))
            .toList(),
        whatToExpectNext:  _toStringList(j['what_to_expect_next']),
        informationSources: _toStringList(j['information_sources']),
        disclaimer:        j['disclaimer']         as String? ?? '',
        generatedBy:       j['generated_by']       as String? ?? '',
        personalizedIntro: j['personalized_intro'] as String? ?? '',
        predictedClass:    j['predicted_class']    as String? ?? '',
        groqAvailable:     j['groq_available']     as bool?   ?? false,
        groqUsedFor:       _toStringList(j['groq_used_for']),
        language:          j['language']           as String? ?? 'en',
      );

  String toChatMessage() {
    final sb = StringBuffer();
    final ar = language == 'ar';

    final labelHeader     = ar ? 'تحليل الرنين المغناطيسي للدماغ' : 'Brain MRI Analysis';
    final labelCondition  = ar ? 'الحالة المشخصة'         : 'Predicted Condition';
    final labelConfidence = ar ? 'الثقة'                  : 'Confidence';
    final labelUrgency    = ar ? 'الأولوية'               : 'Urgency';
    final labelOverview   = ar ? 'نظرة عامة'              : 'Overview';
    final labelSymptoms   = ar ? 'الأعراض الشائعة'        : 'Common Symptoms';
    final labelTreatment  = ar ? 'خيارات العلاج'          : 'Treatment Options';
    final labelSpecialist = ar ? 'استشر متخصصاً'          : 'See a Specialist';
    final labelEmergency  = ar ? 'تحذيرات طارئة'          : 'Emergency Warnings';
    final labelExpect     = ar ? 'ماذا تتوقع بعد ذلك'    : 'What To Expect Next';
    final labelSources    = ar ? 'المصادر'                : 'Sources';

    // ── Header ───────────────────────────────────────────────
    sb.writeln('${urgency.icon} **$labelHeader**');
    sb.writeln();

    if (personalizedIntro.isNotEmpty) {
      sb.writeln(personalizedIntro);
      sb.writeln();
    }

    // ── Scan result ──────────────────────────────────────────
    sb.writeln('─────────────────────');
    sb.writeln('**$labelCondition**: ${scanResult.predictedCondition}');
    sb.writeln('$labelConfidence: ${scanResult.modelConfidence} (${scanResult.confidenceLevel})');
    sb.writeln('$labelUrgency: ${urgency.icon} ${urgency.label}');
    sb.writeln();

    if (conditionOverview.isNotEmpty) {
      sb.writeln('📋 **$labelOverview**');
      sb.writeln(conditionOverview);
      sb.writeln();
    }

    if (commonSymptoms.isNotEmpty) {
      sb.writeln('🩺 **$labelSymptoms**');
      for (final s in commonSymptoms) { sb.writeln('• $s'); }
      sb.writeln();
    }

    if (treatmentOptions.isNotEmpty) {
      sb.writeln('💊 **$labelTreatment**');
      for (final t in treatmentOptions) { sb.writeln('• **${t.name}**: ${t.description}'); }
      sb.writeln();
    }

    if (specialistDoctors.isNotEmpty) {
      sb.writeln('👨‍⚕️ **$labelSpecialist**');
      for (final s in specialistDoctors) { sb.writeln('• **${s.specialty}** — ${s.role}'); }
      sb.writeln();
    }

    if (emergencyWarnings.isNotEmpty) {
      sb.writeln('🚨 **$labelEmergency**');
      for (final w in emergencyWarnings) { sb.writeln('⚠️ $w'); }
      sb.writeln();
    }

    if (whatToExpectNext.isNotEmpty) {
      sb.writeln('📅 **$labelExpect**');
      for (final s in whatToExpectNext) { sb.writeln('• $s'); }
      sb.writeln();
    }

    if (informationSources.isNotEmpty) {
      sb.writeln('📚 **$labelSources**');
      sb.writeln(informationSources.join(' · '));
      sb.writeln();
    }

    // ── Footer ───────────────────────────────────────────────
    sb.writeln('─────────────────────');
    sb.writeln('⚕️ *${scanResult.importantNote}*');
    if (generatedBy.isNotEmpty) {
      sb.writeln();
      sb.writeln('📚 *$generatedBy*');
    }

    return sb.toString().trim();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BrainFollowUpResult
// ──────────────────────────────────────────────────────────────────────────────

class BrainFollowUpResult {
  final String question;
  final String answer;
  final List<String> sourcesUsed;
  final bool groqUsed;

  const BrainFollowUpResult({
    required this.question,
    required this.answer,
    required this.sourcesUsed,
    required this.groqUsed,
  });

  factory BrainFollowUpResult.fromJson(Map<String, dynamic> j) =>
      BrainFollowUpResult(
        question:    j['question']    as String? ?? '',
        answer:      j['answer']      as String? ?? '',
        sourcesUsed: _toStringList(j['sources_used']),
        groqUsed:    j['groq_used']   as bool?   ?? false,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// BrainAnalysisService  — all /brain/* calls
// ──────────────────────────────────────────────────────────────────────────────

class BrainAnalysisService {
  BrainAnalysisService._();

  static final _client = http.Client();

  // ── POST /brain/analyze ──────────────────────────────────────────────────

  static Future<BrainAnalysisResult> analyze({
    required File imageFile,
    String patientNote = '',
    String language = 'en',
    bool includeDoctorSummary = false,
  }) async {
    final uri = Uri.parse('$kServerBaseUrl/brain/analyze');

    final request = http.MultipartRequest('POST', uri)
      ..fields['language']               = language
      ..fields['include_doctor_summary'] = includeDoctorSummary.toString();

    if (patientNote.isNotEmpty) {
      request.fields['reported_symptoms'] = patientNote;
    }

    request.files.add(await http.MultipartFile.fromPath(
      'file', imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    try {
      final streamed = await _client.send(request);
      final body     = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        String detail = 'HTTP ${streamed.statusCode}';
        try {
          final d = json.decode(body) as Map<String, dynamic>;
          detail = d['detail']?.toString() ?? detail;
        } catch (_) {}
        throw Exception(detail);
      }

      return BrainAnalysisResult.fromJson(
          json.decode(body) as Map<String, dynamic>);
    } on SocketException catch (e) {
      throw Exception(
        'Cannot reach server at $kServerBaseUrl. '
        'Ensure server.py is running. (${e.message})',
      );
    }
  }

  // ── POST /brain/followup ─────────────────────────────────────────────────

  static Future<BrainFollowUpResult> followUp({
    required String question,
    String? predictedClass,
    String language = 'en',
  }) async {
    final uri = Uri.parse('$kServerBaseUrl/brain/followup');

    try {
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({
          'question':  question,
          if (predictedClass != null) 'predicted_class': predictedClass,
          'language':  language,
        }),
      );

      if (res.statusCode != 200) {
        String detail = 'HTTP ${res.statusCode}';
        try {
          final d = json.decode(res.body) as Map<String, dynamic>;
          detail = d['detail']?.toString() ?? detail;
        } catch (_) {}
        throw Exception(detail);
      }

      return BrainFollowUpResult.fromJson(
          json.decode(res.body) as Map<String, dynamic>);
    } on SocketException catch (e) {
      throw Exception('Cannot reach server. (${e.message})');
    }
  }

  // ── POST /brain/cross-reference ──────────────────────────────────────────

  static Future<Map<String, dynamic>> crossReference({
    required String mriClass,
    required double mriConfidence,
    required List<String> reportedSymptoms,
    Map<String, dynamic>? symptomCheckerResult,
    String language = 'en',
  }) async {
    final uri = Uri.parse('$kServerBaseUrl/brain/cross-reference');

    try {
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({
          'mri_class':       mriClass,
          'mri_confidence':  mriConfidence,
          'reported_symptoms': reportedSymptoms,
          if (symptomCheckerResult != null)
            'symptom_checker_result': symptomCheckerResult,
          'language': language,
        }),
      );
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return json.decode(res.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw Exception('Cannot reach server. (${e.message})');
    }
  }

  // ── POST /brain/doctor-summary ───────────────────────────────────────────

  static Future<Map<String, dynamic>> doctorSummary({
    required String predictedClass,
    required double confidence,
    List<String>? reportedSymptoms,
    String language = 'en',
  }) async {
    final uri = Uri.parse('$kServerBaseUrl/brain/doctor-summary');

    try {
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({
          'predicted_class': predictedClass,
          'confidence':      confidence,
          if (reportedSymptoms != null) 'reported_symptoms': reportedSymptoms,
          'language':        language,
        }),
      );
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return json.decode(res.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw Exception('Cannot reach server. (${e.message})');
    }
  }

  // ── GET /brain/info/{class_key} ──────────────────────────────────────────

  static Future<Map<String, dynamic>> conditionInfo(String classKey) async {
    final uri = Uri.parse('$kServerBaseUrl/brain/info/$classKey');
    try {
      final res = await _client.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return json.decode(res.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw Exception('Cannot reach server. (${e.message})');
    }
  }

  // ── GET /brain/health ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> health() async {
    final uri = Uri.parse('$kServerBaseUrl/brain/health');
    try {
      final res = await _client.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return json.decode(res.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw Exception('Cannot reach server. (${e.message})');
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Endpoint constants  (kept for brain quick-test via PredictionService)
// ──────────────────────────────────────────────────────────────────────────────

const String kBrainEndpoint = 'brain';
const String kChestEndpoint = 'chest'; // legacy — new flow uses ChestAnalysisService

// ──────────────────────────────────────────────────────────────────────────────
// PredictionService  — brain quick-test only (unchanged call site in screen)
// ──────────────────────────────────────────────────────────────────────────────

class PredictionService {
  PredictionService._();

  static final _client = http.Client();

  static Future<PredictionResult> predict(File file, String endpoint) async {
    if (endpoint != kBrainEndpoint) {
      throw Exception(
        'PredictionService only handles "$kBrainEndpoint". '
        'Use ChestAnalysisService for chest X-ray.',
      );
    }

    final uri = Uri.parse('$kServerBaseUrl/predict/$endpoint');
    final sw  = Stopwatch()..start();

    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath(
          'file', file.path,
          contentType: MediaType('image', 'jpeg'),
        ));

      final streamed    = await _client.send(request);
      sw.stop();
      final inferenceMs = sw.elapsedMilliseconds;
      final body        = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        String detail = 'HTTP ${streamed.statusCode}';
        try {
          final d = json.decode(body) as Map<String, dynamic>;
          detail = d['detail']?.toString() ?? detail;
        } catch (_) {}
        throw Exception(detail);
      }

      final j = json.decode(body) as Map<String, dynamic>;
      return PredictionResult._brain(
        predictionLabel: j['prediction']  as String,
        confidenceRaw:   (j['confidence'] as num).toDouble(),
        probabilities:   (j['probabilities'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        inferenceTimeMs: inferenceMs,
      );
    } on SocketException catch (e) {
      throw Exception(
        'Cannot reach server at $kServerBaseUrl. (${e.message})',
      );
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ChatService  (unchanged)
// ──────────────────────────────────────────────────────────────────────────────

class ChatService {
  final String baseUrl;
  ChatService(this.baseUrl);

  static final _client = http.Client();

  Future<ChatResponse> sendMessage({
    required String message,
    required String sessionId,
    File? file,
    String? fileType,
    String? appLang,
  }) async {
    final uri = Uri.parse('$baseUrl/chat');

    try {
      int    statusCode;
      String body;

      if (file != null) {
        final request = http.MultipartRequest('POST', uri)
          ..fields['message']   = message
          ..fields['sessionId'] = sessionId;

        if (fileType != null) request.fields['fileType'] = fileType;
        if (appLang  != null) request.fields['appLang']  = appLang;

        request.files.add(await http.MultipartFile.fromPath(
          'file', file.path,
          contentType: MediaType('image', 'jpeg'),
        ));

        final streamed = await _client.send(request);
        statusCode = streamed.statusCode;
        body       = await streamed.stream.bytesToString();
      } else {
        final res = await _client.post(
          uri,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: json.encode({
            'message':   message,
            'sessionId': sessionId,
            if (appLang != null) 'appLang': appLang,
          }),
        );
        statusCode = res.statusCode;
        body       = res.body;
      }

      if (statusCode != 200) {
        String detail = 'HTTP $statusCode';
        try {
          final d = json.decode(body) as Map<String, dynamic>;
          detail  = d['detail']?.toString() ?? detail;
        } catch (_) {}
        return ChatResponse.failure(detail);
      }

      return _parseChatBody(body);
    } on SocketException catch (e) {
      return ChatResponse.failure(
        'Cannot reach chat server at $baseUrl. (${e.message})',
      );
    } catch (e) {
      return ChatResponse.failure('Unexpected error: $e');
    }
  }

  static ChatResponse _parseChatBody(String body) {
    try {
      final decoded   = json.decode(body) as Map<String, dynamic>;
      final response  = decoded['response']?.toString()       ?? '';
      final statusMsg = decoded['status_message']?.toString();
      return ChatResponse.success(
        response:      response,
        statusMessage: (statusMsg?.isNotEmpty == true) ? statusMsg : null,
      );
    } catch (_) {
      return ChatResponse.failure('Could not parse server response.');
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Private helpers
// ──────────────────────────────────────────────────────────────────────────────

List<String> _toStringList(dynamic raw) =>
    (raw as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];

/// Recursively extracts all leaf strings from a nested List/Map structure.
/// Used for common_symptoms which can be a plain `List<String>` or a nested
/// Map (e.g. pituitary tumor has vision_symptoms, hormonal_symptoms_by_type, etc.).
List<String> _extractStrings(dynamic raw) {
  if (raw == null) return const [];
  if (raw is String) return [raw];
  if (raw is List) {
    final result = <String>[];
    for (final item in raw) {
      result.addAll(_extractStrings(item));
    }
    return result;
  }
  if (raw is Map) {
    final result = <String>[];
    for (final entry in raw.entries) {
      if (entry.key == 'type') continue; // skip descriptor keys
      result.addAll(_extractStrings(entry.value));
    }
    return result;
  }
  return [raw.toString()];
}