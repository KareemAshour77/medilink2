import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../models/reminder_model.dart';
import '../../../core/theme/app_theme.dart';

class AllRemindersScreen extends StatefulWidget {
  const AllRemindersScreen({super.key});

  @override
  State<AllRemindersScreen> createState() => _AllRemindersScreenState();
}

class _AllRemindersScreenState extends State<AllRemindersScreen> {
  List<ReminderModel> _reminders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final reminders = await ApiService.fetchReminders();
      if (mounted) setState(() => _reminders = reminders);
    } catch (e) {
      debugPrint('AllRemindersScreen._load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period.name.toUpperCase()}';
  }

  static const _formImages = <MedicineForm, String>{
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

  @override
  Widget build(BuildContext context) {
    final taken = _reminders.where((r) => r.allTaken).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l.reminders, style: TextStyle(color: context.text)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.notifications_none,
                        size: 64, color: AppColors.grey.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(context.l.noRemindersYet,
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(context.l.tapToAddOne,
                        style: TextStyle(
                            color: AppColors.grey.withOpacity(0.6),
                            fontSize: 13)),
                  ]),
                )
              : Column(
                  children: [
                    // Progress chip
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Builder(builder: (ctx) {
                            final isArabic =
                                Localizations.localeOf(ctx).languageCode ==
                                    'ar';
                            return Text(
                              isArabic
                                  ? '$taken من ${_reminders.length} تم أخذها اليوم'
                                  : '$taken of ${_reminders.length} taken today',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }),
                        ),
                      ]),
                    ),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: _reminders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _reminders[i];
                            final imagePath = r.type == ReminderType.doctor
                                ? (context.isDark
                                    ? 'assets/images/doctor white.png'
                                    : 'assets/images/doctor black.png')
                                : (_formImages[r.form] ??
                                    'assets/images/injection.png');

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.card,
                                borderRadius: BorderRadius.circular(16),
                                border: context.isDark
                                    ? Border.all(color: context.divider)
                                    : null,
                                boxShadow: context.isDark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Row(children: [
                                // Icon pill
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: r.color.withOpacity(
                                        context.isDark ? 0.2 : 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Image.asset(
                                    imagePath,
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('❌ Missing image: $imagePath');
                                      return Icon(Icons.medication,
                                          size: 24, color: r.color);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Name + time
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.name,
                                          style: TextStyle(
                                            color: context.text,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            decoration: r.allTaken
                                                ? TextDecoration.lineThrough
                                                : null,
                                          )),
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Icon(Icons.access_time_outlined,
                                            size: 12, color: r.color),
                                        const SizedBox(width: 4),
                                        Text(_fmtTime(r.time),
                                            style: TextStyle(
                                              color: r.color,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            )),
                                      ]),
                                    ],
                                  ),
                                ),

                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: r.allTaken
                                        ? AppColors.success.withOpacity(0.12)
                                        : r.color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    r.allTaken ? 'Done ✓' : 'Pending',
                                    style: TextStyle(
                                      color:
                                          r.allTaken ? AppColors.success : r.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
