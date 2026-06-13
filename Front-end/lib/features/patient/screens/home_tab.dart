// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:medilink/core/services/api_service.dart';
import 'package:medilink/core/services/in_app_notification_store.dart';
import 'package:medilink/core/services/reminder_store.dart';
import 'package:medilink/core/services/location_service.dart';
import 'package:medilink/core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/name_format.dart';
import '../../../models/reminder_model.dart';
import 'chatbot_screen.dart';
import 'all_doctors_screen.dart';
import '../../../core/widgets/notification_bell_button.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/fcm_service.dart';
// ignore: unused_import
import 'all_reminders_screen.dart';
import 'category_screen.dart';
import 'doctor_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared colour palette — imported by home_screen.dart via `import 'home_tab.dart'`
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the [main], [dark], and [light] colours for a given category index.
/// 0 = Doctors (Blue) · 1 = Pharmacy (Rose-Red) · 2 = Labs (Teal) · 3 = Scans (Purple)

({Color main, Color dark, Color light}) categoryPalette(int cat) {
  final palettes = [
    // 0 – Doctors
    (
      main: AppColors.primary,
      dark: AppColors.primaryDark,
      light: const Color(0xFFE3F2FD),
    ),

    // 1 – Pharmacy
    (
      main: AppColors.pharcatdark,
      dark: AppColors.pharcat,
      light: const Color(0xFFFFEBEE),
    ),

    // 2 – Labs
    (
      main: AppColors.labcatdark,
      dark: AppColors.labcat,
      light: const Color(0xFFE0F7FA),
    ),

    // 3 – Scans
    (
      main: AppColors.scancatdark,
      dark: AppColors.scancat,
      light: const Color(0xFFF3E5F5),
    ),
  ];

  return palettes[cat.clamp(0, 3)];
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeTab
// ─────────────────────────────────────────────────────────────────────────────

class HomeTab extends StatefulWidget {
  final void Function(int) onSwitchTab;

  /// Shared notifier – HomeScreen reads this to update FAB + BottomNav colours.
  final ValueNotifier<int> categoryNotifier;

  const HomeTab({
    super.key,
    required this.onSwitchTab,
    required this.categoryNotifier,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Single source of truth, shared with ReminderTab. Listening to it keeps the
  // Upcoming Schedule in sync with adds/deletes/takes made on the Reminders tab.
  final _store = ReminderStore.instance;

  List<_DoctorData> _apiDoctors = [];
  bool _loadingDoctors = false;

  // ── Convenience accessors ─────────────────────────────────────────────────
  ValueNotifier<int> get _catNotifier => widget.categoryNotifier;
  int get _selectedCategory => _catNotifier.value;

  // ── Dynamic colour getters ────────────────────────────────────────────────
  Color get _mainColor => categoryPalette(_selectedCategory).main;
  Color get _darkColor => categoryPalette(_selectedCategory).dark;
  Color get _lightColor => categoryPalette(_selectedCategory).light;

  /// Dark-mode–aware background tint for highlighted surfaces.
  Color _surfaceTint(BuildContext ctx) =>
      ctx.isDark ? _mainColor.withOpacity(0.15) : _lightColor;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  void _onCategoryChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _catNotifier.addListener(_onCategoryChanged);
    _store.addListener(_onStoreChanged);
    _loadReminders();
    _loadDoctors();
  }

  @override
  void dispose() {
    _catNotifier.removeListener(_onCategoryChanged);
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  /// Rebuild the Upcoming Schedule whenever the shared store changes.
  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<void> _loadReminders() async {
    // Loads into the shared store (which notifies listeners on completion).
    await _store.load();
    if (!mounted) return;

    // Re-schedule this account's reminders. Session clear() cancels all
    // device-scheduled notifications on login/switch (so a new account never
    // inherits another's), so we rebuild the current user's here.
    try {
      await NotificationService.rescheduleAll(_store.reminders);
    } catch (e) {
      debugPrint('HomeTab._loadReminders reschedule error: $e');
    }
  }

  Future<void> _loadDoctors() async {
    if (!mounted) return;
    setState(() => _loadingDoctors = true);
    try {
      final position = await LocationService.getLocation();
      if (!mounted) return;
      List<Map<String, dynamic>> raw;
      if (position != null) {
        raw = await ApiService.fetchNearbyDoctors(
          lat: position.latitude,
          lng: position.longitude,
        );
      } else {
        // No GPS — load all doctors unsorted
        raw = await ApiService.fetchAllDoctors();
      }
      if (!mounted) return;
      setState(() => _apiDoctors = raw.map(_DoctorData.fromJson).toList());
    } catch (e) {
      debugPrint('HomeTab._loadDoctors error: $e');
    } finally {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            FadeSlideIn(
              delay: 0,
              child: AnimatedBuilder(
                animation: SessionService.userNotifier,
                builder: (context, _) {
                  final user = SessionService.currentUser;
                  return Row(children: [
                    // Avatar ring animates to active-category colour
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _mainColor.withOpacity(0.15),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.transparent,
                        backgroundImage: user?.image != null
                            ? NetworkImage(user!.image!)
                            : null,
                        child: user?.image == null
                            ? Icon(Icons.person_outline_rounded,
                                color: _mainColor)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l.hiUser(user?.name ?? 'User'),
                              style: TextStyle(
                                  color: context.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(context.l.howAreYou,
                              style: TextStyle(
                                  color: AppColors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: InAppNotificationStore.instance,
                      builder: (_, __) {
                        return NotificationBellButton(
                          notifications: InAppNotificationStore.instance.items,
                          onDismissed: (notification) =>
                              InAppNotificationStore.instance.dismiss(
                            notification.id,
                          ),
                          onClearedAll: () =>
                              InAppNotificationStore.instance.dismissAll(),
                          onNotificationRead: (notification) async {
                            if (notification.conversationId != null) {
                              // Close the bell sheet first, then navigate
                              Navigator.of(context).pop();
                              FcmService.chatNavNotifier.value =
                                  notification.conversationId;
                            }
                          },
                        );
                      },
                    ),
                  ]);
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Search ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(14),
                border:
                    context.isDark ? Border.all(color: context.divider) : null,
                boxShadow: context.isDark
                    ? null
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10),
                      ],
              ),
              child: Row(children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.grey, size: 22),
                const SizedBox(width: 10),
                Text(context.l.searchHint,
                    style: TextStyle(color: AppColors.grey, fontSize: 14)),
                const Spacer(),
                // Filter button animates colour with the active category
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _mainColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 16),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Categories ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (i) {
                final categories = [
                  _CategoryItem.image(
                    lightImagePath: 'assets/images/doctor black.png',
                    darkImagePath: 'assets/images/doctor white.png',
                    selectedLightImagePath: 'assets/images/doctor white.png',
                    selectedDarkImagePath: 'assets/images/doctor white.png',
                    label: context.l.doctors,
                  ),
                  _CategoryItem.image(
                    lightImagePath: 'assets/images/pharmacy black.png',
                    darkImagePath: 'assets/images/pharmacy white.png',
                    selectedLightImagePath: 'assets/images/pharmacy white.png',
                    selectedDarkImagePath: 'assets/images/pharmacy white.png',
                    label: context.l.pharmacy,
                  ),
                  _CategoryItem.image(
                    lightImagePath: 'assets/images/lab black.png',
                    darkImagePath: 'assets/images/lab white.png',
                    selectedLightImagePath: 'assets/images/lab white.png',
                    selectedDarkImagePath: 'assets/images/lab white.png',
                    label: context.l.labs,
                  ),
                  _CategoryItem.image(
                    lightImagePath: 'assets/images/radilogy black.png',
                    darkImagePath: 'assets/images/radilogy white.png',
                    selectedLightImagePath: 'assets/images/radilogy white.png',
                    selectedDarkImagePath: 'assets/images/radilogy white.png',
                    label: context.l.scans,
                  ),
                ];
                final category = categories[i];
                return ScaleTap(
                  onTap: () => _catNotifier.value = i,
                  child: _Category(
                    icon: category.icon,
                    lightImagePath: category.lightImagePath,
                    darkImagePath: category.darkImagePath,
                    selectedLightImagePath: category.selectedLightImagePath,
                    selectedDarkImagePath: category.selectedDarkImagePath,
                    label: category.label,
                    selected: _selectedCategory == i,
                    activeColor: categoryPalette(i).main,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // ── AI ChatBot Banner ─────────────────────────────────────────────
            // AnimatedSwitcher fades between banner instances keyed by category
            ScaleTap(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen())),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity:
                      CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                  child: child,
                ),
                child: _AiBanner(
                  key: ValueKey(_selectedCategory),
                  mainColor: _mainColor,
                  darkColor: _darkColor,
                  chatNowText: context.l.chatNow,
                  titleText: context.l.aiAssistantTitle,
                  descText: context.l.aiAssistantDesc,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Upcoming Schedule ────────────────────────────────────────────
            _sectionHeader(
              context,
              context.l.upcomingSchedule,
              onSeeAll: () => widget.onSwitchTab(1),
            ),
            const SizedBox(height: 12),

            if (_store.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_store.reminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.l.noRemindersYet,
                  style: const TextStyle(color: AppColors.grey, fontSize: 13),
                ),
              )
            else
              ...() {
                final sorted =
                    _store.reminders.where((r) => !r.allTaken).toList()
                      ..sort((a, b) {
                        final aMin = a.time.hour * 60 + a.time.minute;
                        final bMin = b.time.hour * 60 + b.time.minute;
                        return aMin.compareTo(bMin);
                      });

                if (sorted.isEmpty) {
                  return [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        context.l.noRemindersYet,
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 13),
                      ),
                    ),
                  ];
                }

                return sorted.take(3).map((r) {
                  const formImages = <MedicineForm, String>{
                    MedicineForm.tablets: 'assets/images/tablets.png',
                    MedicineForm.capsules: 'assets/images/capsule.png',
                    MedicineForm.syrups: 'assets/images/syrup.png',
                    MedicineForm.dropsEye: 'assets/images/drops.png',
                    MedicineForm.dropsEar: 'assets/images/drops.png',
                    MedicineForm.dropsNasal: 'assets/images/drops.png',
                    MedicineForm.injection: 'assets/images/injection.png',
                    MedicineForm.inhaler: 'assets/images/inhaler.png',
                    MedicineForm.cream: 'assets/images/cream.png',
                    MedicineForm.powder: 'assets/images/effervescent.png',
                    MedicineForm.suppository: 'assets/images/suppository.png',
                    MedicineForm.lozenge: 'assets/images/lozenge.png',
                    MedicineForm.sublingual: 'assets/images/Sublingual.png',
                  };
                  final imagePath = r.type == ReminderType.doctor
                      ? (context.isDark
                          ? 'assets/images/doctor white.png'
                          : 'assets/images/doctor black.png')
                      : (formImages[r.form] ?? 'assets/images/tablets.png');
                  final h = r.time.hourOfPeriod == 0 ? 12 : r.time.hourOfPeriod;
                  final m = r.time.minute.toString().padLeft(2, '0');
                  final timeStr = '$h:$m ${r.time.period.name.toUpperCase()}';
                  final doseStr = r.dose == r.dose.truncateToDouble()
                      ? r.dose.toInt().toString()
                      : r.dose.toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ScheduleCard(
                      imagePath: imagePath,
                      title: r.name,
                      sub: '$timeStr  •  $doseStr dose',
                      color: r.color,
                      bgLight: r.color.withOpacity(0.1),
                      // Mark the whole reminder taken; the store notifies and
                      // both this section and the Reminders tab rebuild.
                      onTake: () => _store.markTaken(r.id, taken: true),
                    ),
                  );
                }).toList();
              }(),
            const SizedBox(height: 24),

            // ── Dynamic section header ────────────────────────────────────────
            _sectionHeader(
              context,
              _selectedCategory == 0
                  ? context.l.topDoctors
                  : _selectedCategory == 1
                      ? context.l.topPharmacy
                      : _selectedCategory == 2
                          ? context.l.topLabs
                          : context.l.topScans,
              onSeeAll: () {
                if (_selectedCategory == 0) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AllDoctorsScreen()));
                } else if (_selectedCategory == 1) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CategoryScreen.pharmacy(context)));
                } else if (_selectedCategory == 2) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CategoryScreen.labs(context)));
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CategoryScreen.scans(context)));
                }
              },
            ),
            const SizedBox(height: 12),

            // ── Category content with slide+fade transition ───────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_selectedCategory),
                child: Column(
                  children: _buildCategoryContent(context),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Widget> _buildCategoryContent(BuildContext context) {
    if (_selectedCategory == 0) {
      // Doctors — show real API doctors if available, else hardcoded fallback
      if (_loadingDoctors) {
        return [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        ];
      }
      if (_apiDoctors.isNotEmpty) {
        return _apiDoctors.map((d) => _DoctorCard(
              name: d.name,
              spec: d.specialty ?? context.l.generalPractitioner,
              sub: d.distanceLabel,
              imageUrl: d.imageUrl != null
                  ? '${ApiService.baseUrl}/${d.imageUrl}'
                  : null,
              accentColor: _mainColor,
              doctorId: d.id,
            )).toList();
      }
      // Fallback to hardcoded while no location or no doctors registered yet
      return [
        _DoctorCard(
            name: context.l.drKareem,
            spec: context.l.generalPractitioner,
            rating: 4.5,
            reviews: 200,
            accentColor: _mainColor),
        _DoctorCard(
            name: context.l.drEhab,
            spec: context.l.pediatrician,
            rating: 4.1,
            reviews: 130,
            accentColor: _mainColor),
        _DoctorCard(
            name: context.l.drAya,
            spec: context.l.internalMedicine,
            rating: 4.0,
            reviews: 150,
            accentColor: _mainColor),
        _DoctorCard(
            name: context.l.drMohamed,
            spec: context.l.oncologist,
            rating: 4.5,
            reviews: 120,
            accentColor: _mainColor),
        _DoctorCard(
            name: context.l.drSeif,
            spec: context.l.pulmonology,
            rating: 4.0,
            reviews: 100,
            accentColor: _mainColor),
      ];
    } else if (_selectedCategory == 1) {
      // Pharmacy – rose-red
      final c = categoryPalette(1).main;
      return [
        _CategoryPreviewCard(
            name: context.l.alNahda,
            detail: '0.3 km  •  8AM - 12AM',
            icon: Icons.local_pharmacy_outlined,
            color: c),
        _CategoryPreviewCard(
            name: context.l.dawaa,
            detail: '0.7 km  •  24 Hours',
            icon: Icons.local_pharmacy_outlined,
            color: c),
        _CategoryPreviewCard(
            name: context.l.seif,
            detail: '1.1 km  •  9AM - 11PM',
            icon: Icons.local_pharmacy_outlined,
            color: c),
      ];
    } else if (_selectedCategory == 2) {
      // Labs – teal
      final c = categoryPalette(2).main;
      return [
        _CategoryPreviewCard(
            name: context.l.alphaMedical,
            detail: '0.5 km  •  7AM - 9PM',
            icon: Icons.science_outlined,
            color: c),
        _CategoryPreviewCard(
            name: context.l.nileDiagnostics,
            detail: '1.0 km  •  8AM - 8PM',
            icon: Icons.biotech_outlined,
            color: c),
        _CategoryPreviewCard(
            name: context.l.cairoCenter,
            detail: '1.4 km  •  7AM - 10PM',
            icon: Icons.science_outlined,
            color: c),
      ];
    } else {
      // Scans – purple
      final c = categoryPalette(3).main;
      return [
        _CategoryPreviewCard(
            name: context.l.radiologyPlus,
            detail: '0.6 km  •  8AM - 10PM',
            icon: Icons.document_scanner_outlined,
            color: c),
        _CategoryPreviewCard(
            name: context.l.mriScanCenter,
            detail: '1.2 km  •  9AM - 9PM',
            icon: Icons.hub_outlined,
            color: c),
        _CategoryPreviewCard(
            name: context.l.cairoRadiology,
            detail: '1.6 km  •  8AM - 8PM',
            icon: Icons.document_scanner_outlined,
            color: c),
      ];
    }
  }

  Widget _sectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  color: context.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          GestureDetector(
            onTap: onSeeAll,
            // AnimatedDefaultTextStyle smoothly transitions the "See all" colour
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: _mainColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              child: Text(context.l.seeAll),
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Banner  (extracted so AnimatedSwitcher can key + crossfade it)
// ─────────────────────────────────────────────────────────────────────────────

class _AiBanner extends StatelessWidget {
  final Color mainColor, darkColor;
  final String chatNowText, titleText, descText;

  const _AiBanner({
    super.key,
    required this.mainColor,
    required this.darkColor,
    required this.chatNowText,
    required this.titleText,
    required this.descText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [mainColor, darkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titleText,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(descText,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.5)),
              const SizedBox(height: 12),
              _ChatPill(text: chatNowText),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: Colors.white, size: 36),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category pill
// ─────────────────────────────────────────────────────────────────────────────

class _Category extends StatelessWidget {
  final IconData? icon;
  final String? lightImagePath;
  final String? darkImagePath;
  final String? selectedLightImagePath;
  final String? selectedDarkImagePath;
  final String label;
  final bool selected;

  /// The colour this specific category pill uses when selected.
  final Color activeColor;
  final VoidCallback? onTap;

  const _Category({
    required this.label,
    required this.selected,
    required this.activeColor,
    this.icon,
    this.lightImagePath,
    this.darkImagePath,
    this.selectedLightImagePath,
    this.selectedDarkImagePath,
    // ignore: unused_element_parameter
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themedImagePath = context.isDark
        ? darkImagePath ?? lightImagePath
        : lightImagePath ?? darkImagePath;
    final selectedThemedImagePath = context.isDark
        ? selectedDarkImagePath ?? selectedLightImagePath ?? themedImagePath
        : selectedLightImagePath ?? selectedDarkImagePath ?? themedImagePath;

    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? activeColor : context.card,
            borderRadius: BorderRadius.circular(14),
            border: (!selected && context.isDark)
                ? Border.all(color: context.divider)
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.38),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : context.isDark
                    ? null
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8),
                      ],
          ),
          child: _CategoryVisual(
            icon: icon,
            imagePath: selected ? selectedThemedImagePath : themedImagePath,
            color: selected ? Colors.white : AppColors.grey,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: selected ? activeColor : AppColors.grey,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
          child: Text(label),
        ),
      ]),
    );
  }
}

class _CategoryVisual extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final Color color;

  const _CategoryVisual({
    this.icon,
    this.imagePath,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        width: 22,
        height: 22,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(icon ?? Icons.category_outlined, color: color, size: 22),
      );
    }

    return Icon(icon ?? Icons.category_outlined, color: color, size: 22);
  }
}

class _CategoryItem {
  final IconData? icon;
  final String? lightImagePath;
  final String? darkImagePath;
  final String? selectedLightImagePath;
  final String? selectedDarkImagePath;
  final String label;

  const _CategoryItem.icon({
    required this.icon,
    required this.label,
  })  : lightImagePath = null,
        darkImagePath = null,
        selectedLightImagePath = null,
        selectedDarkImagePath = null;

  const _CategoryItem.image({
    required this.lightImagePath,
    this.darkImagePath,
    this.selectedLightImagePath,
    this.selectedDarkImagePath,
    required this.label,
  }) : icon = null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule card
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final String imagePath;
  final String title, sub;
  final Color color, bgLight;
  final VoidCallback? onTake;

  const _ScheduleCard({
    required this.imagePath,
    required this.title,
    required this.sub,
    required this.color,
    required this.bgLight,
    this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDark ? context.card : bgLight,
        borderRadius: BorderRadius.circular(14),
        border: context.isDark ? Border.all(color: context.divider) : null,
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(context.isDark ? 0.2 : 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(
            imagePath,
            width: 22,
            height: 22,
            errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Missing image: $imagePath');
              return Icon(Icons.medication, size: 22, color: color);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: context.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              Text(sub,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onTake,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(20)),
            child: Text(context.l.take,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Doctor data model (from API)
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorData {
  final String id;
  final String name;
  final String? specialty;
  final String? imageUrl;
  final double distance;

  const _DoctorData({
    required this.id,
    required this.name,
    this.specialty,
    this.imageUrl,
    required this.distance,
  });

  factory _DoctorData.fromJson(Map<String, dynamic> j) => _DoctorData(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? 'Doctor',
        specialty: j['specialty'] as String?,
        imageUrl: j['image'] as String?,
        distance: (j['distance'] as num?)?.toDouble() ?? 0.0,
      );

  String get distanceLabel {
    if (distance < 1) return '${(distance * 1000).round()} m away';
    return '${distance.toStringAsFixed(1)} km away';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Doctor card
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorCard extends StatelessWidget {
  final String name, spec;
  final double rating;
  final int reviews;
  final String? sub;
  final String? imageUrl;
  final Color accentColor;
  final String doctorId;

  const _DoctorCard({
    required this.name,
    required this.spec,
    required this.accentColor,
    this.doctorId = '',
    this.rating = 0.0,
    this.reviews = 0,
    this.sub,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorDetailsScreen(
            name: name,
            specialization: spec,
            rating: rating,
            reviews: reviews,
            doctorId: doctorId,
            doctorImageUrl: imageUrl,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(14),
          border: context.isDark ? Border.all(color: context.divider) : null,
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2)),
                ],
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor:
                accentColor.withOpacity(context.isDark ? 0.25 : 0.12),
            backgroundImage:
                imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Icon(Icons.person_rounded, color: accentColor, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drName(name),
                    style: TextStyle(
                        color: context.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Text(spec,
                    style:
                        const TextStyle(color: AppColors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                if (sub != null)
                  Row(children: [
                    Icon(Icons.location_on_rounded,
                        color: accentColor, size: 13),
                    const SizedBox(width: 3),
                    Text(sub!,
                        style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ])
                else
                  Row(children: [
                    Icon(Icons.star_rounded,
                        color: context.isDark ? Colors.white : Colors.black,
                        size: 15),
                    const SizedBox(width: 3),
                    Text('$rating',
                        style: TextStyle(
                            color:
                                context.isDark ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text('($reviews ${context.l.reviews})',
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 11)),
                  ]),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(context.isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: accentColor),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category preview card  (pharmacy / labs / scans)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPreviewCard extends StatelessWidget {
  final String name, detail;
  final IconData icon;
  final Color color;

  const _CategoryPreviewCard({
    required this.name,
    required this.detail,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        border: context.isDark ? Border.all(color: context.divider) : null,
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(context.isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      color: context.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 3),
              Text(detail,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12)),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat pill button  (inside banner)
// ─────────────────────────────────────────────────────────────────────────────

class _ChatPill extends StatelessWidget {
  final String text;
  const _ChatPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation helpers
// ─────────────────────────────────────────────────────────────────────────────

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delay;

  const FadeSlideIn({super.key, required this.child, this.delay = 0});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(_controller),
        child: widget.child,
      ),
    );
  }
}

class StaggeredList extends StatelessWidget {
  final List<Widget> children;

  const StaggeredList({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(children.length, (i) {
        return FadeSlideIn(delay: i * 80, child: children[i]);
      }),
    );
  }
}

class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ScaleTap({super.key, required this.child, this.onTap});

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  double scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => scale = 0.96),
      onTapUp: (_) => setState(() => scale = 1),
      onTapCancel: () => setState(() => scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
