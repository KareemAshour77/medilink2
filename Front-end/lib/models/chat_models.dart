// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// chat_models.dart
//
// Single source of truth for all data types used across the
// chat feature.  No Flutter/UI imports — pure Dart.
// ─────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart'; // only for Color

// ══════════════════════════════════════════════════════════
// Enums
// ══════════════════════════════════════════════════════════

/// Delivery state of a user-sent message.
enum MsgStatus { sending, sent, failed }

/// Content variant of a chat bubble.
///   • followUp — a selectable options card shown inside the conversation.
///   • report   — a bot bubble that displays a generated image/report (URL).
enum MsgType { text, image, file, thinking, followUp, report }

/// Medical document category chosen by the user.
enum AttachmentType { labResult, xray, prescription }

// ── AttachmentType helpers ────────────────────────────────
extension AttachmentTypeX on AttachmentType {
  Color get accentColor {
    switch (this) {
      case AttachmentType.labResult:    return Colors.teal;
      case AttachmentType.xray:         return Colors.purple;
      case AttachmentType.prescription: return Colors.blue;
    }
  }

  Color get bgColor {
    switch (this) {
      case AttachmentType.labResult:    return Colors.teal;
      case AttachmentType.xray:         return Colors.purple;
      case AttachmentType.prescription: return Colors.blue;
    }
  }
}

// ══════════════════════════════════════════════════════════
// Follow-up options (unified /chat → follow_up object)
//
// FastAPI may return, for ANY flow (symptoms, yes/no report
// confirmation, brain MRI, chest X-ray, lab, …):
//   "follow_up": {
//     "required": true,
//     "type": "symptom_choices",
//     "prompt": "…",
//     "allow_multiple": true,
//     "options": [ { "id", "symptom", "label" }, … ]
//   }
// These are pure-Dart models so they can be shared by the API
// layer and the widgets without any UI coupling.
// ══════════════════════════════════════════════════════════
class FollowUpOption {
  final String id;
  final String? label;
  final String? symptom;

  const FollowUpOption({required this.id, this.label, this.symptom});

  /// Text to render: prefer label, then symptom, then id.
  String get display {
    if (label != null && label!.trim().isNotEmpty) return label!.trim();
    if (symptom != null && symptom!.trim().isNotEmpty) return symptom!.trim();
    return id;
  }

  /// True for the special "none of the above" option.
  bool get isNone => id.toLowerCase() == 'none';

  factory FollowUpOption.fromJson(Map<String, dynamic> j) => FollowUpOption(
        id: (j['id'] ?? j['symptom'] ?? j['value'] ?? '').toString(),
        label: j['label']?.toString(),
        symptom: j['symptom']?.toString(),
      );
}

class FollowUp {
  final bool required;
  final String? type;
  final String? prompt;
  final bool allowMultiple;
  final List<FollowUpOption> options;

  const FollowUp({
    required this.required,
    this.type,
    this.prompt,
    required this.allowMultiple,
    required this.options,
  });

  bool get hasOptions => options.isNotEmpty;

  /// FastAPI uses two shapes:
  ///   • symptom flow      → `prompt` + `allow_multiple: true` + `type: symptom_choices`
  ///   • lab/xray/brain    → `question` + `type: yes_no | multi_choice`
  /// This parser accepts both so the card works for every flow.
  factory FollowUp.fromJson(Map<String, dynamic> j) {
    final rawOptions = (j['options'] as List<dynamic>?) ?? const [];
    final opts = rawOptions
        .whereType<Map>()
        .map((e) => FollowUpOption.fromJson(e.cast<String, dynamic>()))
        .where((o) => o.id.isNotEmpty)
        .toList();

    final type = j['type']?.toString();
    // Title comes from `prompt` (symptom flow) or `question` (lab/xray/brain).
    final title = (j['prompt']?.toString().trim().isNotEmpty == true)
        ? j['prompt']!.toString()
        : j['question']?.toString();

    // Multi-select if explicitly flagged OR the type implies many choices.
    final multi = j['allow_multiple'] == true ||
        type == 'multi_choice' ||
        type == 'symptom_choices';

    return FollowUp(
      required: j['required'] == true,
      type: type,
      prompt: title,
      allowMultiple: multi,
      options: opts,
    );
  }
}

// ══════════════════════════════════════════════════════════
// PendingFile — a file staged for sending (not yet in chat)
// ══════════════════════════════════════════════════════════
class PendingFile {
  final File file;
  final String fileName;
  final AttachmentType type;
  final bool fromCamera;

  const PendingFile({
    required this.file,
    required this.fileName,
    required this.type,
    required this.fromCamera,
  });
}

// ══════════════════════════════════════════════════════════
// ChatMessage — immutable chat bubble data
// ══════════════════════════════════════════════════════════
class ChatMessage {
  /// Stable ID used as widget key in AnimatedList.
  final String id;
  final String? text;
  final File? image;
  final File? fileData;
  final String? fileName;
  final bool isBot;
  final MsgType type;
  final MsgStatus status;

  /// Follow-up options payload (only for [MsgType.followUp]).
  final FollowUp? followUp;

  /// True once the user has confirmed this follow-up card (disables it).
  final bool answered;

  /// Generated report/image URL (only for [MsgType.report]).
  final String? imageUrl;

  /// Optional direct download URL for the report image.
  final String? downloadUrl;

  const ChatMessage._({
    required this.id,
    this.text,
    this.image,
    this.fileData,
    this.fileName,
    required this.isBot,
    required this.type,
    this.status = MsgStatus.sent,
    this.followUp,
    this.answered = false,
    this.imageUrl,
    this.downloadUrl,
  });

  // ── Factories ──────────────────────────────────────────

  factory ChatMessage.text(String text, bool isBot) => ChatMessage._(
        id: '${DateTime.now().microsecondsSinceEpoch}_${isBot ? 'bot' : 'usr'}',
        text: text,
        isBot: isBot,
        type: MsgType.text,
        // User messages begin as "sending"; bot replies are immediately "sent"
        status: isBot ? MsgStatus.sent : MsgStatus.sending,
      );

  factory ChatMessage.image(File file, bool isBot) => ChatMessage._(
        id: '${DateTime.now().microsecondsSinceEpoch}_img',
        image: file,
        isBot: isBot,
        type: MsgType.image,
      );

  factory ChatMessage.file(File file, String name, bool isBot) => ChatMessage._(
        id: '${DateTime.now().microsecondsSinceEpoch}_file',
        fileData: file,
        fileName: name,
        isBot: isBot,
        type: MsgType.file,
      );

  /// Transient card shown while the AI is processing.
  factory ChatMessage.thinking(String label) => ChatMessage._(
        id: '${DateTime.now().microsecondsSinceEpoch}_thinking',
        text: label,
        isBot: true,
        type: MsgType.thinking,
      );

  /// A selectable follow-up options card rendered inside the conversation.
  factory ChatMessage.followUp(FollowUp data) => ChatMessage._(
        id: '${DateTime.now().microsecondsSinceEpoch}_followup',
        isBot: true,
        type: MsgType.followUp,
        followUp: data,
      );

  /// A bot bubble that renders a generated report/image from a URL.
  factory ChatMessage.report({
    required String imageUrl,
    String? downloadUrl,
  }) =>
      ChatMessage._(
        id: '${DateTime.now().microsecondsSinceEpoch}_report',
        isBot: true,
        type: MsgType.report,
        imageUrl: imageUrl,
        downloadUrl: downloadUrl,
      );

  // ── Convenience getters ────────────────────────────────
  bool get isImage    => type == MsgType.image;
  bool get isFile     => type == MsgType.file;
  bool get isThinking => type == MsgType.thinking;
  bool get isFollowUp => type == MsgType.followUp;
  bool get isReport   => type == MsgType.report;

  /// Returns a copy with an updated [MsgStatus] (immutable update pattern).
  ChatMessage withStatus(MsgStatus s) => _copy(status: s);

  /// Returns a copy marked as answered (used to disable a follow-up card).
  ChatMessage markAnswered() => _copy(answered: true);

  ChatMessage _copy({MsgStatus? status, bool? answered}) => ChatMessage._(
        id: id,
        text: text,
        image: image,
        fileData: fileData,
        fileName: fileName,
        isBot: isBot,
        type: type,
        status: status ?? this.status,
        followUp: followUp,
        answered: answered ?? this.answered,
        imageUrl: imageUrl,
        downloadUrl: downloadUrl,
      );
}
