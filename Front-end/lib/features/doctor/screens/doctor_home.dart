import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/chat_api_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/fcm_service.dart';
import 'doctor_dashboard.dart';
import 'doctor_patients.dart';
import 'doctor_appointments.dart';
import 'doctor_chat_list.dart';
import 'doctor_chat_screen.dart';
import 'doctor_profile1.dart';

class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});
  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FcmService.chatNavNotifier.addListener(_onChatNavNotify);
    // Handles terminated-state: main.dart wrote PendingNavigation from SharedPrefs
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingNav());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FcmService.chatNavNotifier.removeListener(_onChatNavNotify);
    super.dispose();
  }

  // Case 3 (foreground) + Case 2 backgrounded FCM tap: notifier fired directly
  void _onChatNavNotify() {
    final convId = FcmService.chatNavNotifier.value;
    if (convId == null) return;
    FcmService.chatNavNotifier.value = null;
    _navigateToChat(convId);
  }

  // Case 2 (backgrounded local notification): app resumes, read SharedPrefs
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingNavFromPrefs();
    }
  }

  Future<void> _checkPendingNavFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final convId = prefs.getString('pending_chat_nav');
    if (convId == null || !mounted) return;
    await prefs.remove('pending_chat_nav');
    await _navigateToChat(convId);
  }

  // Case 1 (terminated): PendingNavigation set by main.dart from SharedPrefs
  Future<void> _handlePendingNav() async {
    final convId = PendingNavigation.chatConversationId;
    if (convId == null) return;
    PendingNavigation.chatConversationId = null;
    await _navigateToChat(convId);
  }

  Future<void> _navigateToChat(String convId) async {
    if (!mounted) return;
    setState(() => _index = 3); // switch to Chat tab first
    try {
      final conv = await ChatApiService.getConversationById(convId);
      if (conv == null || !mounted) return;
      final other = (conv['other'] as Map<String, dynamic>?) ?? {};
      final imgPath = other['image'] as String?;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorChatScreen(
            conversationId: convId,
            patientId: other['id'] as String? ?? '',
            patientName: other['name'] as String? ?? 'Patient',
            patientImageUrl: imgPath != null ? '${ApiService.baseUrl}/$imgPath' : null,
          ),
        ),
      );
    } catch (_) {}
  }

  static const _tabs = [
    DoctorDashboard(),
    DoctorPatients(),
    DoctorAppointments(),
    DoctorChatList(),
    MenuTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final nav = [
      _N(Icons.grid_view_outlined,      Icons.grid_view_rounded,      l.dashboard),
      _N(Icons.people_alt_outlined,     Icons.people_alt_rounded,     l.navPatients),
      _N(Icons.calendar_today_outlined, Icons.calendar_today_rounded, l.schedule),
      _N(Icons.chat_bubble_outline,     Icons.chat_bubble_rounded,    l.navChat),
      _N(Icons.person_outline_rounded,  Icons.person_rounded,         l.navProfile),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_index), child: _tabs[_index]),
      ),
      bottomNavigationBar: _BottomBar(
        items: nav,
        selected: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _N {
  final IconData icon, active;
  final String label;
  const _N(this.icon, this.active, this.label);
}

class _BottomBar extends StatelessWidget {
  final List<_N> items;
  final int selected;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.items, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.card,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, -4))],
        border: Border(top: BorderSide(color: context.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) => _NavBtn(
              item: items[i], selected: i == selected, onTap: () => onTap(i),
            )),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatefulWidget {
  final _N item;
  final bool selected;
  final VoidCallback onTap;
  const _NavBtn({required this.item, required this.selected, required this.onTap});
  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween<double>(begin: 1, end: 1.25)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(_NavBtn old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _ac.forward(from: 0);
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = RoleTheme.doctor;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: widget.selected ? color.withOpacity(0.11) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
            scale: widget.selected ? _scale : const AlwaysStoppedAnimation(1),
            child: Icon(widget.selected ? widget.item.active : widget.item.icon,
                color: widget.selected ? color : AppColors.grey, size: 22),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400,
              color: widget.selected ? color : AppColors.grey,
            ),
            child: Text(widget.item.label),
          ),
        ]),
      ),
    );
  }
}
