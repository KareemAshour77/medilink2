import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/record_access_service.dart';

/// Patient screen to approve/reject doctors' medical-record access requests.
/// Each request is valid for 15 minutes from creation.
class AccessRequestsScreen extends StatefulWidget {
  const AccessRequestsScreen({super.key});

  @override
  State<AccessRequestsScreen> createState() => _AccessRequestsScreenState();
}

class _AccessRequestsScreenState extends State<AccessRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await RecordAccessService.pending();
      if (!mounted) return;
      setState(() { _requests = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _act(String id, bool approve) async {
    setState(() => _busy.add(id));
    try {
      if (approve) {
        await RecordAccessService.approve(id);
      } else {
        await RecordAccessService.reject(id);
      }
      if (!mounted) return;
      setState(() {
        _requests.removeWhere((r) => r['id'] == id);
        _busy.remove(id);
      });
      AppSnackBar.show(context, approve ? context.l.accessGranted : context.l.requestRejected,
          backgroundColor: approve ? AppColors.primary : Colors.black87);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(id));
      AppSnackBar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _expiresIn(dynamic raw) {
    final exp = DateTime.tryParse(raw?.toString() ?? '');
    if (exp == null) return '';
    final mins = exp.difference(DateTime.now()).inMinutes;
    if (mins <= 0) return context.l.accessExpired;
    return '${context.l.expiresInLabel} $mins ${context.l.minutesShort}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.recordsAccess, style: TextStyle(color: context.text)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: AppColors.grey)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: Text(context.l.retry)),
        ]),
      );
    }
    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          const SizedBox(height: 140),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                context.l.noPendingAccess,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey),
              ),
            ),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final r = _requests[i];
          final id = r['id'] as String? ?? '';
          final doctor = r['doctorName'] as String? ?? 'A doctor';
          final specialty = r['specialty'] as String?;
          final busy = _busy.contains(id);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.divider),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(doctor,
                        style: TextStyle(
                            color: context.text, fontWeight: FontWeight.w700, fontSize: 15)),
                    if (specialty != null && specialty.isNotEmpty)
                      Text(specialty, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                  ]),
                ),
                Text(_expiresIn(r['expires_at']),
                    style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              Text(context.l.wantsToViewRecords,
                  style: TextStyle(color: context.text.withOpacity(0.7), fontSize: 13)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _act(id, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: Text(context.l.reject),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : () => _act(id, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(context.l.approve),
                  ),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}
