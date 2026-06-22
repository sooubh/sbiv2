import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/ai/engine/pattern_engine.dart';
import 'package:sbiv2/ai/behavior/next_best_action.dart';
import 'package:sbiv2/ai/behavior/retention_rules.dart';

class ProactiveAgentEngine {
  /// Evaluates all conditions and returns the single highest priority NextBestAction
  /// that is not currently on cooldown.
  static NextBestAction determineNextBestAction({
    required UserProfile profile,
    required List<Transaction> transactions,
    required List<Goal> goals,
    required AgentMemory memory,
    required List<Recommendation> recommendations,
  }) {
    // 1. Run pattern analysis
    final signals = PatternEngine.analyze(profile, transactions);
    final cooldownMap = memory.suggestionCooldownMap;

    // Check actions in strict priority order:

    // 1. KYC Completion (Priority 1)
    if (!profile.kycComplete && profile.name == 'Rohan') {
      final key = NextBestActionType.kyc.name;
      if (!RetentionRules.isCoolingDown(key, cooldownMap)) {
        return NextBestAction(
          id: 'nba_kyc',
          title: 'Complete KYC Onboarding',
          subtitle: 'Verify PAN, Aadhaar and Video KYC to activate full banking.',
          aiReason: 'Incomplete KYC detected for new profile Rohan.',
          actionText: 'Finish KYC Now',
          type: NextBestActionType.kyc,
          priority: 1,
          payload: {'kycStep': profile.kycStep},
        );
      }
    }

    // 2. Resume Missed SIP (Priority 2)
    final missedSipActive = signals.missedRecurring || 
        recommendations.any((r) => r.id == 'rec_02' && !r.isCompleted);
    if (missedSipActive) {
      final key = NextBestActionType.sip.name;
      if (!RetentionRules.isCoolingDown(key, cooldownMap)) {
        return const NextBestAction(
          id: 'nba_sip',
          title: 'Resume Missed SIP',
          subtitle: 'Missed your regular ₹5,000 SBI Mutual Fund SIP this month.',
          aiReason: 'PatternEngine detected a mutual fund SIP in May but none in June.',
          actionText: 'Resume SIP with 1 Click',
          type: NextBestActionType.sip,
          priority: 2,
          payload: {'sipAmount': 5000.0, 'fundName': 'SBI Bluechip Fund'},
        );
      }
    }

    // 3. Fix Low Balance Warning (Priority 3)
    final lowBalanceActive = signals.lowBalance || profile.balance < 1000;
    if (lowBalanceActive) {
      final key = NextBestActionType.lowBalance.name;
      if (!RetentionRules.isCoolingDown(key, cooldownMap)) {
        return NextBestAction(
          id: 'nba_low_balance',
          title: 'Low Balance Buffer Alert',
          subtitle: 'Your balance is currently ₹${profile.balance.toStringAsFixed(0)}. Avoid heavy debits.',
          aiReason: 'Account balance dropped below the ₹1,000 safe buffer limit.',
          actionText: 'Load Funds via UPI',
          type: NextBestActionType.lowBalance,
          priority: 3,
          payload: {'balance': profile.balance},
        );
      }
    }

    // 4. Move Idle Cash to FD (Priority 4)
    final idleBalanceActive = signals.idleBalance ||
        recommendations.any((r) => r.id == 'rec_01' && !r.isCompleted);
    if (idleBalanceActive && profile.balance >= 50000) {
      final key = NextBestActionType.fd.name;
      if (!RetentionRules.isCoolingDown(key, cooldownMap)) {
        return const NextBestAction(
          id: 'nba_fd',
          title: 'Optimize Idle Balance',
          subtitle: 'Earn 7.25% p.a. secure returns by moving ₹50,000 to SBI FD.',
          aiReason: 'Idle savings balance exceeds ₹1,20,000 with no investment allocations.',
          actionText: 'Open Fixed Deposit',
          type: NextBestActionType.fd,
          priority: 4,
          payload: {'amount': 50000.0},
        );
      }
    }

    // 5. Salary Save / Auto-save (Priority 5)
    final salaryNoSaveActive = signals.salaryNoSave || 
        recommendations.any((r) => r.id == 'rec_salary_no_save' && !r.isCompleted);
    if (salaryNoSaveActive) {
      final key = NextBestActionType.salarySave.name;
      if (!RetentionRules.isCoolingDown(key, cooldownMap)) {
        return const NextBestAction(
          id: 'nba_salary_save',
          title: 'Salary Credit Savings Alert',
          subtitle: 'Salary credited recently. Allocate ₹15,000 to your savings goal.',
          aiReason: 'Salary credited but no goals or Mutual Fund SIP allocations made in last 7 days.',
          actionText: 'Boost Goal Savings',
          type: NextBestActionType.salarySave,
          priority: 5,
          payload: {'salaryAmount': 75000.0, 'saveSuggestion': 15000.0},
        );
      }
    }

    // 6. Spending Spike (Priority 6)
    final spendingSpikeActive = signals.spendingSpike ||
        recommendations.any((r) => r.id == 'rec_spending_spike' && !r.isCompleted);
    if (spendingSpikeActive) {
      final key = NextBestActionType.spendingSpike.name;
      if (!RetentionRules.isCoolingDown(key, cooldownMap)) {
        return const NextBestAction(
          id: 'nba_spending_spike',
          title: 'Food Budget Spike Warning',
          subtitle: 'You spent ₹25,000 on Zomato food delivery this month.',
          aiReason: 'Zomato food expenditure is 10x higher than normal average.',
          actionText: 'Review Budget Limit',
          type: NextBestActionType.spendingSpike,
          priority: 6,
          payload: {'category': 'Food', 'amount': 25000.0},
        );
      }
    }

    // 7. Goal Progress Nudge (Priority 7)
    if (goals.isNotEmpty) {
      final key = NextBestActionType.goalNudge.name;
      if (!RetentionRules.isCoolingDown(key, cooldownMap)) {
        final primaryGoal = goals.first;
        final remaining = primaryGoal.targetAmount - primaryGoal.savedAmount;
        if (remaining > 0) {
          return NextBestAction(
            id: 'nba_goal_nudge',
            title: 'Boost "${primaryGoal.name}" Goal',
            subtitle: 'You are ₹${remaining.toStringAsFixed(0)} away from target. Boost by ₹1,000 now.',
            aiReason: 'Active goal nudge to maintain regular savings momentum.',
            actionText: 'Add ₹1,000 Now',
            type: NextBestActionType.goalNudge,
            priority: 7,
            payload: {'goalId': primaryGoal.id, 'nudgeAmount': 1000.0},
          );
        }
      }
    }

    // 8. General Financial Health Fallback (Priority 8)
    return NextBestAction(
      id: 'nba_health_summary',
      title: 'Check Financial Health Score',
      subtitle: 'Your health score is ${profile.healthScore}/100. View optimization tips.',
      aiReason: 'Advisory fallback when no critical financial alerts are active.',
      actionText: 'Check Insights',
      type: NextBestActionType.healthSummary,
      priority: 8,
      payload: {'healthScore': profile.healthScore},
    );
  }
}
