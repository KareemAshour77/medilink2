import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return GestureDetector(
          onTap: toggleTheme,
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: isDark ? const EdgeInsets.only(left: 10) : const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: context.card,
              shape: BoxShape.circle,
              border: isDark
                  ? Border.all(color: Colors.white.withOpacity(0.1))
                  : null,
              boxShadow: isDark
                  ? null
                  : [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
            ),
            child: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              color: isDark ? Colors.amber : const Color.fromARGB(255, 0, 0, 0),
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
