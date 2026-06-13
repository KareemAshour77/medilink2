import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/emergency_info_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/emergency_info_model.dart';
import '../screens/edit_emergency_info_screen.dart';

/// Apple Health "Medical ID"-style emergency card.
/// Opens as a scrollable modal sheet, fetches the profile, and lets the
/// patient edit it. Call [showEmergencyCardSheet] to present it.
Future<void> showEmergencyCardSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EmergencyCardSheet(),
  );
}

class _EmergencyCardSheet extends StatefulWidget {
  const _EmergencyCardSheet();

  @override
  State<_EmergencyCardSheet> createState() => _EmergencyCardSheetState();
}

class _EmergencyCardSheetState extends State<_EmergencyCardSheet> {
  EmergencyInfoModel? _info;
  bool _loading = true; // a fetch is in flight
  bool _loaded = false; // at least one fetch has completed
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Re-fetch from the backend. Used on open, after save, on retry, and by
  // pull-to-refresh. Existing content stays visible while refreshing.
  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final info = await _withAccountIdentity(
        await EmergencyInfoService.fetchMine(),
      );
      if (!mounted) return;
      setState(() {
        _info = info;
        _error = null;
        _loaded = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loaded = true;
        _loading = false;
      });
    }
  }

  // Gender and date of birth are account identity, read from the `users` table
  // (derived from the National ID at registration). Always prefer those over any
  // value stored on the emergency profile, so the card's Gender and Age reflect
  // the DB.
  Future<EmergencyInfoModel?> _withAccountIdentity(
      EmergencyInfoModel? info) async {
    if (info == null) return null;
    final identity = await ApiService.fetchMyIdentity();
    if (identity == null) return info;
    return info.copyWith(
      gender: identity.gender,
      dateOfBirth: identity.dateOfBirth,
    );
  }

  Future<void> _openEdit(EmergencyInfoModel? current) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditEmergencyInfoScreen(initial: current),
      ),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(child: _body(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(ScrollController scrollController) {
    // Initial load (nothing to show yet).
    if (!_loaded && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Hard error with no data to fall back on.
    if (_error != null && _info == null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    return _Content(
      scrollController: scrollController,
      info: _info,
      onEdit: () => _openEdit(_info),
      onRefresh: _load,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.grey, size: 44),
            const SizedBox(height: 14),
            Text('Couldn’t load emergency info\n$message',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final ScrollController scrollController;
  final EmergencyInfoModel? info;
  final VoidCallback onEdit;
  final Future<void> Function() onRefresh;

  const _Content({
    required this.scrollController,
    required this.info,
    required this.onEdit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final i = info;
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.primary,
            child: ListView(
              controller: scrollController,
              // AlwaysScrollable so pull-to-refresh works even when the
              // content is shorter than the viewport.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              children: [
                const _Header(),
                const SizedBox(height: 20),
                if (i == null)
                  _EmptyState()
                else
                  ..._sections(context, i),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: Text(i == null
                    ? 'Add Emergency Info'
                    : 'Edit Emergency Info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                  textStyle: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _sections(BuildContext context, EmergencyInfoModel i) {
    final widgets = <Widget>[];

    void add(Widget w) {
      widgets.add(w);
      widgets.add(const SizedBox(height: 14));
    }

    // 1. Blood type
    add(_BloodTypeCard(bloodType: i.bloodType));

    // Gender (from the account / National ID)
    add(_InfoLineCard(
      title: 'Gender',
      value: i.isFemale ? 'Female' : 'Male',
    ));

    // Age (derived from date of birth — from the account / National ID)
    if (i.age != null) {
      add(_InfoLineCard(
        title: 'Age',
        value: '${i.age} yrs'
            '${i.dateOfBirth != null ? ' • ${_formatDate(i.dateOfBirth!)}' : ''}',
      ));
    }

    // Vitals: height & weight
    if (i.height != null || i.weight != null) {
      add(_VitalsCard(height: i.height, weight: i.weight));
    }

    // 2. Allergies
    add(_AllergyCard(allergies: i.allergies));

    // 3. Chronic conditions
    add(_SectionCard(
      title: 'Chronic Conditions',
      child: i.conditions.isEmpty
          ? const _EmptyLine('None reported')
          : _ChipWrap(items: i.conditions, accent: AppColors.error),
    ));

    // 4. Current medications
    add(_MedicationsCard(meds: i.medications));

    // 5. Medical devices
    add(_SectionCard(
      title: 'Medical Devices',
      child: i.medicalDevices.isEmpty
          ? const _EmptyLine('No implanted devices')
          : _ChipWrap(items: i.medicalDevices, accent: AppColors.primary),
    ));

    // 6. Organ donor
    add(_OrganDonorCard(isDonor: i.organDonor));

    // Smoking status
    add(_SmokerCard(isSmoker: i.smoker));

    // 7. Pregnancy (female only)
    if (i.isFemale) {
      add(_InfoLineCard(
        title: 'Pregnancy Status',
        value: !i.isPregnant
            ? 'Not Pregnant'
            : (i.pregnancyWeeks != null
                ? '${i.pregnancyWeeks} Weeks Pregnant'
                : 'Pregnant'),
      ));
    }

    // 8. Primary language
    add(_InfoLineCard(
      title: 'Primary Language',
      value: (i.primaryLanguage?.isNotEmpty ?? false)
          ? i.primaryLanguage!
          : '—',
    ));

    // 9. Last updated
    if (i.updatedAt != null) {
      add(_InfoLineCard(
        title: 'Last Updated',
        value: _formatDate(i.updatedAt!),
      ));
    }

    return widgets;
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = d.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: AppColors.error, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MEDICAL ID',
              style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6)),
          const SizedBox(height: 6),
          Text('Emergency Medical Information',
              style: TextStyle(
                  color: context.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text('Critical information for first responders',
              style: TextStyle(color: AppColors.grey, fontSize: 12.5)),
        ],
      ),
    );
  }
}

// ─── Generic section card ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? background;
  final Color? borderColor;

  const _SectionCard({
    required this.title,
    required this.child,
    this.background,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background ?? context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? context.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: context.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Blood type (prominent) ───────────────────────────────────────────────────
class _BloodTypeCard extends StatelessWidget {
  final String? bloodType;
  const _BloodTypeCard({required this.bloodType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withOpacity(0.14),
            AppColors.error.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BLOOD TYPE',
              style: TextStyle(
                  color: AppColors.label,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(
            (bloodType?.isNotEmpty ?? false) ? bloodType! : '—',
            style: TextStyle(
                color: context.text,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

// ─── Vitals (height & weight) ─────────────────────────────────────────────────
class _VitalsCard extends StatelessWidget {
  final double? height;
  final double? weight;
  const _VitalsCard({required this.height, required this.weight});

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: context.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
    }

    return Row(children: [
      tile('Height', height != null ? '${_num(height!)} cm' : '—'),
      const SizedBox(width: 12),
      tile('Weight', weight != null ? '${_num(weight!)} kg' : '—'),
    ]);
  }
}

// ─── Allergies (warning card) ─────────────────────────────────────────────────
class _AllergyCard extends StatelessWidget {
  final List<String> allergies;
  const _AllergyCard({required this.allergies});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Allergies',
      background: AppColors.warning.withOpacity(0.08),
      borderColor: AppColors.warning.withOpacity(0.35),
      child: allergies.isEmpty
          ? const _EmptyLine('No known allergies')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: allergies
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•',
                                style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(a,
                                  style: TextStyle(
                                      color: context.text,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}

// ─── Medications ──────────────────────────────────────────────────────────────
class _MedicationsCard extends StatelessWidget {
  final List<MedicationModel> meds;
  const _MedicationsCard({required this.meds});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Current Medications',
      child: meds.isEmpty
          ? const _EmptyLine('No current medications')
          : Column(
              children: meds
                  .map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: context.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                                color: AppColors.primary, width: 3),
                          ),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name,
                                    style: TextStyle(
                                        color: context.text,
                                        fontWeight: FontWeight.w700)),
                                if (m.detail.isNotEmpty)
                                  Text(m.detail,
                                      style: const TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ]),
                      ))
                  .toList(),
            ),
    );
  }
}

// ─── Organ donor ──────────────────────────────────────────────────────────────
class _OrganDonorCard extends StatelessWidget {
  final bool isDonor;
  const _OrganDonorCard({required this.isDonor});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Organ Donor Status',
      child: Text(
        isDonor ? 'Registered Donor' : 'Not Registered',
        style: TextStyle(
          color: isDonor ? AppColors.success : context.text,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Smoking status ───────────────────────────────────────────────────────────
class _SmokerCard extends StatelessWidget {
  final bool isSmoker;
  const _SmokerCard({required this.isSmoker});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Smoking Status',
      child: Text(
        isSmoker ? 'Smoker' : 'Non-Smoker',
        style: TextStyle(
          color: isSmoker ? AppColors.error : AppColors.success,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Simple icon + title + value card ─────────────────────────────────────────
class _InfoLineCard extends StatelessWidget {
  final String title;
  final String value;
  const _InfoLineCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Row(children: [
        Text(title,
            style: const TextStyle(color: AppColors.grey, fontSize: 13.5)),
        const Spacer(),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: context.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> items;
  final Color accent;
  const _ChipWrap({required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((c) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Text(c,
                    style: TextStyle(
                        color: context.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ))
          .toList(),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.grey,
            fontSize: 13.5,
            fontStyle: FontStyle.italic));
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.medical_information_outlined,
              color: AppColors.grey.withOpacity(0.6), size: 56),
          const SizedBox(height: 16),
          Text('No emergency info yet',
              style: TextStyle(
                  color: context.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Add your blood type, allergies, conditions and\nmedications so first responders can help faster.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
