import 'dart:math';

// Simple unique ID without extra dependency
String _genId() {
  final now = DateTime.now();
  final rand = Random().nextInt(99999);
  return '${now.millisecondsSinceEpoch}_$rand';
}

enum TimelineEntryType {
  signalDetected,
  recommendation,
  toolStarted,
  toolCompleted,
  toolFailed,
  connection,
  onboarding,
  insight,
}

enum TimelineEntryStatus {
  success,
  running,
  failed,
  info,
}

class TimelineEntry {
  final String id;
  final DateTime timestamp;
  final TimelineEntryType type;
  final String title;
  final String description;
  final TimelineEntryStatus status;

  TimelineEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
  });

  factory TimelineEntry.create({
    required TimelineEntryType type,
    required String title,
    required String description,
    required TimelineEntryStatus status,
  }) {
    return TimelineEntry(
      id: _genId(),
      timestamp: DateTime.now(),
      type: type,
      title: title,
      description: description,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'title': title,
        'description': description,
        'status': status.name,
      };

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: TimelineEntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TimelineEntryType.insight,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      status: TimelineEntryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TimelineEntryStatus.info,
      ),
    );
  }
}
