import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Read-only display tile for values extracted from the National ID
/// (date of birth, gender). Visually distinct from editable fields.
class ReadOnlyInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ReadOnlyInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: context.isDark ? context.card : AppColors.bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divider),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: AppColors.grey, fontSize: 11.5)),
              const SizedBox(height: 2),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: context.text,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.lock_outline_rounded,
            size: 14, color: AppColors.grey),
      ]),
    );
  }
}
