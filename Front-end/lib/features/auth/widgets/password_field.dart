import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Password input with a visibility toggle and an optional live strength meter.
/// Validation rules elsewhere require: an uppercase letter, a digit and a
/// special character.
class PasswordField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? errorText;
  final bool showStrength;
  final ValueChanged<String>? onChanged;

  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.showStrength = false,
    this.onChanged,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  // 0..4 score based on length + character classes present.
  int get _score {
    final p = widget.controller.text;
    if (p.isEmpty) return 0;
    var s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!_@#\$%^&*(),.?":{}|<>]'))) s++;
    return s;
  }

  ({String label, Color color, double fraction}) get _meter {
    switch (_score) {
      case 0:
        return (label: '', color: Colors.transparent, fraction: 0);
      case 1:
        return (label: 'Weak', color: AppColors.error, fraction: 0.33);
      case 2:
      case 3:
        return (label: 'Medium', color: AppColors.warning, fraction: 0.66);
      default:
        return (label: 'Strong', color: AppColors.success, fraction: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meter = _meter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              color: context.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          onChanged: (v) {
            widget.onChanged?.call(v);
            if (widget.showStrength) setState(() {});
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.grey,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (widget.showStrength && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: meter.fraction,
                    minHeight: 5,
                    backgroundColor: context.divider,
                    valueColor: AlwaysStoppedAnimation(meter.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                meter.label,
                style: TextStyle(
                  color: meter.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._requirements(),
        ],
      ],
    );
  }

  // Live checklist so the user sees exactly which rules are still missing.
  List<Widget> _requirements() {
    final p = widget.controller.text;
    final rules = <(String, bool)>[
      ('At least 8 characters', p.length >= 8),
      ('One uppercase letter', p.contains(RegExp(r'[A-Z]'))),
      ('One number', p.contains(RegExp(r'[0-9]'))),
      (
        'One special character',
        p.contains(RegExp(r'[!_@#\$%^&*(),.?":{}|<>]')),
      ),
    ];
    return [
      for (final (text, met) in rules)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                met ? Icons.check_circle_rounded : Icons.cancel_outlined,
                size: 15,
                color: met ? AppColors.success : AppColors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: met ? AppColors.success : AppColors.grey,
                  fontWeight: met ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
    ];
  }
}
