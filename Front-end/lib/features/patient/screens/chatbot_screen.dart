// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// chat_screen.dart
//
//   ✅ Chest X-ray → ChestAnalysisService (/chest/analyze)
//      DenseNet-121, 15-class, top-2 findings + RAG report.
//   ✅ Brain MRI   → BrainAnalysisService (/brain/analyze)
//      Custom CNN, 4-class, prediction + RAG report + Groq.
//   ✅ Both flows: optional patient note → image → report →
//      follow-up Q&A mode until the user ends the session.
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
import '../../../core/widgets/attachment_preview.dart';

// ── Small reusable sub-widgets for picker sheets ──────────
part '../../../core/widgets/_attachment_sheet_widgets.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // ── Controllers ──────────────────────────────────────────
  final _textCtrl   = TextEditingController();
  final _scroll     = ScrollController();
  final _picker     = ImagePicker();

  // ── State ────────────────────────────────────────────────
  final _messages     = <ChatMessage>[];
  final _pendingFiles = <PendingFile>[];

  bool _initialized    = false;
  bool _typing         = false;
  bool _userScrolledUp = false;

  /// Set after a chest X-ray analysis — routes text to ChestAnalysisService.followUp().
  ChestAnalysisResult? _lastChestResult;

  /// Set after a brain MRI analysis — routes text to BrainAnalysisService.followUp().
  BrainAnalysisResult? _lastBrainResult;

  // ── Services ─────────────────────────────────────────────
  final _chatService = ChatService(kServerBaseUrl);
  final String _sessionId =
      DateTime.now().millisecondsSinceEpoch.toString();

  // ════════════════════════════════════════════════════════
  // Lifecycle
  // ════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final distFromBottom =
          _scroll.position.maxScrollExtent - _scroll.offset;
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
  // Scroll helpers
  // ════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════
  // Core send handler — text and generic file messages
  // ════════════════════════════════════════════════════════

  Future<void> _handleSend({
    File? file,
    String? fileName,
    bool isPrescription = false,
  }) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && file == null) return;

    setState(() {
      if (text.isNotEmpty) _messages.add(ChatMessage.text(text, false));
      if (file != null) {
        final ext   = fileName?.split('.').last.toLowerCase() ?? '';
        final isImg = _isImageExt(ext);
        _messages.add(
          isImg
              ? ChatMessage.image(file, false)
              : ChatMessage.file(file, fileName ?? 'file', false),
        );
      }
      _textCtrl.clear();
      _typing         = true;
      _userScrolledUp = false;
    });
    _scrollDown(force: true);

    try {
      if (file != null) {
        await _handleFileMessage(
            file: file, fileName: fileName, isPrescription: isPrescription);
      } else if (_lastBrainResult != null) {
        await _handleBrainFollowUp(text);
      } else if (_lastChestResult != null) {
        await _handleChestFollowUp(text);
      } else {
        final res = await _chatService.sendMessage(
          message:   text,
          sessionId: _sessionId,
          appLang:   langNotifier.value.languageCode,
        );
        setState(() {
          _markLastUserMsgSent();
          _messages.add(ChatMessage.text(res.response, true));
          _typing = false;
        });
      }
    } catch (e) {
      _handleSendError(e);
    }

    _scrollDown();
  }

  Future<void> _handleFileMessage({
    required File file,
    required String? fileName,
    required bool isPrescription,
  }) async {
    final ext     = fileName?.split('.').last.toLowerCase() ?? '';
    final isImg   = _isImageExt(ext);
    final appLang = langNotifier.value.languageCode;

    if (isImg) {
      final fileType     = isPrescription ? 'prescription' : 'auto';
      final thinkingLabel = isPrescription
          ? '💊 Reading prescription...'
          : '🔬 Analyzing image...';

      await _sendWithThinkingCardFull(
        label: thinkingLabel,
        call: () => _chatService.sendMessage(
          message:   isPrescription ? 'prescription' : '',
          sessionId: _sessionId,
          file:      file,
          fileType:  fileType,
          appLang:   appLang,
        ),
      );
    } else {
      await _sendWithThinkingCard(
        label: '📄 Processing your document...',
        call: () async {
          final res = await _chatService.sendMessage(
            message:   'User uploaded a file: $fileName',
            sessionId: _sessionId,
            file:      file,
            fileType:  'auto',
            appLang:   appLang,
          );
          return res.response;
        },
      );
    }
  }

  Future<void> _sendWithThinkingCard({
    required String label,
    required Future<String> Function() call,
  }) async {
    setState(() => _messages.add(ChatMessage.thinking(label)));
    _scrollDown();
    try {
      final reply = await call();
      setState(() {
        _removeThinkingCard();
        _markLastUserMsgSent();
        _messages.add(ChatMessage.text(reply, true));
        _typing = false;
      });
    } catch (e) {
      setState(() => _removeThinkingCard());
      rethrow;
    }
  }

  Future<void> _sendWithThinkingCardFull({
    required String label,
    required Future<ChatResponse> Function() call,
  }) async {
    setState(() => _messages.add(ChatMessage.thinking(label)));
    _scrollDown();
    try {
      final res = await call();
      setState(() {
        _removeThinkingCard();
        _markLastUserMsgSent();
        if (res.statusMessage != null && res.statusMessage!.isNotEmpty) {
          _messages.add(ChatMessage.text(res.statusMessage!, true));
        }
        _messages.add(ChatMessage.text(res.response, true));
        _typing = false;
      });
      _scrollDown();
    } catch (e) {
      setState(() => _removeThinkingCard());
      rethrow;
    }
  }

  void _handleSendError(Object e) {
    setState(() {
      final idx = _messages
          .lastIndexWhere((m) => !m.isBot && m.type == MsgType.text);
      if (idx != -1) {
        _messages[idx] = _messages[idx].withStatus(MsgStatus.failed);
      }
      _removeThinkingCard();
      _messages.add(ChatMessage.text('⚠️ $e', true));
      _typing = false;
    });
  }

  void _removeThinkingCard() {
    if (_messages.isNotEmpty && _messages.last.isThinking) {
      _messages.removeLast();
    }
  }

  void _markLastUserMsgSent() {
    final idx = _messages
        .lastIndexWhere((m) => !m.isBot && m.type == MsgType.text);
    if (idx != -1) {
      _messages[idx] = _messages[idx].withStatus(MsgStatus.sent);
    }
  }

  bool _isImageExt(String ext) =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

  bool _isImageFile(String name) =>
      _isImageExt(name.split('.').last.toLowerCase());

  // ════════════════════════════════════════════════════════
  // Chest follow-up Q&A
  // ════════════════════════════════════════════════════════

  static const _noReplies = {
    'no', 'nope', 'nah', 'no thanks', 'no thank you', 'not now',
    'none', 'nothing', 'stop', 'end', 'exit', 'cancel', 'done', 'ok', 'okay',
    'لا', 'لأ', 'لا شكرا', 'لا شكراً', 'لا، شكرا', 'انهاء', 'إنهاء', 'كفاية',
  };

  bool _isNoReply(String text) =>
      _noReplies.contains(text.toLowerCase().trim());

  Future<void> _handleChestFollowUp(String question) async {
    final isAr = langNotifier.value.languageCode == 'ar';

    if (_isNoReply(question)) {
      setState(() {
        _lastChestResult = null;
        _markLastUserMsgSent();
        _messages.add(ChatMessage.text(
          isAr
              ? 'حسناً! إذا احتجت أي مساعدة أخرى، أنا هنا.'
              : 'Got it! Let me know if you need anything else.',
          true,
        ));
        _typing = false;
      });
      return;
    }

    final diseaseKey = (_lastChestResult!.findings.isNotEmpty)
        ? _lastChestResult!.findings.first.classKey
        : null;
    final lang = isAr ? 'ar' : 'en';

    await _sendWithThinkingCard(
      label: '🫁 Looking up your question…',
      call: () async {
        final result = await ChestAnalysisService.followUp(
          question:   question,
          diseaseKey: diseaseKey,
          language:   lang,
        );
        return result.answer;
      },
    );

    // Prompt the user to continue or end follow-up mode.
    if (mounted && _lastChestResult != null) {
      setState(() => _messages.add(ChatMessage.text(
        isAr
            ? '❓ هل لديك سؤال آخر حول نتائج الأشعة؟'
            : '❓ Do you have another question about your X-ray findings?',
        true,
      )));
      _scrollDown();
    }
  }

  // ════════════════════════════════════════════════════════
  // Brain MRI follow-up Q&A
  // ════════════════════════════════════════════════════════

  Future<void> _handleBrainFollowUp(String question) async {
    final isAr = langNotifier.value.languageCode == 'ar';

    if (_isNoReply(question)) {
      setState(() {
        _lastBrainResult = null;
        _markLastUserMsgSent();
        _messages.add(ChatMessage.text(
          isAr
              ? 'حسناً! إذا احتجت أي مساعدة أخرى، أنا هنا.'
              : 'Got it! Let me know if you need anything else.',
          true,
        ));
        _typing = false;
      });
      return;
    }

    final predictedClass = _lastBrainResult!.predictedClass.isNotEmpty
        ? _lastBrainResult!.predictedClass
        : null;
    final lang = isAr ? 'ar' : 'en';

    await _sendWithThinkingCard(
      label: '🧠 Looking up your question…',
      call: () async {
        final result = await BrainAnalysisService.followUp(
          question:       question,
          predictedClass: predictedClass,
          language:       lang,
        );
        return result.answer;
      },
    );

    if (mounted && _lastBrainResult != null) {
      setState(() => _messages.add(ChatMessage.text(
        isAr
            ? '❓ هل لديك سؤال آخر حول نتائج الرنين المغناطيسي؟'
            : '❓ Do you have another question about your MRI findings?',
        true,
      )));
      _scrollDown();
    }
  }

  // ════════════════════════════════════════════════════════
  // Chest X-ray flow
  //
  // 1. Ask the patient for an optional note (symptoms / context).
  // 2. Open gallery — pick exactly ONE photo.
  // 3. Show the image bubble + thinking card.
  // 4. Call ChestAnalysisService.analyze() with the note.
  // 5. Render the structured report as a chat message.
  // ════════════════════════════════════════════════════════

  Future<void> _runChestXrayFlow() async {
    // ── Step 1: pick one photo ────────────────────────────
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    HapticFeedback.lightImpact();

    // ── Step 2: collect optional patient note ─────────────
    final note = await _showPatientNoteDialog();
    // note == null  → user cancelled the dialog entirely
    // note == ''    → user tapped "Skip" or cleared the field
    if (note == null) return;

    final file = File(picked.path);

    // ── Step 3: add bubbles ───────────────────────────────
    setState(() {
      if (note.isNotEmpty) {
        _messages.add(ChatMessage.text(note, false));
      }
      _messages.add(ChatMessage.image(file, false));
      _messages.add(ChatMessage.thinking('🫁 Analyzing chest X-ray…'));
      _typing         = true;
      _userScrolledUp = false;
    });
    _scrollDown(force: true);

    // ── Step 4: call /chest/analyze ──────────────────────
    try {
      final result = await ChestAnalysisService.analyze(
        imageFile:   file,
        patientNote: note,
        language:    langNotifier.value.languageCode == 'ar' ? 'ar' : 'en',
      );

      // ── Step 5: render report ─────────────────────────
      final reportText = result.toChatMessage();
      final isAr = langNotifier.value.languageCode == 'ar';

      setState(() {
        _removeThinkingCard();
        _markLastUserMsgSent();
        _messages.add(ChatMessage.text(reportText, true));
        _messages.add(ChatMessage.text(
          isAr
              ? '💬 يمكنك الآن طرح أسئلة متابعة حول نتائج الأشعة.'
              : '💬 You can now ask follow-up questions about these findings.',
          true,
        ));
        _lastChestResult = result;
        _typing = false;
      });
    } catch (e) {
      _handleSendError(e);
    }

    _scrollDown();
  }

  /// Shows a bottom-sheet dialog where the patient can type symptoms or context
  /// before sending the X-ray.  Returns the trimmed text, empty string if
  /// skipped, or null if cancelled.
  Future<String?> _showPatientNoteDialog() {
    final ctrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🫁 Chest X-ray Analysis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Add any symptoms or notes (optional)',
                style: TextStyle(fontSize: 12, color: ctx.text.withOpacity(0.5)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLines: 3,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'e.g. cough, shortness of breath, chest pain…',
                  hintStyle: TextStyle(color: ctx.text.withOpacity(0.35)),
                  filled: true,
                  fillColor: ctx.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Send',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  // Brain MRI flow — full analysis (mirrors chest X-ray flow)
  //
  // 1. Pick one MRI photo from gallery.
  // 2. Optional patient note (symptoms / context).
  // 3. Call BrainAnalysisService.analyze().
  // 4. Render structured report as chat message.
  // 5. Enter follow-up Q&A mode.
  // ════════════════════════════════════════════════════════

  Future<void> _runBrainMriFlow() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    HapticFeedback.lightImpact();

    final note = await _showBrainNoteDialog();
    if (note == null) return; // user cancelled

    final file = File(picked.path);

    setState(() {
      if (note.isNotEmpty) _messages.add(ChatMessage.text(note, false));
      _messages.add(ChatMessage.image(file, false));
      _messages.add(ChatMessage.thinking('🧠 Analyzing brain MRI…'));
      _typing         = true;
      _userScrolledUp = false;
      _lastChestResult = null; // clear other follow-up mode
    });
    _scrollDown(force: true);

    try {
      final result = await BrainAnalysisService.analyze(
        imageFile:   file,
        patientNote: note,
        language:    langNotifier.value.languageCode == 'ar' ? 'ar' : 'en',
      );

      final reportText = result.toChatMessage();
      final isAr = langNotifier.value.languageCode == 'ar';

      setState(() {
        _removeThinkingCard();
        _markLastUserMsgSent();
        _messages.add(ChatMessage.text(reportText, true));
        _messages.add(ChatMessage.text(
          isAr
              ? '💬 يمكنك الآن طرح أسئلة متابعة حول نتائج الرنين المغناطيسي.'
              : '💬 You can now ask follow-up questions about these MRI findings.',
          true,
        ));
        _lastBrainResult = result;
        _typing = false;
      });
    } catch (e) {
      _handleSendError(e);
    }
    _scrollDown();
  }

  Future<String?> _showBrainNoteDialog() {
    final ctrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🧠 Brain MRI Analysis',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Add any symptoms or notes (optional)',
                style: TextStyle(fontSize: 12, color: ctx.text.withOpacity(0.5)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLines: 3,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'e.g. headache, blurred vision, morning nausea…',
                  hintStyle: TextStyle(color: ctx.text.withOpacity(0.35)),
                  filled: true,
                  fillColor: ctx.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Send',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  // Attachment queue (generic / PDF flow)
  // ════════════════════════════════════════════════════════

  Future<void> _pickMedia({
    required ImageSource source,
    required AttachmentType type,
  }) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    HapticFeedback.lightImpact();
    _addToPendingQueue(
      file:       File(picked.path),
      fileName:   picked.name,
      type:       type,
      fromCamera: source == ImageSource.camera,
    );
  }

  Future<void> _pickFileForQueue(AttachmentType type) async {
    final result = await FilePicker.pickFiles(
      type:              FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple:     true,
    );
    if (result == null || result.files.isEmpty) return;
    HapticFeedback.lightImpact();
    for (final f in result.files) {
      if (f.path == null) continue;
      _addToPendingQueue(
        file:       File(f.path!),
        fileName:   f.name,
        type:       type,
        fromCamera: false,
      );
    }
  }

  void _addToPendingQueue({
    required File file,
    required String fileName,
    required AttachmentType type,
    required bool fromCamera,
  }) {
    setState(() {
      _pendingFiles.add(PendingFile(
        file:       file,
        fileName:   fileName,
        type:       type,
        fromCamera: fromCamera,
      ));
    });
    _showPreviewSheet();
  }

  Future<void> _sendPendingFiles() async {
    final files = List<PendingFile>.from(_pendingFiles);
    setState(() => _pendingFiles.clear());
    for (final pf in files) {
      await _handleSend(
        file:           pf.file,
        fileName:       pf.fileName,
        isPrescription: pf.type == AttachmentType.prescription,
      );
    }
  }

  // ════════════════════════════════════════════════════════
  // Bottom sheets
  // ════════════════════════════════════════════════════════

  void _showPreviewSheet() {
    showModalBottomSheet(
      context:             context,
      backgroundColor:     context.card,
      isScrollControlled:  true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AttachmentPreview(
        files:    _pendingFiles,
        onRemove: (i) => setState(() => _pendingFiles.removeAt(i)),
        onRetake: (i) async {
          setState(() => _pendingFiles.removeAt(i));
          await _pickMedia(
              source: ImageSource.camera, type: AttachmentType.xray);
        },
        onAddMore: () {
          Navigator.pop(context);
          _showAttachmentSheet();
        },
        onSend: () {
          Navigator.pop(context);
          _sendPendingFiles();
        },
      ),
    );
  }

  /// Attachment sheet — three actions:
  ///   PDF      → generic file queue
  ///   X-Ray    → full chest analysis flow (NEW)
  ///   Brain    → brain quick-test
  ///   OCR      → OCR model test
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
          _pickFileForQueue(AttachmentType.labResult);
        },
        // ── Chest X-ray → new full analysis flow ──────────
        onXray: () {
          Navigator.pop(context);
          _runChestXrayFlow();          // ← replaces old _testModel('chest', …)
        },
        // ── Brain MRI → full analysis flow ────────────────
        onBrain: () {
          Navigator.pop(context);
          _runBrainMriFlow();
        },
        onOcr: () {
          Navigator.pop(context);
          // OCR test — reuse PredictionService with its own endpoint when ready
          _showComingSoon('OCR');
        },
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature model coming soon'),
        duration: const Duration(seconds: 2),
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
            messages:         _messages,
            isTyping:         _typing,
            scrollController: _scroll,
            onRetry: (msg) => _handleSend(
              file:     msg.fileData,
              fileName: msg.fileName,
            ),
          ),
        ),
        if (_lastChestResult != null || _lastBrainResult != null) _buildFollowUpBanner(),
        MessageInputBar(
          controller:      _textCtrl,
          hintText:        l.typingHint,
          onSend:          _handleSend,
          onAttachmentTap: _showAttachmentSheet,
        ),
      ]),
    );
  }

  Widget _buildFollowUpBanner() {
    final isAr = langNotifier.value.languageCode == 'ar';

    final String label;
    final VoidCallback onDismiss;

    if (_lastBrainResult != null) {
      final condition = _lastBrainResult!.scanResult.predictedCondition.isNotEmpty
          ? _lastBrainResult!.scanResult.predictedCondition
          : 'Brain MRI';
      label     = isAr ? 'وضع المتابعة: $condition' : 'Follow-up: $condition';
      onDismiss = () => setState(() => _lastBrainResult = null);
    } else {
      final finding = _lastChestResult!.findings.isNotEmpty
          ? _lastChestResult!.findings.first.displayName
          : 'X-ray';
      label     = isAr ? 'وضع المتابعة: $finding' : 'Follow-up: $finding';
      onDismiss = () => setState(() => _lastChestResult = null);
    }

    final dismiss = isAr ? 'إنهاء' : 'End';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withOpacity(0.08),
      child: Row(children: [
        const Icon(Icons.chat_bubble_outline_rounded,
            size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500),
          ),
        ),
        GestureDetector(
          onTap: onDismiss,
          child: Text(
            dismiss,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onDismiss,
          child: const Icon(Icons.close_rounded,
              size: 16, color: AppColors.primary),
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
                color: context.text,
                fontSize: 16,
                fontWeight: FontWeight.bold),
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