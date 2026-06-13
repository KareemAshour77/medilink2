import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/chat_api_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/in_app_notification_store.dart';
import '../../../core/models/in_app_notification.dart';
import 'home_tab.dart';
import 'reminder_tab.dart';
import 'records_tab.dart';
import 'menu_tab.dart';
import 'chat_list_screen.dart';
import 'doctor_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0;
  final ValueNotifier<int> categoryNotifier = ValueNotifier(0);

  // Cache conversationId → doctor info for bell notifications
  final Map<String, String> _convNameCache = {};
  final Map<String, String> _convSpecialtyCache = {};

  void _switchTab(int i) => setState(() => _index = i);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FcmService.chatNavNotifier.addListener(_onChatNavNotify);
    FcmService.appointmentNavNotifier.addListener(_onAppointmentNavNotify);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handlePendingNav();
      await _initSocket();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FcmService.chatNavNotifier.removeListener(_onChatNavNotify);
    FcmService.appointmentNavNotifier.removeListener(_onAppointmentNavNotify);
    super.dispose();
  }

  void _onAppointmentNavNotify() {
    final status = FcmService.appointmentNavNotifier.value;
    if (status == null || !mounted) return;
    FcmService.appointmentNavNotifier.value = null;
    final accepted = status == 'accepted';
    AppSnackBar.show(
      context,
      accepted
          ? 'Your appointment was accepted! You can now chat with the doctor.'
          : 'Your appointment request was declined.',
      backgroundColor: accepted ? AppColors.primary : Colors.red,
      duration: const Duration(seconds: 4),
    );
  }

  // ── Socket setup ──────────────────────────────────────────────────────────

  Future<void> _initSocket() async {
    await ChatService.instance.connect();
    _registerConvUpdatedListener();
    // Pre-populate name cache so notifications show the doctor's name
    _preloadConvNames();
  }

  void _registerConvUpdatedListener() {
    ChatService.instance.onConvUpdated(_onConvUpdatedForBell);
  }

  Future<void> _preloadConvNames() async {
    try {
      final convs = await ChatApiService.getConversations();
      for (final conv in convs) {
        final id    = conv['id'] as String? ?? '';
        final other = (conv['other'] as Map<String, dynamic>?) ?? {};
        if (id.isEmpty) continue;
        _convNameCache[id]      = other['name'] as String? ?? 'Doctor';
        _convSpecialtyCache[id] = other['specialty'] as String? ?? '';
      }
    } catch (_) {}
  }

  void _onConvUpdatedForBell(Map<String, dynamic> data) {
    final senderId = data['senderId'] as String?;
    final myId     = SessionService.currentUser?.id ?? '';
    if (senderId == null || senderId == myId) return;

    final convId = data['conversationId'] as String?;
    if (convId == null) return;

    if (FcmService.activeChatConversationId == convId) return;

    final senderName = _convNameCache[convId] ?? 'Doctor';
    final specialty  = _convSpecialtyCache[convId] ?? '';
    final lastMsg    = data['lastMessage'] as String? ?? '';
    final msgId      = 'msg_${convId}_${DateTime.now().millisecondsSinceEpoch}';

    InAppNotificationStore.instance.add(
      InAppNotification(
        id:             msgId,
        title:          'Dr. $senderName',
        description:    lastMsg.isNotEmpty ? lastMsg : '📎 Attachment',
        time:           DateTime.now(),
        type:           InAppNotificationType.chat,
        conversationId: convId,
        specialty:      specialty.isNotEmpty ? specialty : null,
      ),
    );
  }

  // ── FCM navigation handlers ───────────────────────────────────────────────

  void _onChatNavNotify() {
    final convId = FcmService.chatNavNotifier.value;
    if (convId == null) return;
    FcmService.chatNavNotifier.value = null;
    _navigateToChat(convId);
  }

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

  Future<void> _handlePendingNav() async {
    final convId = PendingNavigation.chatConversationId;
    if (convId == null) return;
    PendingNavigation.chatConversationId = null;
    await _navigateToChat(convId);
  }

  Future<void> _navigateToChat(String convId) async {
    if (!mounted) return;
    try {
      final conv = await ChatApiService.getConversationById(convId);
      if (conv == null || !mounted) return;
      final other   = (conv['other'] as Map<String, dynamic>?) ?? {};
      final imgPath = other['image'] as String?;
      // Cache doctor info while we have it
      if (convId.isNotEmpty) {
        _convNameCache[convId]      = other['name'] as String? ?? 'Doctor';
        _convSpecialtyCache[convId] = other['specialty'] as String? ?? '';
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientDoctorChatScreen(
            doctorId:      other['id'] as String? ?? '',
            doctorName:    other['name'] as String? ?? 'Doctor',
            specialization: other['specialty'] as String? ?? '',
            doctorImageUrl: imgPath != null ? '${ApiService.baseUrl}/$imgPath' : null,
          ),
        ),
      ).then((_) => _registerConvUpdatedListener()); // re-register after chat closes
    } catch (_) {}
  }

  // ── Open chat list (FAB) — re-register after returning ───────────────────

  Future<void> _openChatList() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const ChatListScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    // ChatListScreen.dispose() calls offAll() — re-register our bell listener
    _registerConvUpdatedListener();
    // Refresh name cache in case new conversations were created
    _preloadConvNames();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(onSwitchTab: _switchTab, categoryNotifier: categoryNotifier),
      const ReminderTab(),
      const RecordsTab(),
      const MenuTab(),
    ];

    return Scaffold(
      floatingActionButton: _ChatFAB(onTap: _openChatList),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(key: ValueKey(_index), child: tabs[_index]),
      ),
      bottomNavigationBar: _BottomNav(current: _index, onTap: _switchTab),
    );
  }
}

// ── Chatbot floating button ───────────────────────────────────────────────────

class _ChatFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              _NavItem(icon: Icons.home_outlined,         activeIcon: Icons.home_rounded,            label: l.home,    index: 0, current: current, onTap: onTap),
              _NavItem(icon: Icons.notifications_none,    activeIcon: Icons.notifications_rounded,   label: l.reminder, index: 1, current: current, onTap: onTap),
              const SizedBox(width: 1),
              _NavItem(icon: Icons.folder_outlined,       activeIcon: Icons.folder_rounded,          label: l.records, index: 2, current: current, onTap: onTap),
              _NavItem(icon: Icons.menu_rounded,          activeIcon: Icons.menu_rounded,            label: l.menu,    index: 3, current: current, onTap: onTap),
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
