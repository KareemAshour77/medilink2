// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
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
  bool _isSearching = false;
  GoogleMapController? _controller;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = SessionService.currentUser;
    _selected = LatLng(
      user?.latitude ?? 30.0444,
      user?.longitude ?? 31.2357,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _moveTo(LatLng p, {double zoom = 15}) {
    setState(() => _selected = p);
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(p, zoom));
  }

  // ── Search an address and jump the pin there ──────────────────────────────
  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);
    try {
      final results = await locationFromAddress(query);
      if (!mounted) return;
      if (results.isEmpty) {
        AppSnackBar.show(context, 'No place found for "$query".');
        return;
      }
      _moveTo(LatLng(results.first.latitude, results.first.longitude));
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Could not find that address.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ── Jump the pin to the doctor's current GPS position ─────────────────────
  Future<void> _useCurrentLocation() async {
    final pos = await LocationService.getLocation();
    if (!mounted) return;
    if (pos != null) {
      _moveTo(LatLng(pos.latitude, pos.longitude));
    } else {
      AppSnackBar.show(context, 'Could not get location. Check GPS and permission.');
    }
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
      AppSnackBar.show(
        context,
        response['message']?.toString() ??
            response['error']?.toString() ??
            'Failed to save location',
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

    AppSnackBar.show(context, 'Location saved successfully', backgroundColor: Colors.green);
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
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (c) => _controller = c,
                  initialCameraPosition:
                      CameraPosition(target: _selected, zoom: 14),
                  onTap: (pos) => setState(() => _selected = pos),
                  markers: {
                    Marker(
                      markerId: const MarkerId('clinic'),
                      position: _selected,
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

                // ── Search bar overlay ──────────────────────────────────
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(14),
                    color: context.card,
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchAddress,
                      style: TextStyle(color: context.text, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search clinic or address…',
                        hintStyle:
                            const TextStyle(color: AppColors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.grey, size: 20),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    color: RoleTheme.doctor, size: 20),
                                onPressed: () =>
                                    _searchAddress(_searchCtrl.text),
                              ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // ── Use my current location button ──────────────────────
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'gps',
                    backgroundColor: context.card,
                    foregroundColor: RoleTheme.doctor,
                    onPressed: _useCurrentLocation,
                    child: const Icon(Icons.my_location_rounded),
                  ),
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
                    'Search, tap the map, or use your location to place the clinic pin.',
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
