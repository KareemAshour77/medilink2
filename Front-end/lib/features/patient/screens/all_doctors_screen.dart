// ignore_for_file: prefer_const_constructors

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/location_service.dart';
import 'doctor_details_screen.dart';

class AllDoctorsScreen extends StatefulWidget {
  const AllDoctorsScreen({super.key});

  @override
  State<AllDoctorsScreen> createState() => _AllDoctorsScreenState();
}

class _AllDoctorsScreenState extends State<AllDoctorsScreen> {
  List<_Doctor> _doctors = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch all doctors from the backend
      final raw = await ApiService.fetchAllDoctors();

      // Try to get patient GPS so we can compute distance labels
      final position = LocationService.cached ??
          await LocationService.getLocation();

      final doctors = raw.map((j) {
        final docLat = (j['latitude'] as num?)?.toDouble();
        final docLng = (j['longitude'] as num?)?.toDouble();

        String? distLabel;
        if (position != null && docLat != null && docLng != null) {
          final dist = _haversine(
            position.latitude, position.longitude, docLat, docLng,
          );
          distLabel = dist < 1
              ? '${(dist * 1000).round()} m away'
              : '${dist.toStringAsFixed(1)} km away';
        }

        return _Doctor(
          id: j['id'] as String? ?? '',
          name: j['name'] as String? ?? 'Doctor',
          spec: j['specialty'] as String? ?? 'General Practitioner',
          imageUrl: j['image'] != null
              ? '${ApiService.baseUrl}/${j['image']}'
              : null,
          distLabel: distLabel,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _doctors = doctors;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load doctors. Check your connection.';
        _loading = false;
      });
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = math.pi / 180 * (lat2 - lat1);
    final dLon = math.pi / 180 * (lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(math.pi / 180 * lat1) *
            math.cos(math.pi / 180 * lat2) *
            math.pow(math.sin(dLon / 2), 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l.topDoctors,
            style: TextStyle(color: context.text)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.text),
            onPressed: _loadDoctors,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppColors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadDoctors,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded, size: 56, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(
              'No doctors registered yet.',
              style: TextStyle(color: AppColors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _doctors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _DoctorCard(doctor: _doctors[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Doctor {
  final String id, name, spec;
  final String? imageUrl;
  final String? distLabel;

  const _Doctor({
    required this.id,
    required this.name,
    required this.spec,
    this.imageUrl,
    this.distLabel,
  });
}

class _DoctorCard extends StatelessWidget {
  final _Doctor doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    void openDetails() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorDetailsScreen(
            name: doctor.name,
            specialization: doctor.spec,
            rating: 0.0,
            reviews: 0,
            doctorId: doctor.id,
            doctorImageUrl: doctor.imageUrl,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: openDetails,
      child: Container(
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
          CircleAvatar(
            radius: 28,
            backgroundColor:
                AppColors.primary.withOpacity(context.isDark ? 0.25 : 0.12),
            backgroundImage: doctor.imageUrl != null
                ? NetworkImage(doctor.imageUrl!)
                : null,
            child: doctor.imageUrl == null
                ? const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 30)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name,
                    style: TextStyle(
                        color: context.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(doctor.spec,
                    style:
                        const TextStyle(color: AppColors.grey, fontSize: 13)),
                if (doctor.distLabel != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 13),
                    const SizedBox(width: 3),
                    Text(doctor.distLabel!,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ]),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: openDetails,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(context.l.book,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
