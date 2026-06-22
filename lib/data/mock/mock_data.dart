import 'package:sbiv2/data/models/models.dart';

class MockData {
  static UserProfile get profileA => UserProfile(
        name: 'Rohan',
        balance: 5000.0,
        kycComplete: false,
        kycStep: 'none',
        upiEnabled: false,
        incomeBracket: '0-5 Lakhs',
        bankingNeed: 'Savings & UPI',
        existingBank: 'None',
        healthScore: 40,
      );

  static UserProfile get profileB => UserProfile(
        name: 'Sourabh',
        balance: 124500.0,
        kycComplete: true,
        kycStep: 'complete',
        upiEnabled: true,
        incomeBracket: '15-25 Lakhs',
        bankingNeed: 'Wealth Creation',
        existingBank: 'HDFC',
        healthScore: 82,
      );

  static List<Transaction> get transactionsA => [];

  static List<Transaction> get transactionsB {
    final now = DateTime.now();
    return [
      // Salary Credit on Jun 20
      Transaction(
        id: 'tx_01',
        amount: 75000.0,
        payee: 'TCS Salary Credit',
        category: 'Salary',
        date: now.subtract(const Duration(days: 2)), // 2 days ago
        type: 'credit',
      ),
      // Rent payment on Jun 21
      Transaction(
        id: 'tx_02',
        amount: 15000.0,
        payee: 'House Rent Owner',
        category: 'Rent',
        date: now.subtract(const Duration(days: 1)),
        type: 'debit',
      ),
      // Food on Jun 18
      Transaction(
        id: 'tx_03',
        amount: 2500.0,
        payee: 'Zomato',
        category: 'Food',
        date: now.subtract(const Duration(days: 4)),
        type: 'debit',
      ),
      // May transactions including SIP
      Transaction(
        id: 'tx_04',
        amount: 5000.0,
        payee: 'SBI Bluechip Fund (SIP)',
        category: 'Investment',
        date: now.subtract(const Duration(days: 40)), // ~40 days ago (May)
        type: 'debit',
      ),
      // Other May expenses
      Transaction(
        id: 'tx_05',
        amount: 18000.0,
        payee: 'Credit Card Bill',
        category: 'Bills',
        date: now.subtract(const Duration(days: 35)),
        type: 'debit',
      ),
      Transaction(
        id: 'tx_06',
        amount: 15000.0,
        payee: 'House Rent Owner',
        category: 'Rent',
        date: now.subtract(const Duration(days: 31)),
        type: 'debit',
      ),
      Transaction(
        id: 'tx_07',
        amount: 75000.0,
        payee: 'TCS Salary Credit',
        category: 'Salary',
        date: now.subtract(const Duration(days: 32)),
        type: 'credit',
      ),
    ];
  }

  static List<Goal> get mockGoals => [
        Goal(
          id: 'goal_01',
          name: 'Dream Car',
          targetAmount: 500000.0,
          savedAmount: 45000.0,
          deadline: DateTime.now().add(const Duration(days: 365)),
        ),
        Goal(
          id: 'goal_02',
          name: 'Emergency Fund',
          targetAmount: 100000.0,
          savedAmount: 85000.0,
          deadline: DateTime.now().add(const Duration(days: 120)),
        ),
      ];

  static List<Recommendation> get mockRecommendations => [
        Recommendation(
          id: 'rec_01',
          title: 'Start a Tax Saving FD',
          subtitle: 'Earn 7.25% p.a. & save tax under 80C',
          aiReason: 'Detected idle balance of over ₹1,20,000 in savings account. Moving it to FD yields higher interest.',
          priority: 1,
          isCompleted: false,
        ),
        Recommendation(
          id: 'rec_02',
          title: 'Resume SBI Bluechip SIP',
          subtitle: 'Missed SIP in June. Resume now with 1 click.',
          aiReason: 'PatternEngine detected mutual fund SIP debit in May but none in June.',
          priority: 0,
          isCompleted: false,
        ),
      ];

  static List<Service> get mockServices => [
        Service(
          id: 'srv_sip',
          name: 'SIP (Mutual Fund)',
          isActivated: false,
          isRecommended: true,
          aiReason: 'Sourabh has long term wealth creation needs. Recurring investments fit this goal.',
        ),
        Service(
          id: 'srv_fd',
          name: 'Fixed Deposit (FD)',
          isActivated: false,
          isRecommended: true,
          aiReason: 'Idle funds of ₹1,24,500 detected. FD provides 7.2% secure returns.',
        ),
        Service(
          id: 'srv_insurance',
          name: 'Health Insurance',
          isActivated: false,
          isRecommended: false,
          aiReason: 'Standard protection product for general safety.',
        ),
        Service(
          id: 'srv_loans',
          name: 'Pre-Approved Car Loan',
          isActivated: false,
          isRecommended: true,
          aiReason: 'Rohan/Sourabh is looking for asset purchase, eligible for SBI Quick Loan.',
        ),
        Service(
          id: 'srv_upi',
          name: 'UPI Quick Pay',
          isActivated: true,
          isRecommended: true,
          aiReason: 'Primary need is quick transfers and digital payments.',
        ),
      ];

  static EngagementState get mockEngagement => EngagementState(
        sbiCoins: 120,
        streakCount: 3,
        achievements: ['First Login', 'Profile Setup'],
      );
}
