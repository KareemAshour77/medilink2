import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/utils/record_labels.dart';
import 'patient_details_screen.dart';

class DoctorPatients extends StatefulWidget {
  const DoctorPatients({super.key});
  @override
  State<DoctorPatients> createState() => _DoctorPatientsState();
}

class _DoctorPatientsState extends State<DoctorPatients> {
  final _searchCtrl = TextEditingController();
  final _focusNode  = FocusNode();
  bool _searchFocused = false;
  int _filterIndex = 0;

  static const _filters = ['All', 'Active', 'Ended'];

  // Real patients, connected through confirmed appointments.
  List<Map<String, String>> _patients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _searchFocused = _focusNode.hasFocus);
    });
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await AppointmentService.getDoctorPatients();
      if (!mounted) return;
      setState(() {
        _patients = list.map(_mapPatient).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Map<String, String> _mapPatient(Map<String, dynamic> p) {
    final name = (p['name'] as String?)?.trim().isNotEmpty == true
        ? p['name'] as String
        : 'Patient';
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : '?');
    return {
      'id':        (p['id'] as String?) ?? '',
      'name':      name,
      'age':       (p['gender'] as String?) ?? '',
      'condition': apptTypeLabelL10n(context.l, p['lastType'] as String?),
      'status':    (p['chatActive'] == true) ? 'active' : 'ended',
      'avatar':    initials,
    };
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filtered {
    final query = _searchCtrl.text.toLowerCase();
    final filter = _filters[_filterIndex].toLowerCase();
    return _patients.where((p) {
      final matchSearch = query.isEmpty ||
          p['name']!.toLowerCase().contains(query) ||
          p['condition']!.toLowerCase().contains(query);
      final matchFilter = filter == 'all' || p['status'] == filter;
      return matchSearch && matchFilter;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ended': return AppColors.grey;
      default:      return Colors.green;
    }
  }

  String _filterLabel(BuildContext context, String f) {
    switch (f) {
      case 'Active': return context.l.filterActive;
      case 'Ended':  return context.l.apptEnded;
      default:       return context.l.filterAll;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Top bar ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l.myPatients,
                style: TextStyle(color: context.text, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(
                _loading
                    ? context.l.loadingDots
                    : '${_patients.length} ${context.l.patientsUnderCare}',
                style: const TextStyle(color: AppColors.grey, fontSize: 13)),
            const SizedBox(height: 16),

            // ── Search bar (expands on focus) ─────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _searchFocused
                      ? RoleTheme.doctor.withOpacity(0.5)
                      : context.divider,
                  width: _searchFocused ? 1.5 : 1,
                ),
                boxShadow: _searchFocused
                    ? [BoxShadow(color: RoleTheme.doctor.withOpacity(0.08), blurRadius: 12)]
                    : [],
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.l.searchPatients,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Filter chips ─────────────────────────────────
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = i == _filterIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? RoleTheme.doctor : context.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? RoleTheme.doctor : context.divider,
                        ),
                      ),
                      child: Text(_filterLabel(context, _filters[i]),
                          style: TextStyle(
                            color: sel ? Colors.white : AppColors.grey,
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Patient list ──────────────────────────────────────
        Expanded(child: _buildList(filtered)),
      ]),
    );
  }

  Widget _buildList(List<Map<String, String>> filtered) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: AppColors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: Text(context.l.retry)),
        ]),
      );
    }
    if (_patients.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  context.l.noPatientsYet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (filtered.isEmpty) {
      return Center(child: Text(context.l.noRecordsFound, style: const TextStyle(color: AppColors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _PatientTile(
          patient: filtered[i],
          statusColor: _statusColor(filtered[i]['status']!),
          index: i,
        ),
      ),
    );
  }
}

class _PatientTile extends StatefulWidget {
  final Map<String, String> patient;
  final Color statusColor;
  final int index;
  const _PatientTile({required this.patient, required this.statusColor, required this.index});
  @override
  State<_PatientTile> createState() => _PatientTileState();
}

class _PatientTileState extends State<_PatientTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade  = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _scale = 0.97),
          onTapUp: (_) {
            setState(() => _scale = 1);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientDetailsScreen(patient: widget.patient),
              ),
            );
          },
          onTapCancel: () => setState(() => _scale = 1),
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 140),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.divider, width: 0.5),
                boxShadow: context.isDark ? null : [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(children: [
                Hero(
                  tag: 'avatar_${widget.patient['name']}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: RoleTheme.doctor.withOpacity(0.13),
                    child: Text(widget.patient['avatar']!,
                        style: const TextStyle(color: RoleTheme.doctor, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.patient['name']!,
                      style: TextStyle(color: context.text, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('Age ${widget.patient['age']}  ·  ${widget.patient['condition']}',
                      style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(widget.patient['status']!,
                        style: TextStyle(color: widget.statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.grey),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
