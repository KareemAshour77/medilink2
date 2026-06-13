/// Parsed result of an Egyptian 14-digit national ID.
///
/// Format: `C YYMMDD GG SSS G K`
///  - `C`      century digit (2 → 1900s, 3 → 2000s)
///  - `YYMMDD` date of birth
///  - 13th digit (index 12) parity → gender (odd = male, even = female)
class NationalIdInfo {
  final bool isValid;
  final DateTime? dateOfBirth;
  final String? gender; // 'male' | 'female'

  const NationalIdInfo._({
    required this.isValid,
    this.dateOfBirth,
    this.gender,
  });

  static const invalid = NationalIdInfo._(isValid: false);

  /// Parses [id]. Returns [NationalIdInfo.invalid] for any structural or
  /// calendar error (wrong length, bad century digit, impossible date).
  factory NationalIdInfo.parse(String id) {
    final value = id.trim();
    if (!RegExp(r'^\d{14}$').hasMatch(value)) return invalid;

    final centuryDigit = value[0];
    final centuryBase = centuryDigit == '2'
        ? 1900
        : centuryDigit == '3'
            ? 2000
            : null;
    if (centuryBase == null) return invalid;

    final year = centuryBase + int.parse(value.substring(1, 3));
    final month = int.parse(value.substring(3, 5));
    final day = int.parse(value.substring(5, 7));

    if (month < 1 || month > 12 || day < 1 || day > 31) return invalid;

    final date = DateTime(year, month, day);
    // Reject overflow dates like Feb 30 (DateTime rolls them over).
    if (date.year != year || date.month != month || date.day != day) {
      return invalid;
    }

    final genderDigit = int.parse(value[12]);
    final gender = genderDigit.isOdd ? 'male' : 'female';

    return NationalIdInfo._(
      isValid: true,
      dateOfBirth: date,
      gender: gender,
    );
  }

  /// 'YYYY-MM-DD' for display / API.
  String? get dateOfBirthLabel {
    final d = dateOfBirth;
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
