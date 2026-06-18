// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// chatbot_screen.dart  (MediBot — AI assistant)
//
// Talks to the UNIFIED FastAPI /chat endpoint for everything:
//   text chat, symptom checking, disease Q&A, medicine info,
//   lab reports, prescriptions, chest X-ray, brain MRI.
//
// The frontend never sends an intent — the backend classifies
// the message/file and may reply with:
//   • plain text
//   • a generated report image  (image_url)
//   • a follow_up options card   (follow_up.required == true)
//
// Follow-up choices continue the SAME session with only
// { session_id, app_lang, follow_up_choices } — the original
// message/file is never re-sent.
// ─────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/services/api_ai.dart';
import '../../../core/theme/app_theme.dart';

import '../../../models/chat_models.dart';
import '../../../core/widgets/messages_list.dart';
import '../../../core/widgets/message_input_bar.dart';

// ── Small reusable sub-widgets for picker sheets ──────────
part '../../../core/widgets/_attachment_sheet_widgets.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // ── Controllers ──────────────────────────────────────────
  final _textCtrl = TextEditingController();
  final _scroll   = ScrollController();
  final _picker   = ImagePicker();

  // ── State ────────────────────────────────────────────────
  final _messages = <ChatMessage>[];

  bool _initialized    = false;
  bool _typing         = false;
  bool _userScrolledUp = false;

  /// True while a required follow-up card is visible and waiting for an answer
  /// — the composer is disabled until the user picks an option.
  bool _followUpPending = false;

  // ── Deferred reveal ──────────────────────────────────────
  // Report image + follow-up card are revealed only AFTER the AI text finishes
  // typing. They are stashed here, keyed to the bot text message id, until that
  // message reports completion via [_onBotTextComplete].
  FollowUp? _deferredFollowUp;
  String?   _deferredReportUrl;
  String?   _deferredReportDownload;
  String?   _revealAnchorId;

  /// Report URLs already shown — avoids duplicate cards when a later response
  /// repeats the same report_image_url.
  final _shownReportUrls = <String>{};

  // ── Services ─────────────────────────────────────────────
  final _chatService = ChatService(kServerBaseUrl);

  /// Stable session id. Adopted from FastAPI's response so the backend keeps
  /// the same flow/session across follow-ups.
  String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

  // ════════════════════════════════════════════════════════
  // Lifecycle
  // ════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final distFromBottom = _scroll.position.maxScrollExtent - _scroll.offset;
      _userScrolledUp = distFromBottom > 80;
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════
  // Helpers
  // ════════════════════════════════════════════════════════

  /// Current backend language — 'ar' for Arabic, 'en' for anything else.
  String get _appLang =>
      langNotifier.value.languageCode == 'ar' ? 'ar' : 'en';

  bool get _isAr => _appLang == 'ar';

  /// Single, coalesced scroll-to-bottom. Skips if the user scrolled up
  /// (unless [force]) to avoid fighting the user / multiple auto-scrolls.
  void _scrollDown({bool force = false}) {
    if (!force && _userScrolledUp) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  bool _isImageExt(String ext) =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext);

  String _processingLabel(bool isImage) {
    if (isImage) return _isAr ? '🔬 جاري تحليل الصورة…' : '🔬 Analyzing image…';
    return _isAr ? '📄 جاري معالجة الملف…' : '📄 Processing your file…';
  }

  void _removeThinkingCard() {
    if (_messages.isNotEmpty && _messages.last.isThinking) {
      _messages.removeLast();
    }
  }

  void _markLastUserMsgSent() {
    final idx =
        _messages.lastIndexWhere((m) => !m.isBot && m.type == MsgType.text);
    if (idx != -1) {
      _messages[idx] = _messages[idx].withStatus(MsgStatus.sent);
    }
  }

  /// Adds the AI text immediately, then DEFERS the report image and follow-up
  /// card until that text finishes typing (revealed in [_onBotTextComplete]).
  /// Must be called inside setState.
  void _renderResponse(ChatResponse res) {
    if (!res.isSuccess) {
      _messages.add(ChatMessage.text(res.response, true));
      return;
    }
    // Adopt the backend session id so follow-ups resume the same flow.
    if (res.sessionId != null && res.sessionId!.isNotEmpty) {
      _sessionId = res.sessionId!;
    }

    // Text bubbles type out first; the last one is the "anchor" we wait on.
    String? anchorId;
    if (res.statusMessage != null && res.statusMessage!.isNotEmpty) {
      final m = ChatMessage.text(res.statusMessage!, true);
      _messages.add(m);
      anchorId = m.id;
    }
    if (res.response.trim().isNotEmpty) {
      final m = ChatMessage.text(res.response, true);
      _messages.add(m);
      anchorId = m.id;
    }

    // Report image — skip duplicates of an already-shown URL.
    String? reportUrl = res.hasImage ? res.imageUrl : null;
    if (reportUrl != null && !_shownReportUrls.add(reportUrl)) reportUrl = null;
    final followUp = res.hasFollowUp ? res.followUp : null;

    if (reportUrl == null && followUp == null) return;

    if (anchorId == null) {
      // No text to type → reveal immediately.
      _revealExtras(reportUrl, res.downloadUrl, followUp);
    } else {
      // Defer until the anchor text finishes typing.
      _deferredReportUrl      = reportUrl;
      _deferredReportDownload = res.downloadUrl;
      _deferredFollowUp       = followUp;
      _revealAnchorId         = anchorId;
    }
  }

  /// Appends the deferred report image + follow-up card. Must run inside setState.
  void _revealExtras(String? reportUrl, String? downloadUrl, FollowUp? followUp) {
    if (reportUrl != null) {
      _messages.add(ChatMessage.report(
        imageUrl: reportUrl,
        downloadUrl: downloadUrl,
      ));
    }
    if (followUp != null) {
      _messages.add(ChatMessage.followUp(followUp));
      _followUpPending = true; // lock the composer until answered
    }
  }

  /// Called when a bot text bubble finishes typing. If it's the anchor for a
  /// deferred reveal, show the report image + follow-up card now.
  void _onBotTextComplete(String id) {
    if (id != _revealAnchorId) return;
    final reportUrl = _deferredReportUrl;
    final download  = _deferredReportDownload;
    final followUp  = _deferredFollowUp;
    _revealAnchorId = null;
    _deferredReportUrl = null;
    _deferredReportDownload = null;
    _deferredFollowUp = null;
    if (reportUrl == null && followUp == null) return;
    setState(() => _revealExtras(reportUrl, download, followUp));
    _scrollDown();
  }

  void _handleSendError(Object e) {
    if (!mounted) return;
    setState(() {
      final idx =
          _messages.lastIndexWhere((m) => !m.isBot && m.type == MsgType.text);
      if (idx != -1) {
        _messages[idx] = _messages[idx].withStatus(MsgStatus.failed);
      }
      _removeThinkingCard();
      _messages.add(ChatMessage.text('⚠️ $e', true));
      _typing = false;
    });
  }

  // ════════════════════════════════════════════════════════
  // Send: text
  // ════════════════════════════════════════════════════════

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage.text(text, false));
      _textCtrl.clear();
      _typing         = true; // normal typing animation for text replies
      _userScrolledUp = false;
    });
    _scrollDown(force: true);

    try {
      final res = await _chatService.sendMessage(
        message:   text,
        sessionId: _sessionId,
        appLang:   _appLang,
      );
      if (!mounted) return;
      setState(() {
        _markLastUserMsgSent();
        _typing = false;
        _renderResponse(res);
      });
    } catch (e) {
      _handleSendError(e);
    }
    _scrollDown();
  }

  Future<void> _retryMessage(ChatMessage msg) async {
    if (msg.text == null || msg.text!.isEmpty) return;
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) _messages[idx] = _messages[idx].withStatus(MsgStatus.sending);
      _typing = true;
    });
    try {
      final res = await _chatService.sendMessage(
        message:   msg.text!,
        sessionId: _sessionId,
        appLang:   _appLang,
      );
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx != -1) _messages[idx] = _messages[idx].withStatus(MsgStatus.sent);
        _typing = false;
        _renderResponse(res);
      });
    } catch (e) {
      _handleSendError(e);
    }
    _scrollDown();
  }

  // ════════════════════════════════════════════════════════
  // Send: file (PDF / image) — unified, with a processing card
  // (NOT the normal typing animation).
  // ════════════════════════════════════════════════════════

  Future<void> _sendFile({
    required File file,
    required String fileName,
    required bool isImage,
  }) async {
    setState(() {
      _messages.add(
        isImage
            ? ChatMessage.image(file, false)
            : ChatMessage.file(file, fileName, false),
      );
      _messages.add(ChatMessage.thinking(_processingLabel(isImage)));
      _typing         = false; // file analysis uses the processing card only
      _userScrolledUp = false;
    });
    _scrollDown(force: true);

    try {
      final res = await _chatService.sendMessage(
        message:   '',
        sessionId: _sessionId,
        file:      file,
        fileType:  'auto',
        appLang:   _appLang,
      );
      if (!mounted) return;
      setState(() {
        _removeThinkingCard();
        _renderResponse(res);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _removeThinkingCard();
        _messages.add(ChatMessage.text('⚠️ $e', true));
      });
    }
    _scrollDown();
  }

  // ════════════════════════════════════════════════════════
  // Follow-up choices — continue the SAME session.
  // Sends only { session_id, app_lang, follow_up_choices }.
  // ════════════════════════════════════════════════════════

  Future<void> _submitFollowUp(ChatMessage msg, List<String> ids) async {
    if (ids.isEmpty || msg.followUp == null) return;

    // Human-readable summary of the choices (UI only — NOT sent to the API).
    final labels = <String>[
      for (final id in ids)
        msg.followUp!.options
            .firstWhere((o) => o.id == id,
                orElse: () => FollowUpOption(id: id))
            .display,
    ];
    final separator = _isAr ? '، ' : ', ';

    setState(() {
      // Lock the answered card so it can't be submitted twice + re-enable input.
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) _messages[idx] = _messages[idx].markAnswered();
      _followUpPending = false;
      // Small user bubble summarising the selection.
      _messages.add(ChatMessage.text(labels.join(separator), false));
      _typing         = true;
      _userScrolledUp = false;
    });
    _scrollDown(force: true);

    try {
      final res = await _chatService.sendFollowUp(
        sessionId: _sessionId,
        appLang:   _appLang,
        choices:   ids,
      );
      if (!mounted) return;
      setState(() {
        _markLastUserMsgSent();
        _typing = false;
        _renderResponse(res);
      });
    } catch (e) {
      _handleSendError(e);
    }
    _scrollDown();
  }

  // ════════════════════════════════════════════════════════
  // Pickers
  // ════════════════════════════════════════════════════════

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type:              FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple:     false,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.path == null) return;
    HapticFeedback.lightImpact();
    await _sendFile(file: File(f.path!), fileName: f.name, isImage: false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    HapticFeedback.lightImpact();
    await _sendFile(
      file:     File(picked.path),
      fileName: picked.name,
      isImage:  true,
    );
  }

  // ════════════════════════════════════════════════════════
  // Bottom sheets
  // ════════════════════════════════════════════════════════

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AttachmentSheet(
        onPdf: () {
          Navigator.pop(context);
          _pickPdf();
        },
        onImage: () {
          Navigator.pop(context);
          _showImageSourceSheet();
        },
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_camera_rounded,
                      color: AppColors.primary),
                ),
                title: Text(_isAr ? 'التقاط صورة' : 'Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                ),
                title: Text(_isAr ? 'اختيار من المعرض' : 'Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // Build
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final l = context.l;

    if (!_initialized) {
      _messages.add(ChatMessage.text(l.medibotGreeting, true));
      _initialized = true;
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(children: [
        Expanded(
          child: MessagesList(
            messages:          _messages,
            isTyping:          _typing,
            scrollController:  _scroll,
            isArabic:          _isAr,
            onRetry:           _retryMessage,
            onFollowUpSubmit:  _submitFollowUp,
            onBotTextComplete: _onBotTextComplete,
          ),
        ),
        MessageInputBar(
          controller:      _textCtrl,
          hintText:        _followUpPending
              ? (_isAr ? 'اختر من الأعلى للمتابعة…' : 'Choose above to continue…')
              : l.typingHint,
          enabled:         !_followUpPending,
          onSend:          _sendText,
          onAttachmentTap: _showAttachmentSheet,
        ),
      ]),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: context.text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'MediBot',
            style: TextStyle(
                color: context.text, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Online',
            style: TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ]),
      ]),
    );
  }
}
