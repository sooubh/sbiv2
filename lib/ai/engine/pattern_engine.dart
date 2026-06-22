import 'package:sbiv2/data/models/models.dart';

class PatternEngineSignals {
  final bool spendingSpike;
  final bool idleBalance;
  final bool missedRecurring;
  final bool lowBalance;
  final bool salaryNoSave;
  final String summaryForAgent;
  final List<String> activeSignalsList;

  PatternEngineSignals({
    required this.spendingSpike,
    required this.idleBalance,
    required this.missedRecurring,
    required this.lowBalance,
    required this.salaryNoSave,
    required this.summaryForAgent,
    required this.activeSignalsList,
  });
}

class PatternEngine {
  static PatternEngineSignals analyze(UserProfile profile, List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return PatternEngineSignals(
        spendingSpike: false,
        idleBalance: false,
        missedRecurring: false,
        lowBalance: profile.balance < 1000,
        salaryNoSave: false,
        summaryForAgent: "This is a new customer named ${profile.name} with a balance of ₹${profile.balance}. No transactions recorded yet. They need to undergo KYC onboarding and UPI activation.",
        activeSignalsList: profile.balance < 1000 ? ["Low Balance"] : [],
      );
    }

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    // 1. Calculate average monthly credit/debit
    double currentMonthSpend = 0.0;
    double prevMonthSpend = 0.0;
    double totalCredits = 0.0;
    double last7DaysCredits = 0.0;
    double last7DaysInvestments = 0.0;
    bool hasSIPInPrevMonth = false;
    bool hasSIPInCurrentMonth = false;

    Map<String, double> categorySpendCurrent = {};
    Map<String, double> categorySpendPrev = {};

    for (var tx in transactions) {
      // Current Month (last 30 days)
      if (tx.date.isAfter(thirtyDaysAgo)) {
        if (tx.type == 'debit') {
          currentMonthSpend += tx.amount;
          categorySpendCurrent[tx.category] = (categorySpendCurrent[tx.category] ?? 0.0) + tx.amount;
          if (tx.category == 'Investment' || tx.payee.contains('SIP') || tx.payee.contains('Mutual Fund')) {
            hasSIPInCurrentMonth = true;
          }
        } else {
          totalCredits += tx.amount;
          if (tx.date.isAfter(now.subtract(const Duration(days: 7)))) {
            last7DaysCredits += tx.amount;
          }
        }
      }
      // Previous Month (30 to 60 days ago)
      else if (tx.date.isAfter(sixtyDaysAgo) && tx.date.isBefore(thirtyDaysAgo)) {
        if (tx.type == 'debit') {
          prevMonthSpend += tx.amount;
          categorySpendPrev[tx.category] = (categorySpendPrev[tx.category] ?? 0.0) + tx.amount;
          if (tx.category == 'Investment' || tx.payee.contains('SIP') || tx.payee.contains('Mutual Fund')) {
            hasSIPInPrevMonth = true;
          }
        }
      }

      // Last 7 days check for investments/savings
      if (tx.date.isAfter(now.subtract(const Duration(days: 7)))) {
        if (tx.type == 'debit' && (tx.category == 'Investment' || tx.payee.contains('SIP') || tx.payee.contains('FD'))) {
          last7DaysInvestments += tx.amount;
        }
      }
    }

    // Signals logic
    // 1. Spending Spike: category spend in current month is > 150% of previous month's category spend (minimum ₹1000 diff)
    bool spendingSpike = false;
    String spikeCategory = "";
    categorySpendCurrent.forEach((cat, amt) {
      final prevAmt = categorySpendPrev[cat] ?? 0.0;
      if (prevAmt > 0 && amt > prevAmt * 1.5 && (amt - prevAmt) > 1000) {
        spendingSpike = true;
        spikeCategory = cat;
      }
    });

    // 2. Idle Balance: balance > 3x current month's spend (or last month's spend if current is low) AND no investments in last 30 days
    final avgSpend = currentMonthSpend > 0 ? currentMonthSpend : (prevMonthSpend > 0 ? prevMonthSpend : 15000.0);
    bool idleBalance = (profile.balance > avgSpend * 3) && !hasSIPInCurrentMonth;

    // 3. Missed Recurring: payee seen in previous month but not in this month (like SIP)
    bool missedRecurring = hasSIPInPrevMonth && !hasSIPInCurrentMonth;

    // 4. Low Balance: balance < 20% of monthly average credit/salary
    final avgCredit = totalCredits > 0 ? totalCredits : 50000.0;
    bool lowBalance = profile.balance < (avgCredit * 0.20);

    // 5. Salary No Save: large credit in last 7 days (> ₹20,000) but zero savings/investments in last 7 days
    bool salaryNoSave = (last7DaysCredits > 20000.0) && (last7DaysInvestments == 0.0);

    // Build plain English summary for Gemini
    List<String> signals = [];
    List<String> alerts = [];

    if (spendingSpike) {
      signals.add("spendingSpike ($spikeCategory)");
      alerts.add("Spike in $spikeCategory spending this month compared to last month.");
    }
    if (idleBalance) {
      signals.add("idleBalance");
      alerts.add("Large idle balance of ₹${profile.balance.toStringAsFixed(0)} in savings account, earning minimal interest, with no active investments this month.");
    }
    if (missedRecurring) {
      signals.add("missedRecurring");
      alerts.add("Missed SBI Mutual Fund SIP payment in the current month, which was paid last month.");
    }
    if (lowBalance) {
      signals.add("lowBalance");
      alerts.add("Low account balance of ₹${profile.balance.toStringAsFixed(0)} which is below safe buffer levels.");
    }
    if (salaryNoSave) {
      signals.add("salaryNoSave");
      alerts.add("Received salary credit of ₹${last7DaysCredits.toStringAsFixed(0)} in the last 7 days, but has not made any savings or SIP allocation yet.");
    }

    String summary = "User Profile: ${profile.name}, Balance: ₹${profile.balance.toStringAsFixed(2)}, KYC Complete: ${profile.kycComplete}, UPI Active: ${profile.upiEnabled}.\n";
    if (alerts.isEmpty) {
      summary += "No critical financial anomalies detected. Overall financial health is stable.";
    } else {
      summary += "Active Signals Detected:\n" + alerts.map((a) => "- $a").join("\n");
    }

    return PatternEngineSignals(
      spendingSpike: spendingSpike,
      idleBalance: idleBalance,
      missedRecurring: missedRecurring,
      lowBalance: lowBalance,
      salaryNoSave: salaryNoSave,
      summaryForAgent: summary,
      activeSignalsList: signals,
    );
  }
}
