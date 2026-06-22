class UserProfile {
  final String name;
  final double balance;
  final bool kycComplete;
  final String kycStep; // "none", "pan", "aadhaar", "video_kyc", "complete"
  final bool upiEnabled;
  final String incomeBracket;
  final String bankingNeed;
  final String existingBank;
  final int healthScore;
  final String mobileNumber;
  final String address;

  UserProfile({
    required this.name,
    required this.balance,
    required this.kycComplete,
    required this.kycStep,
    required this.upiEnabled,
    required this.incomeBracket,
    required this.bankingNeed,
    required this.existingBank,
    required this.healthScore,
    this.mobileNumber = '',
    this.address = '',
  });

  UserProfile copyWith({
    String? name,
    double? balance,
    bool? kycComplete,
    String? kycStep,
    bool? upiEnabled,
    String? incomeBracket,
    String? bankingNeed,
    String? existingBank,
    int? healthScore,
    String? mobileNumber,
    String? address,
  }) {
    return UserProfile(
      name: name ?? this.name,
      balance: balance ?? this.balance,
      kycComplete: kycComplete ?? this.kycComplete,
      kycStep: kycStep ?? this.kycStep,
      upiEnabled: upiEnabled ?? this.upiEnabled,
      incomeBracket: incomeBracket ?? this.incomeBracket,
      bankingNeed: bankingNeed ?? this.bankingNeed,
      existingBank: existingBank ?? this.existingBank,
      healthScore: healthScore ?? this.healthScore,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'balance': balance,
      'kycComplete': kycComplete,
      'kycStep': kycStep,
      'upiEnabled': upiEnabled,
      'incomeBracket': incomeBracket,
      'bankingNeed': bankingNeed,
      'existingBank': existingBank,
      'healthScore': healthScore,
      'mobileNumber': mobileNumber,
      'address': address,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      kycComplete: json['kycComplete'] ?? false,
      kycStep: json['kycStep'] ?? 'none',
      upiEnabled: json['upiEnabled'] ?? false,
      incomeBracket: json['incomeBracket'] ?? '',
      bankingNeed: json['bankingNeed'] ?? '',
      existingBank: json['existingBank'] ?? '',
      healthScore: json['healthScore'] ?? 75,
      mobileNumber: json['mobileNumber'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class Transaction {
  final String id;
  final double amount;
  final String payee;
  final String category;
  final DateTime date;
  final String type; // "credit" or "debit"

  Transaction({
    required this.id,
    required this.amount,
    required this.payee,
    required this.category,
    required this.date,
    required this.type,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    String? payee,
    String? category,
    DateTime? date,
    String? type,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      payee: payee ?? this.payee,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'payee': payee,
      'category': category,
      'date': date.toIso8601String(),
      'type': type,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      payee: json['payee'] ?? '',
      category: json['category'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      type: json['type'] ?? 'debit',
    );
  }
}

class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
  });

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'deadline': deadline.toIso8601String(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0.0).toDouble(),
      savedAmount: (json['savedAmount'] ?? 0.0).toDouble(),
      deadline: DateTime.parse(json['deadline'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Recommendation {
  final String id;
  final String title;
  final String subtitle;
  final String aiReason;
  final int priority; // lower value = higher priority
  final bool isCompleted;

  Recommendation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.aiReason,
    required this.priority,
    required this.isCompleted,
  });

  Recommendation copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? aiReason,
    int? priority,
    bool? isCompleted,
  }) {
    return Recommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      aiReason: aiReason ?? this.aiReason,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'aiReason': aiReason,
      'priority': priority,
      'isCompleted': isCompleted,
    };
  }

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      aiReason: json['aiReason'] ?? '',
      priority: json['priority'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class EngagementState {
  final int sbiCoins;
  final int streakCount;
  final List<String> achievements;

  EngagementState({
    required this.sbiCoins,
    required this.streakCount,
    required this.achievements,
  });

  EngagementState copyWith({
    int? sbiCoins,
    int? streakCount,
    List<String>? achievements,
  }) {
    return EngagementState(
      sbiCoins: sbiCoins ?? this.sbiCoins,
      streakCount: streakCount ?? this.streakCount,
      achievements: achievements ?? this.achievements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sbiCoins': sbiCoins,
      'streakCount': streakCount,
      'achievements': achievements,
    };
  }

  factory EngagementState.fromJson(Map<String, dynamic> json) {
    return EngagementState(
      sbiCoins: json['sbiCoins'] ?? 0,
      streakCount: json['streakCount'] ?? 0,
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }
}

class Service {
  final String id;
  final String name;
  final bool isActivated;
  final bool isRecommended;
  final String aiReason;

  Service({
    required this.id,
    required this.name,
    required this.isActivated,
    required this.isRecommended,
    required this.aiReason,
  });

  Service copyWith({
    String? id,
    String? name,
    bool? isActivated,
    bool? isRecommended,
    String? aiReason,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      isActivated: isActivated ?? this.isActivated,
      isRecommended: isRecommended ?? this.isRecommended,
      aiReason: aiReason ?? this.aiReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActivated': isActivated,
      'isRecommended': isRecommended,
      'aiReason': aiReason,
    };
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isActivated: json['isActivated'] ?? false,
      isRecommended: json['isRecommended'] ?? false,
      aiReason: json['aiReason'] ?? '',
    );
  }
}

class SignalSummary {
  final String key;
  final String title;
  final DateTime timestamp;

  SignalSummary({
    required this.key,
    required this.title,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SignalSummary.fromJson(Map<String, dynamic> json) {
    return SignalSummary(
      key: json['key'] ?? '',
      title: json['title'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
