enum InAppNotificationType { medication, doctor, general }

class InAppNotification {
  final String id;
  final String title;
  final String description;
  final DateTime time;
  final InAppNotificationType type;
  final String? medicationName;
  final String? doseStr;
  bool isDismissed;

  InAppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    this.medicationName,
    this.doseStr,
    this.isDismissed = false,
  });
}
