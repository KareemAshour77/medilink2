// lib/screens/home/records_tab.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/records_data.dart';
import 'record_detail_screen.dart';
import 'add_record_screen.dart';

class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  final String _query = '';
  RecordStatus? _statusFilter;
  bool _showTimeline = false;
  final List<MedicalRecord> _records = List.from(sampleRecords);

  // ── Tabs config ───────────────────────────────────────────────────────────
static List<(RecordType, String, IconData)> tabs(BuildContext context) => [
  (RecordType.all, context.l.allRecords, Icons.folder_outlined),
  (RecordType.labTest, context.l.labTest, Icons.biotech_outlined),
  (RecordType.imaging, context.l.imaging, Icons.document_scanner_outlined),
  (RecordType.prescription, context.l.prescriptions, Icons.receipt_long_outlined),
  (RecordType.diagnosis, context.l.diagnosisTab, Icons.medical_information_outlined),
];

bool _initialized = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_initialized) {
    _tabCtrl = TabController(length: tabs(context).length, vsync: this);
    _initialized = true;
  }
}

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MedicalRecord> _filtered(RecordType type) {
    return _records.where((r) {
      final matchType   = type == RecordType.all || r.type == type;
      final matchSearch = _query.isEmpty ||
          r.title.toLowerCase().contains(_query) ||
          r.condition.toLowerCase().contains(_query) ||
          r.doctorOrFacility.toLowerCase().contains(_query);
      final matchStatus = _statusFilter == null || r.status == _statusFilter;
      return matchType && matchSearch && matchStatus;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  void _addRecord(MedicalRecord r) => setState(() => _records.insert(0, r));

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg     = context.bg;
    final card   = context.card;
    final txt    = context.text;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [

          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.l.medicalRecords,
                        style: TextStyle(color: txt, fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text(context.l.documentsStored(_records.length),
                        style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                  ]),
                ),
                // View toggle
                GestureDetector(
                  onTap: () => setState(() => _showTimeline = !_showTimeline),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showTimeline
                          ? AppColors.primary.withOpacity(0.15) : card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _showTimeline ? AppColors.primary : context.divider),
                    ),
                    child: Icon(
                      _showTimeline ? Icons.view_list_rounded : Icons.timeline_rounded,
                      color: _showTimeline ? AppColors.primary : AppColors.grey,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Insights button
                GestureDetector(
                  onTap: () => _showInsights(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: card, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.divider),
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: AppColors.grey, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                // Emergency card
                GestureDetector(
                  onTap: () => _showEmergencyCard(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emergency_outlined,
                        color: AppColors.error, size: 20),
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              // ── Search bar ────────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: txt),
                    decoration: InputDecoration(
                      hintText: 'Search records, diseases…',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.grey, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: AppColors.grey, size: 18),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filter button
                GestureDetector(
                  onTap: () => _showFilter(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _statusFilter != null
                          ? AppColors.primary.withOpacity(0.15) : card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _statusFilter != null
                              ? AppColors.primary : context.divider),
                    ),
                    child: Icon(Icons.filter_list_rounded,
                        color: _statusFilter != null
                            ? AppColors.primary : AppColors.grey,
                        size: 22),
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              // ── Tab bar ───────────────────────────────────────────────────
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: tabs(context).map((t) =>
                  Tab(text: t.$2)
                ).toList(),
              ),
            ]),
          ),

          const Divider(height: 1, thickness: 1),

          // ── Tab views ─────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: tabs(context).map((t) {
                final list = _filtered(t.$1);
                return _showTimeline
                    ? _TimelineView(records: list, txt: txt, card: card, isDark: isDark)
                    : _RecordsList(
                        records: list,
                        txt: txt, card: card, isDark: isDark,
                        onTap: (r) => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => RecordDetailScreen(record: r))),
                      );
              }).toList(),
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => AddRecordScreen(onAdd: _addRecord))),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Record',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Filter bottom sheet ───────────────────────────────────────────────────
  void _showFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Filter by Status',
                style: TextStyle(color: context.text,
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              _FilterChip(label: context.l.allRecords,      selected: _statusFilter == null,
                onTap: () { setState(() => _statusFilter = null); Navigator.pop(context); }),
              const SizedBox(width: 10),
              _FilterChip(label: context.l.stable,   selected: _statusFilter == RecordStatus.stable,
                color: AppColors.success,
                onTap: () { setState(() => _statusFilter = RecordStatus.stable); Navigator.pop(context); }),
              const SizedBox(width: 10),
              _FilterChip(label: context.l.critical, selected: _statusFilter == RecordStatus.critical,
                color: AppColors.error,
                onTap: () { setState(() => _statusFilter = RecordStatus.critical); Navigator.pop(context); }),
              const SizedBox(width: 10),
              _FilterChip(label: context.l.pending,  selected: _statusFilter == RecordStatus.pending,
                color: AppColors.warning,
                onTap: () { setState(() => _statusFilter = RecordStatus.pending); Navigator.pop(context); }),
            ]),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  // ── Insights bottom sheet ─────────────────────────────────────────────────
  void _showInsights(BuildContext context) {
    final total     = _records.length;
    final stable    = _records.where((r) => r.status == RecordStatus.stable).length;
    final critical  = _records.where((r) => r.status == RecordStatus.critical).length;
    final condMap   = <String, int>{};
    for (final r in _records) {
      condMap[r.condition] = (condMap[r.condition] ?? 0) + 1;
    }
    final topCond = condMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Insights & Statistics',
                style: TextStyle(color: context.text,
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Stats row
            Row(children: [
              _StatCard(value: '$total', label: 'Total Records',
                  color: AppColors.primary),
              const SizedBox(width: 12),
              _StatCard(value: '$stable',   label: context.l.stable,   color: AppColors.success),
              const SizedBox(width: 12),
              _StatCard(value: '$critical', label: context.l.critical, color: AppColors.error),
            ]),
            const SizedBox(height: 24),
            Text('Most Frequent Conditions',
                style: TextStyle(color: context.text,
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...topCond.take(5).map((e) => _ConditionBar(
              condition: e.key, count: e.value, total: total,
              txt: context.text,
            )),
            const SizedBox(height: 24),
            Text('Records by Type',
                style: TextStyle(color: context.text,
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...[
              (RecordType.labTest,     context.l.labTest,    AppColors.cyan,   Icons.biotech_outlined),
              (RecordType.imaging,     context.l.imaging,      AppColors.purple, Icons.document_scanner_outlined),
              (RecordType.prescription, context.l.prescription,AppColors.success,Icons.receipt_long_outlined),
              (RecordType.diagnosis,   context.l.diagnosis,    AppColors.error,  Icons.medical_information_outlined),
            ].map((t) {
              final count = _records.where((r) => r.type == t.$1).length;
              return _TypeRow(icon: t.$4, label: t.$2, count: count, color: t.$3, txt: context.text);
            }),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  // ── Emergency card bottom sheet ───────────────────────────────────────────
  void _showEmergencyCard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.emergency_outlined, color: AppColors.error, size: 24),
            const SizedBox(width: 10),
            Text('Emergency Card',
                style: TextStyle(color: context.text,
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          const Text('Critical info for first responders',
              style: TextStyle(color: AppColors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          _EmergencySection(title: 'Chronic Diseases',
              items: const ['Diabetes (Type 2)', 'Arrhythmia'],
              color: AppColors.error),
          const SizedBox(height: 16),
          _EmergencySection(title: 'Allergies',
              items: const ['Penicillin', 'Shellfish'],
              color: AppColors.warning),
          const SizedBox(height: 16),
          _EmergencySection(title: 'Current Medications',
              items: const ['Metformin 500mg (twice daily)',
                            'Beta-blocker 25mg (daily)'],
              color: AppColors.primary),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Emergency Info'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ── Records list view ─────────────────────────────────────────────────────────
class _RecordsList extends StatelessWidget {
  final List<MedicalRecord> records;
  final Color txt, card;
  final bool isDark;
  final ValueChanged<MedicalRecord> onTap;
  const _RecordsList({required this.records, required this.txt,
      required this.card, required this.isDark, required this.onTap});

  Color _typeColor(RecordType t) {
    switch (t) {
      case RecordType.labTest:     return AppColors.cyan;
      case RecordType.imaging:     return AppColors.purple;
      case RecordType.prescription:return AppColors.success;
      case RecordType.diagnosis:   return AppColors.error;
      default:                     return AppColors.primary;
    }
  }

  IconData _typeIcon(RecordType t) {
    switch (t) {
      case RecordType.labTest:     return Icons.biotech_outlined;
      case RecordType.imaging:     return Icons.document_scanner_outlined;
      case RecordType.prescription:return Icons.receipt_long_outlined;
      case RecordType.diagnosis:   return Icons.medical_information_outlined;
      default:                     return Icons.folder_outlined;
    }
  }

  Color _statusColor(RecordStatus s) {
    switch (s) {
      case RecordStatus.stable:   return AppColors.success;
      case RecordStatus.critical: return AppColors.error;
      case RecordStatus.pending:  return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_open_outlined,
            color: AppColors.grey.withOpacity(0.4), size: 64),
        const SizedBox(height: 12),
        const Text('No records found',
            style: TextStyle(color: AppColors.grey, fontSize: 15)),
      ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = records[i];
        final color = _typeColor(r.type);
        final statusColor = _statusColor(r.status);
        return GestureDetector(
          onTap: () => onTap(r),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: context.divider) : null,
              boxShadow: isDark ? null : [
                BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 10, offset: const Offset(0, 2))
              ],
            ),
            child: Row(children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(r.type), color: color, size: 24),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.title,
                      style: TextStyle(color: txt,
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(r.doctorOrFacility,
                      style: const TextStyle(color: AppColors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(children: [
                    _MiniChip(label: r.typeLabel,   color: color),
                    const SizedBox(width: 6),
                    _MiniChip(label: r.statusLabel, color: statusColor),
                    const Spacer(),
                    Text(_formatDate(r.date),
                        style: const TextStyle(color: AppColors.grey, fontSize: 11)),
                  ]),
                ],
              )),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.grey, size: 14),
            ]),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month]} ${d.day}';
  }
}

// ── Timeline view ─────────────────────────────────────────────────────────────
class _TimelineView extends StatelessWidget {
  final List<MedicalRecord> records;
  final Color txt, card;
  final bool isDark;
  const _TimelineView({required this.records, required this.txt,
      required this.card, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Group by year → month
    final Map<int, Map<int, List<MedicalRecord>>> grouped = {};
    for (final r in records) {
      grouped.putIfAbsent(r.date.year,  () => {});
      grouped[r.date.year]!.putIfAbsent(r.date.month, () => []);
      grouped[r.date.year]![r.date.month]!.add(r);
    }
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (records.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timeline_rounded,
            color: AppColors.grey.withOpacity(0.4), size: 64),
        const SizedBox(height: 12),
        const Text('No records to display',
            style: TextStyle(color: AppColors.grey, fontSize: 15)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: years.length,
      itemBuilder: (_, yi) {
        final year   = years[yi];
        final months = grouped[year]!.keys.toList()..sort((a, b) => b.compareTo(a));
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Year header
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$year',
                style: const TextStyle(color: AppColors.primary,
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          ...months.map((month) {
            final monthRecords = grouped[year]![month]!;
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Timeline line
              Column(children: [
                Container(width: 12, height: 12,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle)),
                Container(width: 2, height: 60 * monthRecords.length.toDouble(),
                    color: AppColors.primary.withOpacity(0.25)),
              ]),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_monthName(month),
                      style: TextStyle(color: txt,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...monthRecords.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(12),
                      border: isDark ? Border.all(color: context.divider) : null,
                      boxShadow: isDark ? null : [
                        BoxShadow(color: Colors.black.withOpacity(0.04),
                            blurRadius: 6)
                      ],
                    ),
                    child: Row(children: [
                      Expanded(child: Text(r.title,
                          style: TextStyle(color: txt,
                              fontSize: 13, fontWeight: FontWeight.w500))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (r.status == RecordStatus.stable
                              ? AppColors.success : AppColors.error).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(r.statusLabel,
                            style: TextStyle(
                              color: r.status == RecordStatus.stable
                                  ? AppColors.success : AppColors.error,
                              fontSize: 11, fontWeight: FontWeight.w600,
                            )),
                      ),
                    ]),
                  )),
                  const SizedBox(height: 8),
                ],
              )),
            ]);
          }),
          const SizedBox(height: 16),
        ]);
      },
    );
  }

  String _monthName(int m) => const [
    '', 'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ][m];
}

// ── Helper widgets ────────────────────────────────────────────────────────────
class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
      this.color = AppColors.primary, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.15) : context.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? color : context.divider),
      ),
      child: Text(label,
          style: TextStyle(color: selected ? color : AppColors.grey,
              fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color,
            fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 11),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _ConditionBar extends StatelessWidget {
  final String condition;
  final int count, total;
  final Color txt;
  const _ConditionBar({required this.condition, required this.count,
      required this.total, required this.txt});

  @override
  Widget build(BuildContext context) {
    final pct = count / total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(condition, style: TextStyle(color: txt, fontSize: 13)),
        Text('$count records',
            style: const TextStyle(color: AppColors.grey, fontSize: 12)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 8,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }
}

class _TypeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color txt;
  const _TypeRow({required this.icon, required this.label, required this.count,
      required this.color, required this.txt});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: TextStyle(color: txt, fontSize: 14))),
      Text('$count', style: TextStyle(color: color,
          fontSize: 14, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _EmergencySection extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _EmergencySection({required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: TextStyle(color: color,
        fontSize: 13, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    ...items.map((i) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(i, style: TextStyle(color: context.text, fontSize: 14)),
      ]),
    )),
  ]);
}
