import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/ai/behavior/next_best_action.dart';
import 'package:sbiv2/ai/agent/advisor_agent.dart';
import 'package:sbiv2/ai/agent/transaction_agent.dart';
import 'package:sbiv2/ai/agent/compliance_agent.dart';

enum ActiveAgent { advisor, transaction, compliance, none }

class OrchestratorDecision {
  final ActiveAgent agent;
  final String agentDisplayName;
  final String agentEmoji;
  final String? transactionToolName;
  final TransactionIntent? transactionIntent;
  final ComplianceResult? complianceResult;
  final NextBestAction? advisoryAction;
  final String routingReason;

  const OrchestratorDecision({
    required this.agent,
    required this.agentDisplayName,
    required this.agentEmoji,
    required this.routingReason,
    this.transactionToolName,
    this.transactionIntent,
    this.complianceResult,
    this.advisoryAction,
  });
}

class AgentOrchestrator {
  static OrchestratorDecision route({
    required String message,
    required UserProfile profile,
    required List<Transaction> transactions,
    required List<Goal> goals,
    required AgentMemory memory,
    required List<Recommendation> recommendations,
  }) {
    // Priority 1: Compliance keywords always checked first
    if (ComplianceAgent.canHandle(message)) {
      final kycResult = ComplianceAgent.evaluateKYCStatus(profile);
      return OrchestratorDecision(
        agent: ActiveAgent.compliance,
        agentDisplayName: ComplianceAgent.displayName,
        agentEmoji: ComplianceAgent.emoji,
        routingReason: 'Compliance/KYC keyword detected.',
        complianceResult: kycResult,
      );
    }

    // Priority 2: Transaction operations
    if (TransactionAgent.canHandle(message)) {
      final intent = TransactionAgent.parseIntent(message);
      if (intent != null) {
        final complianceResult = ComplianceAgent.evaluateTransaction(
          profile: profile,
          transactions: transactions,
          amount: intent.amount ?? 0.0,
          transactionType: intent.domain == TransactionDomain.upiPay ? 'upi' : 'transfer',
        );
        if (complianceResult.shouldBlock) {
          return OrchestratorDecision(
            agent: ActiveAgent.compliance,
            agentDisplayName: ComplianceAgent.displayName,
            agentEmoji: ComplianceAgent.emoji,
            routingReason: 'Transaction blocked by compliance rules.',
            complianceResult: complianceResult,
          );
        }
        return OrchestratorDecision(
          agent: ActiveAgent.transaction,
          agentDisplayName: TransactionAgent.displayName,
          agentEmoji: TransactionAgent.emoji,
          routingReason: 'Transaction keyword: ${intent.domain.name}.',
          transactionIntent: intent,
          transactionToolName: TransactionAgent.getToolName(intent.domain),
          complianceResult: complianceResult,
        );
      }
    }

    // Priority 3: Financial advisory
    if (AdvisorAgent.canHandle(message)) {
      final action = AdvisorAgent.evaluate(
        profile: profile,
        transactions: transactions,
        goals: goals,
        memory: memory,
        recommendations: recommendations,
      );
      return OrchestratorDecision(
        agent: ActiveAgent.advisor,
        agentDisplayName: AdvisorAgent.displayName,
        agentEmoji: AdvisorAgent.emoji,
        routingReason: 'Financial advisory keyword detected.',
        advisoryAction: action,
      );
    }

    // Fallback: Advisor
    final fallbackAction = AdvisorAgent.evaluate(
      profile: profile,
      transactions: transactions,
      goals: goals,
      memory: memory,
      recommendations: recommendations,
    );
    return OrchestratorDecision(
      agent: ActiveAgent.advisor,
      agentDisplayName: AdvisorAgent.displayName,
      agentEmoji: AdvisorAgent.emoji,
      routingReason: 'No specific domain matched — defaulting to Advisor.',
      advisoryAction: fallbackAction,
    );
  }
}
