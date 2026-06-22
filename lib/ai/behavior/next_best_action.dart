enum NextBestActionType {
  kyc,
  sip,
  lowBalance,
  fd,
  salarySave,
  spendingSpike,
  goalNudge,
  healthSummary,
}

class NextBestAction {
  final String id;
  final String title;
  final String subtitle;
  final String aiReason;
  final String actionText;
  final NextBestActionType type;
  final int priority; // Lower = higher priority (1 is highest)
  final Map<String, dynamic> payload;

  const NextBestAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.aiReason,
    required this.actionText,
    required this.type,
    required this.priority,
    required this.payload,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'aiReason': aiReason,
      'actionText': actionText,
      'type': type.name,
      'priority': priority,
      'payload': payload,
    };
  }

  factory NextBestAction.fromJson(Map<String, dynamic> json) {
    return NextBestAction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      aiReason: json['aiReason'] ?? '',
      actionText: json['actionText'] ?? '',
      type: NextBestActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NextBestActionType.healthSummary,
      ),
      priority: json['priority'] ?? 8,
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
    );
  }
}
