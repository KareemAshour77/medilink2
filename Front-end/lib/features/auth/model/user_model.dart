import '../../../core/services/api_service.dart';

enum UserRole { patient, doctor, pharmacy, labs }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? token;
  final String? image;
  final double? latitude;
  final double? longitude;
  // Doctors only: 'pending' | 'approved' | 'rejected'. Null for other roles.
  final String? verificationStatus;
  // Public, shareable 7-digit account ID (read-only).
  final String? medilinkId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
    this.image,
    this.latitude,
    this.longitude,
    this.verificationStatus,
    this.medilinkId,
  });

  bool get isPendingDoctor =>
      role == UserRole.doctor && verificationStatus == 'pending';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        role: _parseRole(j['role']),
        token: j['access_token'],
        // Guard against double-prefixing: if the stored value is already a full
        // URL (e.g. loaded back from SharedPreferences), use it as-is.
        image: j['image'] != null
            ? (j['image'].toString().startsWith('http')
                ? j['image'].toString()
                : '${ApiService.baseUrl}/${j['image']}')
            : null,
        latitude: _parseDouble(j['latitude']),
        longitude: _parseDouble(j['longitude']),
        verificationStatus: j['verification_status']?.toString(),
        medilinkId: j['medilink_id']?.toString(),
      );

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? token,
    String? image,
    double? latitude,
    double? longitude,
    String? verificationStatus,
    String? medilinkId,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        token: token ?? this.token,
        image: image ?? this.image,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        medilinkId: medilinkId ?? this.medilinkId,
      );

  static UserRole _parseRole(dynamic r) {
    final role = (r ?? '').toString().toLowerCase().trim();

    if (role.contains('doctor')) {
      return UserRole.doctor;
    } else if (role.contains('pharmacy')) {
      return UserRole.pharmacy;
    } else if (role.contains('lab') || role.contains('scans') || role.contains('radiology')) {
      return UserRole.labs;
    } else {
      return UserRole.patient;
    }
  }

  static double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }
}
