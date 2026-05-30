import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CategoryScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<CategoryItem> items;

  const CategoryScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  // ── Pre-built category data ──────────────────────────
static CategoryScreen pharmacy(BuildContext context) => CategoryScreen(
        title: context.l.pharmacy,
        icon: Icons.local_pharmacy_outlined,
        color: const Color(0xFF4CAF50),
        items:  [
          CategoryItem(context.l.alNahda, '0.3 km away', '8AM - 12AM',
              Icons.local_pharmacy_outlined, const Color(0xFF4CAF50)),
          CategoryItem(context.l.dawaa, '0.7 km away', '24 Hours', Icons.local_pharmacy_outlined,
              const Color(0xFF4CAF50)),
          CategoryItem(context.l.seif, '1.1 km away', '9AM - 11PM', Icons.local_pharmacy_outlined,
              const Color(0xFF4CAF50)),
          CategoryItem(context.l.cairo, '1.8 km away', '8AM - 10PM',
              Icons.local_pharmacy_outlined, const Color(0xFF4CAF50)),
          CategoryItem(context.l.elEzaby, '2.2 km away', '24 Hours',
              Icons.local_pharmacy_outlined, const Color(0xFF4CAF50)),
        ],
      );

  static  CategoryScreen labs(BuildContext context) => CategoryScreen(
        title: context.l.labs,
        icon: Icons.science_outlined,
        color: const Color(0xFF00BCD4),
        items:  [
          CategoryItem(context.l.alphaMedical, '0.5 km away', '7AM - 9PM', Icons.science_outlined,
              const Color(0xFF00BCD4)),
          CategoryItem(context.l.nileDiagnostics,  '1.0 km away', '8AM - 8PM', Icons.biotech_outlined,
              const Color(0xFF00BCD4)),
          CategoryItem(context.l.cairoCenter,  '1.4 km away', '7AM - 10PM', Icons.science_outlined,
              const Color(0xFF00BCD4)),
          CategoryItem(context.l.elite,         '2.0 km away', '8AM - 6PM', Icons.biotech_outlined, const Color(0xFF00BCD4)),
        ],
      );

  static CategoryScreen scans(BuildContext context) => CategoryScreen(
        title: context.l.scans,
        icon: Icons.document_scanner_outlined,
        color: const Color(0xFF9C27B0),
        items:  [
          CategoryItem(context.l.radiologyPlus,    '0.6 km away', '8AM - 10PM',
              Icons.document_scanner_outlined,const Color(0xFF9C27B0)),
          CategoryItem(context.l.mriScanCenter, '1.2 km away', '9AM - 9PM', Icons.hub_outlined,
             const Color(0xFF9C27B0)),
          CategoryItem(context.l.cairoRadiology,   '1.6 km away', '8AM - 8PM',
              Icons.document_scanner_outlined,const Color(0xFF9C27B0)),
          CategoryItem(context.l.advancedImaging,  '2.5 km away', '7AM - 7PM', Icons.hub_outlined,
              const Color(0xFF9C27B0)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: TextStyle(color: context.text)),
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(context.isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${items.length} near you',
                    style: const TextStyle(color: AppColors.grey, fontSize: 13)),
              ]),
            ]),
          ),

          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ItemCard(item: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final CategoryItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: context.isDark ? Border.all(color: context.divider) : null,
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.color.withOpacity(context.isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: TextStyle(color: context.text, fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 12, color: item.color),
                const SizedBox(width: 4),
                Text(item.distance,
                    style: TextStyle(color: item.color, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                Icon(Icons.access_time_outlined, size: 12, color: AppColors.grey),
                const SizedBox(width: 4),
                Text(item.hours, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
              ]),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: item.color),
        ),
      ]),
    );
  }
}

class CategoryItem {
  final String name, distance, hours;
  final IconData icon;
  final Color color;
  const CategoryItem(this.name, this.distance, this.hours, this.icon, this.color);
}
