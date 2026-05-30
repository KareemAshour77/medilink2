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
enum MsgType { text, image, file, thinking }

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

  const ChatMessage._({
    required this.id,
    this.text,
    this.image,
    this.fileData,
    this.fileName,
    required this.isBot,
    required this.type,
    this.status = MsgStatus.sent,
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

  // ── Convenience getters ────────────────────────────────
  bool get isImage    => type == MsgType.image;
  bool get isFile     => type == MsgType.file;
  bool get isThinking => type == MsgType.thinking;

  /// Returns a copy with an updated [MsgStatus] (immutable update pattern).
  ChatMessage withStatus(MsgStatus s) => ChatMessage._(
        id: id,
        text: text,
        image: image,
        fileData: fileData,
        fileName: fileName,
        isBot: isBot,
        type: type,
        status: s,
      );
}
