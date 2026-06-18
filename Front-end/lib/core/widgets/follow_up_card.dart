// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// widgets/follow_up_card.dart
//
// A selectable options card rendered INSIDE the conversation,
// directly under an AI message, whenever FastAPI returns a
// follow-up with options (symptom choices, yes/no report
// confirmation, brain MRI, chest X-ray, lab, …).
//
// AUTO-SUBMIT — there is NO Send button:
//   • single-select / yes-no → tapping an option submits it instantly.
//   • multi-select           → submits automatically a short moment after
//                              the user stops tapping (debounce).
//   • "none" → clears the others and submits ["none"] immediately.
//   • selecting another option after "none" clears "none".
//
// Layout is RTL/LTR aware via the [isArabic] flag.
// ─────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../models/chat_models.dart';

class FollowUpCard extends StatefulWidget {
  final FollowUp followUp;

  /// Whether the card has already been confirmed (locked / read-only).
  final bool answered;

  /// True when the app language is Arabic (controls direction + helper text).
  final bool isArabic;

  /// Called with the selected option ids when the selection is auto-submitted.
  final void Function(List<String> selectedIds) onSubmit;

  const FollowUpCard({
    required this.followUp,
    required this.answered,
    required this.isArabic,
    required this.onSubmit,
    super.key,
  });

  @override
  State<FollowUpCard> createState() => _FollowUpCardState();
}

class _FollowUpCardState extends State<FollowUpCard> {
  final _selected = <String>{};
  bool _submitted = false;
  Timer? _debounce;

  /// How long after the last tap a multi-select auto-submits.
  static const _debounceDelay = Duration(milliseconds: 1100);

  bool get _locked => widget.answered || _submitted;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _submit(List<String> ids) {
    if (_submitted || ids.isEmpty) return;
    _debounce?.cancel();
    setState(() => _submitted = true);
    widget.onSubmit(ids);
  }

  void _onTap(FollowUpOption opt) {
    if (_locked) return;

    // Single-select / yes-no → submit immediately.
    if (!widget.followUp.allowMultiple) {
      setState(() => _selected
        ..clear()
        ..add(opt.id));
      _submit([opt.id]);
      return;
    }

    // Multi-select.
    setState(() {
      if (opt.isNone) {
        _selected
          ..clear()
          ..add(opt.id);
      } else {
        _selected.removeWhere((id) => id.toLowerCase() == 'none');
        if (_selected.contains(opt.id)) {
          _selected.remove(opt.id);
        } else {
          _selected.add(opt.id);
        }
      }
    });

    // "none" submits instantly; otherwise debounce so the user can pick several.
    if (opt.isNone) {
      _submit(['none']);
    } else {
      _debounce?.cancel();
      if (_selected.isNotEmpty) {
        _debounce = Timer(_debounceDelay, () {
          if (mounted && !_locked) _submit(_selected.toList());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fu = widget.followUp;
    final ar = widget.isArabic;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 38),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Prompt / question ──────────────────────────
              if (fu.prompt != null && fu.prompt!.trim().isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.help_outline_rounded,
                          size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fu.prompt!.trim(),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Option chips ───────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fu.options.map(_buildChip).toList(),
              ),

              // ── Helper / status line (no Send button) ──────
              const SizedBox(height: 10),
              Text(
                _helperText(ar),
                style: TextStyle(
                  fontSize: 11,
                  color: context.text.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _helperText(bool ar) {
    if (_submitted || widget.answered) {
      return ar ? 'تم الإرسال' : 'Sent';
    }
    if (widget.followUp.allowMultiple) {
      return ar
          ? 'اختر ما ينطبق — سيُرسل تلقائيًا'
          : 'Select all that apply — sends automatically';
    }
    return ar ? 'اضغط للاختيار' : 'Tap an option to choose';
  }

  Widget _buildChip(FollowUpOption opt) {
    final isSelected = _selected.contains(opt.id);
    return GestureDetector(
      onTap: _locked ? null : () => _onTap(opt),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (_locked
                  ? AppColors.primary.withOpacity(0.04)
                  : context.card),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              opt.display,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : context.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
