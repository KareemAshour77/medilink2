import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/name_format.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/chat_api_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/services/availability_service.dart';
import '../../../core/utils/record_labels.dart';
import '../../../core/widgets/chat_widgets.dart';
import '../../../data/records_data.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final String name;
  final String specialization;
  final double rating;
  final int reviews;
  final String experience;
  final String doctorId;
  final String? doctorImageUrl;

  const DoctorDetailsScreen({
    super.key,
    required this.name,
    required this.specialization,
    required this.rating,
    required this.reviews,
    this.experience = '10+ years exp',
    this.doctorId = '',
    this.doctorImageUrl,
  });

  void _showBookingSheet(BuildContext context, String doctorId, String doctorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(doctorId: doctorId, doctorName: doctorName),
    );
  }

  // Chat is gated server-side: only allowed once the doctor accepts a request.
  // Pre-check here so the patient gets a clear message instead of a broken chat.
  Future<void> _openChat(BuildContext context) async {
    if (doctorId.isEmpty) {
      AppSnackBar.show(context, 'Chat unavailable for this doctor.');
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ChatApiService.getOrCreateConversation(doctorId);
      if (!context.mounted) return;
      Navigator.pop(context); // close loader
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientDoctorChatScreen(
            doctorId: doctorId,
            doctorName: name,
            specialization: specialization,
            doctorImageUrl: doctorImageUrl,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // close loader
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.show(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.text,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Doctor Details', style: TextStyle(color: context.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          _DoctorProfileHeader(
            name: name,
            specialization: specialization,
            rating: rating,
            reviews: reviews,
            experience: experience,
            doctorImageUrl: doctorImageUrl,
          ),
          const SizedBox(height: 18),
          const _InfoCards(),
          const SizedBox(height: 22),
          const _SectionTitle('About'),
          const SizedBox(height: 10),
          _AboutCard(name: name, specialization: specialization),
          const SizedBox(height: 22),
          _ReviewsHeader(count: reviews),
          const SizedBox(height: 10),
          const _ReviewTile(
            name: 'Mona Ali',
            comment:
                'Very kind and clear. The visit felt calm, organized, and helpful.',
            rating: 5,
          ),
          const _ReviewTile(
            name: 'Ahmed Hassan',
            comment:
                'Explained the diagnosis well and answered all my questions.',
            rating: 5,
          ),
          const _ReviewTile(
            name: 'Sara Mohamed',
            comment: 'Professional follow-up and easy communication.',
            rating: 4,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: _PulseBookButton(
                  onPressed: () => _showBookingSheet(context, doctorId, name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(context),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(context.l.btnChatNow),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.8),
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorProfileHeader extends StatelessWidget {
  final String name;
  final String specialization;
  final double rating;
  final int reviews;
  final String experience;
  final String? doctorImageUrl;

  const _DoctorProfileHeader({
    required this.name,
    required this.specialization,
    required this.rating,
    required this.reviews,
    required this.experience,
    this.doctorImageUrl,
  });

  Widget _fallbackImage() => Padding(
        padding: const EdgeInsets.all(14),
        child: Image.asset(
          'assets/images/Stethoscope.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(18),
        border: context.isDark ? Border.all(color: context.divider) : null,
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.18),
                AppColors.primaryDark.withOpacity(0.24),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipOval(
            child: (doctorImageUrl != null && doctorImageUrl!.isNotEmpty)
                ? Image.network(
                    doctorImageUrl!,
                    fit: BoxFit.cover,
                    width: 86,
                    height: 86,
                    errorBuilder: (_, __, ___) => _fallbackImage(),
                  )
                : _fallbackImage(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drName(name),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                specialization,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniBadge(
                    icon: Icons.star_rounded,
                    label: '$rating ($reviews)',
                    color: context.isDark ? Colors.white : Colors.black,
                  ),
                  _MiniBadge(
                    icon: Icons.workspace_premium_rounded,
                    label: experience,
                    color: context.isDark ? Colors.white : Colors.black,
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

class _InfoCards extends StatelessWidget {
  const _InfoCards();

  @override
  Widget build(BuildContext context) {
    final items = [
      const _InfoItem(Icons.location_on_rounded, 'Location', 'New Cairo'),
      const _InfoItem(Icons.call_rounded, 'Phone', '+20 100 123 4567'),
      const _InfoItem(Icons.schedule_rounded, 'Hours', '10:00 AM - 8:00 PM'),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 520;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items.map((item) {
          return SizedBox(
            width:
                isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth,
            child: _InfoCard(item: item),
          );
        }).toList(),
      );
    });
  }
}

class _InfoItem {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItem(this.icon, this.title, this.value);
}

class _InfoCard extends StatelessWidget {
  final _InfoItem item;

  const _InfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(context.isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String name;
  final String specialization;

  const _AboutCard({required this.name, required this.specialization});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: context.isDark ? Border.all(color: context.divider) : null,
      ),
      child: Text(
        '$name is a trusted $specialization specialist focused on clear diagnosis, practical care plans, and comfortable patient communication.',
        style: TextStyle(
          color: context.text.withOpacity(0.78),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}

class _ReviewsHeader extends StatelessWidget {
  final int count;

  const _ReviewsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const _SectionTitle('Reviews'),
      const Spacer(),
      Text(
        '$count total',
        style: const TextStyle(color: AppColors.grey, fontSize: 12),
      ),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.text,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String name;
  final String comment;
  final int rating;

  const _ReviewTile({
    required this.name,
    required this.comment,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: context.isDark ? Border.all(color: context.divider) : null,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            name.substring(0, 1),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: context.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star_rounded,
                      size: 13,
                      // color: i < rating ? Colors.amber : AppColors.grey,
                      color: i < rating ? (context.isDark ? Colors.white : Colors.black) : AppColors.grey,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                comment,
                style: TextStyle(
                  color: context.text.withOpacity(0.68),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _PulseChatButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _PulseChatButton({required this.onPressed});

  @override
  State<_PulseChatButton> createState() => _PulseChatButtonState();
}

class _PulseChatButtonState extends State<_PulseChatButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1, end: 1.035).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.36),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Chat Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Booking sheet ─────────────────────────────────────────────────────────────

class _BookingApptType {
  final String title;
  final String subtitle;
  final IconData icon;
  const _BookingApptType(this.title, this.subtitle, this.icon);
}

const _kApptTypes = [
  _BookingApptType('Follow-Up', 'Return visit for an existing condition', Icons.event_repeat_rounded),
  _BookingApptType('Check-Up', 'Routine health examination', Icons.health_and_safety_rounded),
  _BookingApptType('Consultation', 'First-time advice or second opinion', Icons.record_voice_over_outlined),
];

class _BookingSheet extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  const _BookingSheet({required this.doctorId, required this.doctorName});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  // Step 0 = pick type, Step 1 = pick date + slot.
  int _step = 0;
  String? _selected;
  bool _loading = false;

  // Date + slots.
  late DateTime _selectedDate = DateTime.now();
  bool _slotsLoading = false;
  bool _configured = true;
  List<Map<String, dynamic>> _slots = [];
  String? _selectedSlotIso;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _goToSlots() async {
    if (_selected == null) return;
    setState(() => _step = 1);
    await _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _slotsLoading = true;
      _selectedSlotIso = null;
    });
    try {
      final res = await AvailabilityService.getSlots(
        widget.doctorId,
        _fmtDate(_selectedDate),
      );
      if (!mounted) return;
      setState(() {
        _configured = res['configured'] == true;
        _slots = (res['slots'] as List).cast<Map<String, dynamic>>();
        _slotsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slots = [];
        _slotsLoading = false;
      });
    }
  }

  Future<void> _book() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      await AppointmentService.book(
        doctorId: widget.doctorId,
        type: _selected!,
        scheduledAt: _selectedSlotIso,
      );
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.show(context, '${context.l.requestSentTo} ${widget.doctorName}',
          backgroundColor: AppColors.primary);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.show(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              if (_step == 1)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: context.text),
                  onPressed: () => setState(() => _step = 0),
                ),
              Expanded(
                child: Text(
                  _step == 0 ? context.l.bookAppointment : context.l.chooseTime,
                  style: TextStyle(
                      color: context.text, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _step == 0
                    ? context.l.selectAppointmentType
                    : apptTypeLabelL10n(context.l, _selected),
                style: const TextStyle(color: AppColors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            if (_step == 0) ..._buildTypeStep() else ..._buildSlotStep(),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeStep() => [
        for (final t in _kApptTypes)
          _TypeCard(
            type: t,
            selected: _selected == t.title,
            onTap: () => setState(() => _selected = t.title),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _selected == null ? null : _goToSlots,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: Text(context.l.continueLabel,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ];

  List<Widget> _buildSlotStep() {
    return [
      // Horizontal 14-day date strip.
      SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 14,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final day = DateTime.now().add(Duration(days: i));
            final sel = _fmtDate(day) == _fmtDate(_selectedDate);
            const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            return GestureDetector(
              onTap: () {
                setState(() => _selectedDate = day);
                _loadSlots();
              },
              child: Container(
                width: 56,
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : context.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? AppColors.primary : context.divider),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(wd[day.weekday - 1],
                      style: TextStyle(
                          color: sel ? Colors.white : AppColors.grey,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${day.day}',
                      style: TextStyle(
                          color: sel ? Colors.white : context.text,
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      if (_slotsLoading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: CircularProgressIndicator(),
        )
      else if (!_configured)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Text(
            context.l.doctorNoAvailability,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey, fontSize: 13),
          ),
        )
      else if (_slots.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(context.l.noSlotsAvailable,
              style: const TextStyle(color: AppColors.grey, fontSize: 13)),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _slots.map((s) {
            final iso = s['start'] as String;
            final label = s['label'] as String? ?? '';
            final sel = _selectedSlotIso == iso;
            return GestureDetector(
              onTap: () => setState(() => _selectedSlotIso = iso),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : context.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? AppColors.primary : context.divider),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: sel ? Colors.white : context.text,
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            );
          }).toList(),
        ),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: (_selectedSlotIso == null || _loading) ? null : _book,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
          ),
          child: _loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(context.l.requestAppointment,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    ];
  }
}

class _TypeCard extends StatelessWidget {
  final _BookingApptType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(context.isDark ? 0.2 : 0.08)
              : context.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : context.divider,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(selected ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(type.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(apptTypeLabelL10n(context.l, type.title),
                  style: TextStyle(color: context.text, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 3),
              Text(type.subtitle, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
            ]),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }
}

class _PulseBookButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _PulseBookButton({required this.onPressed});

  @override
  State<_PulseBookButton> createState() => _PulseBookButtonState();
}

class _PulseBookButtonState extends State<_PulseBookButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1, end: 1.035).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.36),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Book',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Patient-side real-time chat screen ───────────────────────────────────────

class PatientDoctorChatScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String? doctorImageUrl;

  const PatientDoctorChatScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    this.doctorImageUrl,
  });

  @override
  State<PatientDoctorChatScreen> createState() =>
      _PatientDoctorChatScreenState();
}

class _PatientDoctorChatScreenState extends State<PatientDoctorChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  String? _conversationId;
  String get _myId => SessionService.currentUser?.id ?? '';
  List<ChatMsg> _messages = [];
  bool _loading = true;
  String? _error;
  bool _doctorOnline = false;
  DateTime? _lastSeen;

  // Typing
  bool _doctorTyping = false;
  bool _isSendingTyping = false;
  Timer? _typingDebounce;
  ChatMsg? _replyTo;
  String? _highlightedId;
  final Map<String, GlobalKey> _messageKeys = {};

  GlobalKey _keyFor(String id) =>
      _messageKeys.putIfAbsent(id, () => GlobalKey());

  Future<void> _scrollToMessage(String msgId) async {
    final key = _keyFor(msgId);

    Future<void> ensureVisible() async {
      final ctx = key.currentContext;
      if (ctx == null) return;
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.3,
      );
    }

    if (key.currentContext != null) {
      await ensureVisible();
    } else {
      final idx = _messages.indexWhere((m) => m.id == msgId);
      if (idx < 0 || !_scroll.hasClients) return;
      final ratio = idx / _messages.length;
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent * ratio,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      await Future.delayed(const Duration(milliseconds: 60));
      await ensureVisible();
    }

    if (!mounted) return;
    setState(() => _highlightedId = msgId);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _highlightedId = null);
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.doctorId.isEmpty) {
      setState(() { _loading = false; _error = 'Chat unavailable for demo doctors.'; });
      return;
    }
    try {
      final conv = await ChatApiService.getOrCreateConversation(widget.doctorId);
      _conversationId = conv['id'] as String;
      FcmService.activeChatConversationId = _conversationId;

      final history = await ChatApiService.getMessages(_conversationId!);
      if (!mounted) return;
      setState(() {
        _messages = history.map(ChatMsg.fromJson).toList();
        _loading = false;
      });
      _scrollToBottom();

      await ChatService.instance.connect();
      ChatService.instance.joinRoom(_conversationId!);

      // Mark existing messages as read
      ChatService.instance.markRead(_conversationId!);

      // Listeners
      ChatService.instance.onNewMessage(_onNew);
      ChatService.instance.onMessageEdited(_onEdited);
      ChatService.instance.onMessageDeletedEveryone(_onDeletedEveryone);
      ChatService.instance.onMessagesRead(_onRead);
      ChatService.instance.onMessageDelivered(_onDelivered);
      ChatService.instance.onUserOnline((id) {
        if (id == widget.doctorId && mounted) setState(() => _doctorOnline = true);
      });
      ChatService.instance.onUserOffline((id, lastSeen) {
        if (id == widget.doctorId && mounted) {
          setState(() { _doctorOnline = false; _lastSeen = lastSeen; });
        }
      });
      // Request current status in case the doctor was already online/offline
      ChatService.instance.onUserStatus((id, online, lastSeen) {
        if (id == widget.doctorId && mounted) {
          setState(() {
            _doctorOnline = online;
            if (!online && lastSeen != null) _lastSeen = lastSeen;
          });
        }
      });
      ChatService.instance.getUserStatus(widget.doctorId);
      ChatService.instance.onTypingStart((id) {
        if (id == widget.doctorId && mounted) setState(() => _doctorTyping = true);
      });
      ChatService.instance.onTypingStop((id) {
        if (id == widget.doctorId && mounted) setState(() => _doctorTyping = false);
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() { _loading = false; _error = msg; });
    }
  }

  void _onNew(Map<String, dynamic> data) {
    final msg = ChatMsg.fromJson(data);
    if (_messages.any((m) => m.id == msg.id)) return;
    if (!mounted) return;
    setState(() {
      _messages.add(msg);
      if (msg.senderId == widget.doctorId) _doctorTyping = false;
    });
    _scrollToBottom();
    if (msg.senderId != _myId && _conversationId != null) {
      ChatService.instance.ackDelivered(msg.id);
      ChatService.instance.markRead(_conversationId!);
    }
  }

  void _onDelivered(Map<String, dynamic> data) {
    final id = data['messageId'] as String?;
    if (id == null || !mounted) return;
    setState(() {
      final i = _messages.indexWhere((m) => m.id == id);
      if (i >= 0 && _messages[i].deliveredAt == null) {
        _messages[i] = _messages[i].copyWith(
          deliveredAt: DateTime.tryParse(data['deliveredAt']?.toString() ?? '') ?? DateTime.now(),
        );
      }
    });
  }

  // ── Typing detection ─────────────────────────────────────────────────────────
  void _onTextChanged(String text) {
    if (_conversationId == null) return;
    if (!_isSendingTyping && text.isNotEmpty) {
      _isSendingTyping = true;
      ChatService.instance.startTyping(_conversationId!, otherId: widget.doctorId);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (_isSendingTyping && _conversationId != null) {
        _isSendingTyping = false;
        ChatService.instance.stopTyping(_conversationId!, otherId: widget.doctorId);
      }
    });
    if (text.isEmpty && _isSendingTyping && _conversationId != null) {
      _isSendingTyping = false;
      _typingDebounce?.cancel();
      ChatService.instance.stopTyping(_conversationId!, otherId: widget.doctorId);
    }
  }

  void _onEdited(Map<String, dynamic> data) {
    final updated = ChatMsg.fromJson(data);
    if (!mounted) return;
    setState(() {
      final i = _messages.indexWhere((m) => m.id == updated.id);
      if (i >= 0) _messages[i] = updated;
    });
  }

  void _onDeletedEveryone(Map<String, dynamic> data) {
    final id = data['messageId'] as String?;
    if (id == null || !mounted) return;
    setState(() {
      final i = _messages.indexWhere((m) => m.id == id);
      if (i >= 0) _messages[i] = _messages[i].copyWith(isDeletedForEveryone: true);
    });
  }

  void _onRead(Map<String, dynamic> data) {
    // Only update ticks when the OTHER person read my messages.
    // If readBy == _myId I triggered this event myself — ignore it.
    final readBy = data['readBy'] as String?;
    if (readBy == null || readBy == _myId || !mounted) return;
    setState(() {
      _messages = _messages.map((m) {
        if (m.senderId == _myId && !m.isRead) {
          return m.copyWith(isRead: true, deliveredAt: m.deliveredAt ?? DateTime.now());
        }
        return m;
      }).toList();
    });
  }

  // ── Send text ───────────────────────────────────────────────────────────────
  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    _ctrl.clear();
    if (_isSendingTyping) {
      _isSendingTyping = false;
      _typingDebounce?.cancel();
      ChatService.instance.stopTyping(_conversationId!, otherId: widget.doctorId);
    }
    final replyId = _replyTo?.id;
    setState(() => _replyTo = null);
    ChatService.instance.sendMessage(_conversationId!, text, replyToId: replyId);
  }

  // ── Media picker ────────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null && _conversationId != null) {
      await _uploadMedia(File(x.path));
    }
  }

  Future<void> _pickFromCamera() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x != null && _conversationId != null) {
      await _uploadMedia(File(x.path));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null && _conversationId != null) {
      await _uploadMedia(File(result.files.single.path!));
    }
  }

  Future<void> _uploadMedia(File file) async {
    try {
      await ChatApiService.uploadMedia(_conversationId!, file);
      // Gateway broadcasts new_message to room — _onNew handles the UI update
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Upload failed: $e');
      }
    }
  }

  // ── Attachment sheet ────────────────────────────────────────────────────────
  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _AttachOption(icon: Icons.photo_library_outlined, label: 'Gallery', onTap: () { Navigator.pop(context); _pickFromGallery(); }),
            _AttachOption(icon: Icons.insert_drive_file_outlined, label: 'Document', onTap: () { Navigator.pop(context); _pickFile(); }),
            _AttachOption(icon: Icons.medical_information_outlined, label: 'Medical Record', onTap: () { Navigator.pop(context); _showRecordPicker(); }),
          ]),
        ),
      ),
    );
  }

  // ── Record picker ───────────────────────────────────────────────────────────
  void _showRecordPicker() {
    if (_conversationId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              const Icon(Icons.medical_information_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Share Medical Record',
                  style: TextStyle(
                      color: context.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sampleRecords.length,
              itemBuilder: (_, i) {
                final rec = sampleRecords[i];
                return ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(rec.title,
                      style: TextStyle(
                          color: context.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  subtitle: Text(
                    '${rec.typeLabel}  •  ${rec.date.day}/${rec.date.month}/${rec.date.year}',
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.send_rounded,
                      color: AppColors.primary, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    final content =
                        '📋 ${rec.title}\n${rec.typeLabel}  •  ${rec.doctorOrFacility}\n${rec.date.day}/${rec.date.month}/${rec.date.year}';
                    ChatService.instance.sendMessage(
                        _conversationId!, content);
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ── Long-press message options ──────────────────────────────────────────────
  void _showMsgOptions(ChatMsg msg) {
    final isMe = msg.senderId == _myId;
    if (msg.isDeletedForEveryone) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (isMe && msg.type == 'text')
              _AttachOption(
                icon: Icons.edit_outlined,
                label: 'Edit Message',
                onTap: () { Navigator.pop(context); _editMsg(msg); },
              ),
            if (isMe)
              _AttachOption(
                icon: Icons.delete_sweep_outlined,
                label: 'Delete for Everyone',
                color: Colors.red,
                onTap: () { Navigator.pop(context); _deleteEveryone(msg); },
              ),
            _AttachOption(
              icon: Icons.delete_outline_rounded,
              label: 'Delete for Me',
              color: Colors.red,
              onTap: () { Navigator.pop(context); _deleteForMe(msg); },
            ),
          ]),
        ),
      ),
    );
  }

  void _editMsg(ChatMsg msg) {
    final ctrl = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: ctrl, maxLines: null, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context);
              ChatService.instance.editMessage(msg.id, text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteEveryone(ChatMsg msg) {
    ChatService.instance.deleteForEveryone(msg.id);
  }

  void _deleteForMe(ChatMsg msg) {
    ChatApiService.deleteForMe(msg.id);
    setState(() => _messages.removeWhere((m) => m.id == msg.id));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    FcmService.activeChatConversationId = null;
    _typingDebounce?.cancel();
    if (_isSendingTyping && _conversationId != null) {
      ChatService.instance.stopTyping(_conversationId!, otherId: widget.doctorId);
    }
    if (_conversationId != null) ChatService.instance.leaveRoom(_conversationId!);
    ChatService.instance.offAll();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? null : const Color(0xFFF7F8FA),
      appBar: ChatAppBar(
        name: widget.doctorName,
        subtitle: widget.specialization,
        imageUrl: widget.doctorImageUrl,
        isOnline: _doctorOnline,
        isVerifiedDoctor: true,
        isTyping: _doctorTyping,
        lastSeen: _lastSeen,
        actions: [
          IconButton(
              icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        ValueListenableBuilder<bool>(
          valueListenable: ChatService.instance.connectionNotifier,
          builder: (_, connected, __) {
            if (connected) return const SizedBox.shrink();
            return const ConnectionBanner();
          },
        ),
        Expanded(child: _buildBody()),
        if (_doctorTyping)
          TypingIndicator(name: widget.doctorName),
        if (_replyTo != null)
          ReplyBar(
            message: _replyTo!,
            myId: _myId,
            onCancel: () => setState(() => _replyTo = null),
          ),
        ChatInputBar(
          controller: _ctrl,
          onSend: _send,
          onAttach: _showAttachMenu,
          onCamera: _pickFromCamera,
          onChanged: _onTextChanged,
        ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: AppColors.grey), textAlign: TextAlign.center),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text('No messages yet. Say hello!', style: TextStyle(color: AppColors.grey)),
      );
    }
    final items = buildChatItems(
      messages: _messages,
      myId: _myId,
      myColor: AppColors.primary,
      baseUrl: ApiService.baseUrl,
      onLongPress: _showMsgOptions,
      onImageTap: (url) => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ImageFullScreen(url: url))),
      onSwipeReply: (msg) => setState(() => _replyTo = msg),
      onTapReply: _scrollToMessage,
      keyFor: _keyFor,
      highlightedMessageId: _highlightedId,
    );
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }
}

// ── Helper widgets for sheets ─────────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _AttachOption({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.text;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c, fontSize: 15)),
      onTap: onTap,
    );
  }
}

