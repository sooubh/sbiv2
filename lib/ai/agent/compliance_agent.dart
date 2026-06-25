import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/ai/engine/pattern_engine.dart';

enum ComplianceRisk { none, low, medium, high, critical }

class ComplianceResult {
  final ComplianceRisk risk;
  final bool shouldBlock;
  final String message;
  final String? actionRequired;

  const ComplianceResult({
    required this.risk,
    required this.shouldBlock,
    required this.message,
    this.actionRequired,
  });

  static const ComplianceResult clear = ComplianceResult(
    risk: ComplianceRisk.none,
    shouldBlock: false,
    message: 'Transaction cleared by Compliance Agent.',
  );
}

class ComplianceAgent {
  static const String agentId = 'compliance_agent';
  static const String displayName = 'Compliance & Security';
  static const String emoji = '🛡️';

  static bool canHandle(String message) {
    final m = message.toLowerCase();
    return m.contains('kyc') ||
        m.contains('pan') ||
        m.contains('aadhaar') ||
        m.contains('verify') ||
        m.contains('block') ||
        m.contains('fraud') ||
        m.contains('suspicious') ||
        m.contains('limit') ||
        m.contains('international');
  }

  static ComplianceResult evaluateTransaction({
    required UserProfile profile,
    required List<Transaction> transactions,
    required double amount,
    required String transactionType,
  }) {
    if (!profile.kycComplete && amount > 10000) {
      return const ComplianceResult(
        risk: ComplianceRisk.critical,
        shouldBlock: true,
        message: 'Transaction blocked: KYC incomplete. Large transactions require full KYC verification.',
        actionRequired: 'complete_kyc',
      );
    }

    final signals = PatternEngine.analyze(profile, transactions);
    if (signals.spendingSpike && amount > 20000) {
      return ComplianceResult(
        risk: ComplianceRisk.high,
        shouldBlock: false,
        message: 'High spending detected. This ₹${amount.toStringAsFixed(0)} transaction is above your normal pattern.',
        actionRequired: 'confirm_transaction',
      );
    }

    if (amount > 100000) {
      return const ComplianceResult(
        risk: ComplianceRisk.medium,
        shouldBlock: false,
        message: 'High-value transfer: Amounts over ₹1,00,000 require additional MPIN confirmation.',
        actionRequired: 'mpin_confirm',
      );
    }

    final recentUpi = transactions
        .where((t) =>
            t.type == 'debit' &&
            DateTime.now().difference(t.date).inHours < 1)
        .length;
    if (transactionType == 'upi' && recentUpi >= 3) {
      return const ComplianceResult(
        risk: ComplianceRisk.high,
        shouldBlock: true,
        message: '🛡️ Fraud Alert: 3+ UPI transactions in the last hour. Transaction paused for your safety.',
        actionRequired: 'security_review',
      );
    }

    return ComplianceResult.clear;
  }

  static ComplianceResult evaluateKYCStatus(UserProfile profile) {
    if (profile.kycStep == 'none' || profile.kycStep == 'pan') {
      return ComplianceResult(
        risk: ComplianceRisk.high,
        shouldBlock: false,
        message: 'KYC incomplete at step: ${profile.kycStep}. Complete verification to unlock full banking.',
        actionRequired: 'resume_kyc',
      );
    }
    if (!profile.kycComplete) {
      return const ComplianceResult(
        risk: ComplianceRisk.medium,
        shouldBlock: false,
        message: 'Almost there! Complete remaining KYC steps to activate all features.',
        actionRequired: 'resume_kyc',
      );
    }
    return ComplianceResult.clear;
  }

  static String getStatusText(ComplianceRisk risk) {
    switch (risk) {
      case ComplianceRisk.none:
        return 'All systems secure';
      case ComplianceRisk.low:
        return 'Low risk — monitoring';
      case ComplianceRisk.medium:
        return 'Review recommended';
      case ComplianceRisk.high:
        return 'High risk detected!';
      case ComplianceRisk.critical:
        return '🛡️ Transaction blocked';
    }
  }
}
