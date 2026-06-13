/// Formats a doctor's name with a "Dr. " prefix, unless it already has one.
/// Safe to call on names that may already start with "Dr." (won't double it).
String drName(String? name) {
  final n = (name ?? '').trim();
  if (n.isEmpty) return 'Doctor';
  final lower = n.toLowerCase();
  if (lower.startsWith('dr.') || lower.startsWith('dr ')) return n;
  return 'Dr. $n';
}
