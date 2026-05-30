import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'home_tab.dart';
import 'reminder_tab.dart';
import 'records_tab.dart';
import 'menu_tab.dart';
import 'chatbot_screen.dart';
// import '../../../core/utils/animation_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final ValueNotifier<int> categoryNotifier = ValueNotifier(0);
  void _switchTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    // Tabs built here so HomeTab can receive the callback

final tabs = [
  HomeTab(
    onSwitchTab: _switchTab,
    categoryNotifier: categoryNotifier,
  ),
  const ReminderTab(),
  const RecordsTab(),
  const MenuTab(),
];

    return Scaffold(
      floatingActionButton: _ChatFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: tabs[_index],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        current: _index,
        onTap: _switchTab,
      ),
    );
  }
}

// ── Chatbot floating button ───────────────────────────────────────────────────
class _ChatFAB extends StatelessWidget {

  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const ChatbotScreen(),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 0,
              // offset: const Offset(50, 0),
            ),
          ],
        ),
        child: const Icon(Icons.chat_bubble_outline_rounded,
            color: Colors.white, size: 28),
      ),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: context.card,
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: l.home,
                  index: 0,
                  current: current,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.notifications_none,
                  activeIcon: Icons.notifications_rounded,
                  label: l.reminder,
                  index: 1,
                  current: current,
                  onTap: onTap),
              const SizedBox(width: 1),
              _NavItem(
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder_rounded,
                  label: l.records,
                  index: 2,
                  current: current,
                  onTap: onTap),
              _NavItem(
                  icon: Icons.menu_rounded,
                  activeIcon: Icons.menu_rounded,
                  label: l.menu,
                  index: 3,
                  current: current,
                  onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(active ? activeIcon : icon,
              color: active ? AppColors.primaryDark : AppColors.grey, size: 24),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                color: active ? AppColors.primaryDark : AppColors.grey,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              )),
        ]),
      ),
    );
  }
}
