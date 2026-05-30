// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/model/user_model.dart';

class DoctorLocationPickerScreen extends StatefulWidget {
  const DoctorLocationPickerScreen({super.key});

  @override
  State<DoctorLocationPickerScreen> createState() =>
      _DoctorLocationPickerScreenState();
}

class _DoctorLocationPickerScreenState
    extends State<DoctorLocationPickerScreen> {
  late LatLng _selected;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = SessionService.currentUser;
    _selected = LatLng(
      user?.latitude ?? 30.0444,
      user?.longitude ?? 31.2357,
    );
  }

  Future<void> _saveLocation() async {
    setState(() => _isSaving = true);

    final response = await ApiService.updateMyLocation(
      latitude: _selected.latitude,
      longitude: _selected.longitude,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (response['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ??
              response['error']?.toString() ??
              'Failed to save location'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final current = SessionService.currentUser;
    if (current != null) {
      await SessionService.saveUser(
        UserModel.fromJson({
          ...response,
          'access_token': current.token,
        }),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location saved successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Clinic location',
          style: TextStyle(color: context.text, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selected,
                initialZoom: 14,
                onTap: (_, point) => setState(() => _selected = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.medilink.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected,
                      width: 54,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          color: RoleTheme.doctor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_pin,
                          color: RoleTheme.doctor,
                          size: 42,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: context.card,
              border: Border(top: BorderSide(color: context.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tap the map to place your clinic pin.',
                    style: TextStyle(
                      color: context.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat ${_selected.latitude.toStringAsFixed(6)}, '
                    'Lng ${_selected.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveLocation,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_alt_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Save location'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: RoleTheme.doctor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
