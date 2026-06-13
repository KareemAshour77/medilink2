import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// "Basic Info → Identity → Verification" progress header.
/// Completed/active steps use the primary color; upcoming steps are muted.
class StepProgressIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;

  const StepProgressIndicator({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _node(context, i),
          if (i != steps.length - 1) _connector(i),
        ],
      ],
    );
  }

  Widget _node(BuildContext context, int i) {
    final done = i < currentIndex;
    final active = i == currentIndex;
    final color = (done || active) ? AppColors.primary : context.divider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: done ? AppColors.primary : context.card,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: active ? AppColors.primary : AppColors.grey,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 78,
          child: Text(
            steps[i],
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: (done || active) ? context.text : AppColors.grey,
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _connector(int i) {
    final filled = i < currentIndex;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 3,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : const Color(0x33000000),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
