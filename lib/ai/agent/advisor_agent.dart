import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/ai/behavior/proactive_agent_engine.dart';
import 'package:sbiv2/ai/behavior/next_best_action.dart';

class AdvisorAgent {
  static const String agentId = 'advisor_agent';
  static const String displayName = 'Financial Advisor';
  static const String emoji = '📊';

  static NextBestAction evaluate({
    required UserProfile profile,
    required List<Transaction> transactions,
    required List<Goal> goals,
    required AgentMemory memory,
    required List<Recommendation> recommendations,
  }) {
    return ProactiveAgentEngine.determineNextBestAction(
      profile: profile,
      transactions: transactions,
      goals: goals,
      memory: memory,
      recommendations: recommendations,
    );
  }

  static bool canHandle(String message) {
    final m = message.toLowerCase();
    return m.contains('sip') ||
        m.contains('mutual fund') ||
        m.contains('fd') ||
        m.contains('fixed deposit') ||
        m.contains('investment') ||
        m.contains('health score') ||
        m.contains('savings') ||
        m.contains('goal') ||
        m.contains('salary') ||
        m.contains('advice') ||
        m.contains('suggest') ||
        m.contains('portfolio');
  }

  static String getStatusText(NextBestAction action) {
    switch (action.type) {
      case NextBestActionType.sip:
        return 'Watching your SIP schedule';
      case NextBestActionType.fd:
        return 'Optimizing idle balance to FD';
      case NextBestActionType.goalNudge:
        return 'Tracking your savings goals';
      case NextBestActionType.salarySave:
        return 'Salary allocation advisory active';
      case NextBestActionType.healthSummary:
        return 'Financial health: monitoring';
      default:
        return 'Financial advisory active';
    }
  }
}
