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
  final int lastQuizTakenTimestamp;
  final int quizStreak;

  EngagementState({
    required this.sbiCoins,
    required this.streakCount,
    required this.achievements,
    this.lastQuizTakenTimestamp = 0,
    this.quizStreak = 0,
  });

  EngagementState copyWith({
    int? sbiCoins,
    int? streakCount,
    List<String>? achievements,
    int? lastQuizTakenTimestamp,
    int? quizStreak,
  }) {
    return EngagementState(
      sbiCoins: sbiCoins ?? this.sbiCoins,
      streakCount: streakCount ?? this.streakCount,
      achievements: achievements ?? this.achievements,
      lastQuizTakenTimestamp: lastQuizTakenTimestamp ?? this.lastQuizTakenTimestamp,
      quizStreak: quizStreak ?? this.quizStreak,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sbiCoins': sbiCoins,
      'streakCount': streakCount,
      'achievements': achievements,
      'lastQuizTakenTimestamp': lastQuizTakenTimestamp,
      'quizStreak': quizStreak,
    };
  }

  factory EngagementState.fromJson(Map<String, dynamic> json) {
    return EngagementState(
      sbiCoins: json['sbiCoins'] ?? 0,
      streakCount: json['streakCount'] ?? 0,
      achievements: List<String>.from(json['achievements'] ?? []),
      lastQuizTakenTimestamp: json['lastQuizTakenTimestamp'] ?? 0,
      quizStreak: json['quizStreak'] ?? 0,
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

class FixedDeposit {
  final String id;
  final String title;
  final double principalAmount;
  final double interestRate;
  final DateTime maturityDate;
  final bool isAutoRenew;

  FixedDeposit({
    required this.id,
    required this.title,
    required this.principalAmount,
    required this.interestRate,
    required this.maturityDate,
    required this.isAutoRenew,
  });

  FixedDeposit copyWith({
    String? id,
    String? title,
    double? principalAmount,
    double? interestRate,
    DateTime? maturityDate,
    bool? isAutoRenew,
  }) {
    return FixedDeposit(
      id: id ?? this.id,
      title: title ?? this.title,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate: interestRate ?? this.interestRate,
      maturityDate: maturityDate ?? this.maturityDate,
      isAutoRenew: isAutoRenew ?? this.isAutoRenew,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'maturityDate': maturityDate.toIso8601String(),
      'isAutoRenew': isAutoRenew,
    };
  }

  factory FixedDeposit.fromJson(Map<String, dynamic> json) {
    return FixedDeposit(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      principalAmount: (json['principalAmount'] ?? 0.0).toDouble(),
      interestRate: (json['interestRate'] ?? 0.0).toDouble(),
      maturityDate: DateTime.parse(json['maturityDate'] ?? DateTime.now().toIso8601String()),
      isAutoRenew: json['isAutoRenew'] ?? false,
    );
  }
}

class SipInvestment {
  final String id;
  final String fundName;
  final double amount;
  final String nextPaymentDate;
  final String category;
  final String status;

  SipInvestment({
    required this.id,
    required this.fundName,
    required this.amount,
    required this.nextPaymentDate,
    required this.category,
    required this.status,
  });

  SipInvestment copyWith({
    String? id,
    String? fundName,
    double? amount,
    String? nextPaymentDate,
    String? category,
    String? status,
  }) {
    return SipInvestment(
      id: id ?? this.id,
      fundName: fundName ?? this.fundName,
      amount: amount ?? this.amount,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fundName': fundName,
      'amount': amount,
      'nextPaymentDate': nextPaymentDate,
      'category': category,
      'status': status,
    };
  }

  factory SipInvestment.fromJson(Map<String, dynamic> json) {
    return SipInvestment(
      id: json['id'] ?? '',
      fundName: json['fundName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      nextPaymentDate: json['nextPaymentDate'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? 'active',
    );
  }
}

class Loan {
  final String id;
  final String title;
  final String accountNumber;
  final double outstandingBalance;
  final double emiAmount;
  final String nextDueDate;
  final double percentRepaid;

  Loan({
    required this.id,
    required this.title,
    required this.accountNumber,
    required this.outstandingBalance,
    required this.emiAmount,
    required this.nextDueDate,
    required this.percentRepaid,
  });

  Loan copyWith({
    String? id,
    String? title,
    String? accountNumber,
    double? outstandingBalance,
    double? emiAmount,
    String? nextDueDate,
    double? percentRepaid,
  }) {
    return Loan(
      id: id ?? this.id,
      title: title ?? this.title,
      accountNumber: accountNumber ?? this.accountNumber,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      emiAmount: emiAmount ?? this.emiAmount,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      percentRepaid: percentRepaid ?? this.percentRepaid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'accountNumber': accountNumber,
      'outstandingBalance': outstandingBalance,
      'emiAmount': emiAmount,
      'nextDueDate': nextDueDate,
      'percentRepaid': percentRepaid,
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      outstandingBalance: (json['outstandingBalance'] ?? 0.0).toDouble(),
      emiAmount: (json['emiAmount'] ?? 0.0).toDouble(),
      nextDueDate: json['nextDueDate'] ?? '',
      percentRepaid: (json['percentRepaid'] ?? 0.0).toDouble(),
    );
  }
}

class Budget {
  final double spent;
  final double limit;
  final Map<String, double> categoryLimits;
  final Map<String, double> categorySpent;

  Budget({
    required this.spent,
    required this.limit,
    required this.categoryLimits,
    required this.categorySpent,
  });

  Budget copyWith({
    double? spent,
    double? limit,
    Map<String, double>? categoryLimits,
    Map<String, double>? categorySpent,
  }) {
    return Budget(
      spent: spent ?? this.spent,
      limit: limit ?? this.limit,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      categorySpent: categorySpent ?? this.categorySpent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spent': spent,
      'limit': limit,
      'categoryLimits': categoryLimits,
      'categorySpent': categorySpent,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      spent: (json['spent'] ?? 0.0).toDouble(),
      limit: (json['limit'] ?? 0.0).toDouble(),
      categoryLimits: Map<String, double>.from(
        (json['categoryLimits'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v ?? 0.0).toDouble())),
      ),
      categorySpent: Map<String, double>.from(
        (json['categorySpent'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v ?? 0.0).toDouble())),
      ),
    );
  }
}
