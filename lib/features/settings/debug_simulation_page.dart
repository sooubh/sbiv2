import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/ai/events/agent_event.dart';
import 'package:sbiv2/features/agent/models/timeline_entry.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/ai/voice/voice_service.dart';
import 'package:sbiv2/ai/voice/voice_state.dart';
import 'package:sbiv2/features/navigation/bottom_nav_shell.dart';

class DebugSimulationPage extends ConsumerWidget {
  const DebugSimulationPage({super.key});

  // Action 1: Fire Salary Credit
  void _fireSalaryCredit(WidgetRef ref) {
    final now = DateTime.now();
    final tx = Transaction(
      id: 'sim_salary_${now.millisecondsSinceEpoch}',
      amount: 75000.0,
      payee: 'TCS Salary Credit',
      category: 'Salary',
      date: now,
      type: 'credit',
    );

    // 1. Add salary transaction
    ref.read(transactionsProvider.notifier).addTransaction(tx);
    
    // 2. Increase balance
    ref.read(userProfileProvider.notifier).updateBalance(75000.0);
    
    // 3. Add recommendation
    final rec = Recommendation(
      id: 'rec_salary_no_save',
      title: 'Salary Credited! Save Now',
      subtitle: 'Allocate ₹15,000 to emergency fund or SIP',
      aiReason: 'Detected salary credit of ₹75,000 but no savings/investments have been made.',
      priority: 1,
      isCompleted: false,
    );
    ref.read(recommendationsProvider.notifier).addRecommendation(rec);
    
    // 4. Emit event
    ref.read(agentEventProvider.notifier).emit(
      AgentEventType.toolCompleted,
      "Simulated Event: Salary Credited",
      metadata: {'payee': tx.payee, 'amount': tx.amount},
    );

    // 5. Log signal detected to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.signalDetected,
      title: 'Signal: salaryNoSave',
      description: 'Salary credited, no savings/investments allocated yet.',
      status: TimelineEntryStatus.info,
    );

    // 6. Log recommendation generated to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.recommendation,
      title: 'Recommendation Generated',
      description: 'Salary Credited! Save Now - Allocate ₹15,000 to emergency fund or SIP',
      status: TimelineEntryStatus.success,
    );

    // 7. Update agent memory
    final memory = ref.read(agentMemoryProvider);
    ref.read(agentMemoryProvider.notifier).updateMemory(memory.copyWith(
      lastDetectedSignal: SignalSummary(key: 'salary_no_save', title: 'Salary Credited, No Savings', timestamp: now),
      lastRecommendedAction: 'Salary Credited! Save Now',
    ));

    // 8. Speak and show agent response
    ref.read(aiCoordinatorProvider.notifier).simulateAgentResponse(
      "Namaste! TCS Salary of ₹75,000 has been credited. I noticed you haven't allocated any savings from it. Would you like to allocate ₹15,000 to save towards your Dream Car goal?"
    );
  }

  // Action 2: Trigger Missed SIP
  void _triggerMissedSIP(WidgetRef ref) {
    // 1. Remove current month SIP transactions
    ref.read(transactionsProvider.notifier).removeSIPTransactions();

    // 2. Reset recommendation isCompleted to false
    final rec = Recommendation(
      id: 'rec_02',
      title: 'Resume SBI Bluechip SIP',
      subtitle: 'Missed SIP in June. Resume now with 1 click.',
      aiReason: 'PatternEngine detected mutual fund SIP debit in May but none in June.',
      priority: 0,
      isCompleted: false,
    );
    ref.read(recommendationsProvider.notifier).addRecommendation(rec);

    // 3. Emit event
    ref.read(agentEventProvider.notifier).emit(
      AgentEventType.toolCompleted,
      "Simulated Event: Missed Mutual Fund SIP Detected",
    );

    // 4. Log signal detected to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.signalDetected,
      title: 'Signal: missedRecurring',
      description: 'Missed Mutual Fund SIP in the current month.',
      status: TimelineEntryStatus.info,
    );

    // 5. Update agent memory
    final memory = ref.read(agentMemoryProvider);
    ref.read(agentMemoryProvider.notifier).updateMemory(memory.copyWith(
      lastDetectedSignal: SignalSummary(key: 'missed_recurring', title: 'Missed Mutual Fund SIP', timestamp: DateTime.now()),
      lastRecommendedAction: 'Resume SBI Bluechip SIP',
    ));

    // 6. Speak and show agent response
    ref.read(aiCoordinatorProvider.notifier).simulateAgentResponse(
      "Attention: I noticed your regular SBI Bluechip Mutual Fund SIP of ₹5,000 was missed this month. Shall I resume it for you?"
    );
  }

  // Action 3: Add Idle Balance
  void _addIdleBalance(WidgetRef ref) {
    final now = DateTime.now();

    // 1. Increase balance by 50,000
    ref.read(userProfileProvider.notifier).updateBalance(50000.0);

    // 2. Reset FD recommendation
    final rec = Recommendation(
      id: 'rec_01',
      title: 'Start a Tax Saving FD',
      subtitle: 'Earn 7.25% p.a. & save tax under 80C',
      aiReason: 'Detected idle balance of over ₹1,20,000 in savings account. Moving it to FD yields higher interest.',
      priority: 1,
      isCompleted: false,
    );
    ref.read(recommendationsProvider.notifier).addRecommendation(rec);

    // 3. Emit event
    ref.read(agentEventProvider.notifier).emit(
      AgentEventType.toolCompleted,
      "Simulated Event: Idle Balance Detected",
    );

    // 4. Log signal detected to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.signalDetected,
      title: 'Signal: idleBalance',
      description: 'Large idle savings balance detected.',
      status: TimelineEntryStatus.info,
    );

    // 5. Update agent memory
    final memory = ref.read(agentMemoryProvider);
    ref.read(agentMemoryProvider.notifier).updateMemory(memory.copyWith(
      lastDetectedSignal: SignalSummary(key: 'idle_balance', title: 'Large Idle Savings Balance', timestamp: now),
      lastRecommendedAction: 'Start a Tax Saving FD',
    ));

    // 6. Speak and show agent response
    final currentBalance = ref.read(userProfileProvider).balance;
    ref.read(aiCoordinatorProvider.notifier).simulateAgentResponse(
      "Aapke savings account mein ₹${currentBalance.toStringAsFixed(0)} idle balance hai. Aap ise high-yield Fixed Deposit account mein transfer karke 7.25% interest earn kar sakte hain. Kya main process karu?"
    );
  }

  // Action 4: Low Balance Mode
  void _triggerLowBalance(WidgetRef ref) {
    // 1. Set balance to 500
    ref.read(userProfileProvider.notifier).setBalance(500.0);

    // 2. Emit event
    ref.read(agentEventProvider.notifier).emit(
      AgentEventType.toolFailed,
      "Simulated Event: Low Account Balance Warning",
    );

    // 3. Log signal detected to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.signalDetected,
      title: 'Signal: lowBalance',
      description: 'Low account balance of ₹500 which is below safe buffer levels.',
      status: TimelineEntryStatus.info,
    );

    // 4. Update agent memory
    final memory = ref.read(agentMemoryProvider);
    ref.read(agentMemoryProvider.notifier).updateMemory(memory.copyWith(
      lastDetectedSignal: SignalSummary(key: 'low_balance', title: 'Low Account Balance', timestamp: DateTime.now()),
      lastRecommendedAction: 'Load Funds via UPI',
    ));

    // 5. Speak and show agent response
    ref.read(aiCoordinatorProvider.notifier).simulateAgentResponse(
      "Warning: Aapka account balance alert limit se kam (₹500) ho gaya hai. Emergency funds use karein ya balance load karein."
    );
  }

  // Action 5: Spending Spike
  void _triggerSpendingSpike(WidgetRef ref) {
    final now = DateTime.now();
    final tx = Transaction(
      id: 'sim_spike_${now.millisecondsSinceEpoch}',
      amount: 25000.0,
      payee: 'Spike Zomato Party',
      category: 'Food',
      date: now,
      type: 'debit',
    );

    // 1. Add large food expense
    ref.read(transactionsProvider.notifier).addTransaction(tx);

    // 2. Deduct balance
    ref.read(userProfileProvider.notifier).updateBalance(-25000.0);

    // 3. Add recommendation/insight
    final rec = Recommendation(
      id: 'rec_spending_spike',
      title: 'Food Budget Spike Alert',
      subtitle: 'Spent ₹25,000 on Food compared to ₹2,500 average',
      aiReason: 'PatternEngine detected a food expense spike that is 10x higher than normal.',
      priority: 2,
      isCompleted: false,
    );
    ref.read(recommendationsProvider.notifier).addRecommendation(rec);

    // 4. Emit event
    ref.read(agentEventProvider.notifier).emit(
      AgentEventType.toolCompleted,
      "Simulated Event: Spending Spike in Food Category",
      metadata: {'payee': tx.payee, 'amount': tx.amount},
    );

    // 5. Log signal detected to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.signalDetected,
      title: 'Signal: spendingSpike (Food)',
      description: 'Spike in Food spending comparison to last month.',
      status: TimelineEntryStatus.info,
    );

    // 6. Update agent memory
    final memory = ref.read(agentMemoryProvider);
    ref.read(agentMemoryProvider.notifier).updateMemory(memory.copyWith(
      lastDetectedSignal: SignalSummary(key: 'spending_spike', title: 'Spending Spike Detected', timestamp: now),
      lastRecommendedAction: 'Food Budget Spike Alert',
    ));

    // 7. Speak and show agent response
    ref.read(aiCoordinatorProvider.notifier).simulateAgentResponse(
      "Alert: Food category mein large spend spike detected! You spent ₹25,000 on Zomato, which is 10 times your monthly average. Maintain budget controls to stay on track."
    );
  }

  // Action 6: Complete KYC
  void _completeKYC(WidgetRef ref, BuildContext context) {
    // 1. Force onboarding completion in user profile
    ref.read(userProfileProvider.notifier).updateProfile(
      ref.read(userProfileProvider).copyWith(
        kycComplete: true,
        kycStep: 'complete',
        upiEnabled: true,
      ),
    );

    // 2. Force onboarding completion in agent memory
    ref.read(agentMemoryProvider.notifier).setKYCCompleted();

    // 3. Force agent state mode to banking
    ref.read(agentStateProvider.notifier).setMode(AgentMode.banking);

    // 4. Emit event
    ref.read(agentEventProvider.notifier).emit(
      AgentEventType.toolCompleted,
      "Simulated Event: Onboarding KYC completed",
    );

    // 5. Log to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.onboarding,
      title: 'KYC & Onboarding Completed',
      description: 'All KYC verification documents processed and verified.',
      status: TimelineEntryStatus.success,
    );

    // 6. Speak and show agent response
    ref.read(aiCoordinatorProvider.notifier).simulateAgentResponse(
      "Onboarding aur KYC complete ho gaya hai! YONO SBI 2.0 Banking assistant active hai. Main aapke investments and savings analyze karne ke liye ready hun."
    );

    // Redirect to banking shell
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BottomNavShell()),
      (route) => false,
    );
  }

  // Action 7: Activate UPI
  void _activateUPI(WidgetRef ref, BuildContext context) {
    // 1. Force UPI activation
    ref.read(userProfileProvider.notifier).enableUPI(true);
    ref.read(userProfileProvider.notifier).updateKYCStep('complete');
    ref.read(agentStateProvider.notifier).setMode(AgentMode.banking);
    ref.read(agentMemoryProvider.notifier).setKYCCompleted();

    // 2. Emit event
    ref.read(agentEventProvider.notifier).emit(
      AgentEventType.toolCompleted,
      "Simulated Event: UPI Service Activated",
    );

    // 3. Log to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.onboarding,
      title: 'UPI Services Activated',
      description: 'UPI VPA linked and quick pay enabled.',
      status: TimelineEntryStatus.success,
    );

    // 4. Speak and show agent response
    ref.read(aiCoordinatorProvider.notifier).simulateAgentResponse(
      "Congratulations! Aapka VPA rohan@sbi activate ho gaya hai. Aap kisi bhi UPI transaction ke liye use kar sakte hain."
    );

    // Redirect to banking shell
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BottomNavShell()),
      (route) => false,
    );
  }

  // Action 8: Create Goal
  void _createGoal(WidgetRef ref) {
    final now = DateTime.now();
    final goal = Goal(
      id: 'goal_sim_${now.millisecondsSinceEpoch}',
      name: 'Shimla Vacation',
      targetAmount: 50000.0,
      savedAmount: 0.0,
      deadline: now.add(const Duration(days: 90)),
    );

    // 1. Create a sample goal
    ref.read(goalsProvider.notifier).addGoal(goal);

    // 2. Emit event
    ref.read(agentEventProvider.notifier).emit(
      AgentEventType.toolCompleted,
      "Simulated Event: Goal Created via AI Advisor",
      metadata: {'name': goal.name, 'target': goal.targetAmount},
    );

    // 3. Log to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.toolCompleted,
      title: 'Created Goal: ${goal.name}',
      description: 'Target amount: ₹${goal.targetAmount.toStringAsFixed(0)}',
      status: TimelineEntryStatus.success,
    );

    // 4. Speak and show agent response
    ref.read(aiCoordinatorProvider.notifier).simulateAgentResponse(
      "Excellent! Maine aapka naya savings goal 'Shimla Vacation' target ₹50,000 create kar diya hai. I will help you track and save for it."
    );
  }

  // Action 9: Reset Demo State
  void _resetDemo(WidgetRef ref, BuildContext context) {
    // 1. Reset all state notifiers
    ref.read(userProfileProvider.notifier).reset();
    ref.read(transactionsProvider.notifier).reset();
    ref.read(goalsProvider.notifier).reset();
    ref.read(recommendationsProvider.notifier).reset();
    ref.read(servicesProvider.notifier).reset();
    ref.read(engagementProvider.notifier).reset();
    ref.read(onboardingChatProvider.notifier).reset();
    ref.read(bankingChatProvider.notifier).reset();
    ref.read(agentMemoryProvider.notifier).reset();
    ref.read(timelineProvider.notifier).clear();
    ref.read(agentEventProvider.notifier).clear();
    ref.read(agentStateProvider.notifier).reset();
    ref.read(voiceStateProvider.notifier).clearError();
    ref.read(voiceServiceProvider).stopSpeaking();

    // 2. Clear API coordinator error / re-initialize
    ref.read(aiCoordinatorProvider.notifier).updateApiKey(ref.read(geminiApiKeyProvider));

    // 3. Speak and show agent response
    ref.read(aiCoordinatorProvider.notifier).simulateAgentResponse(
      "Demo environment has been completely reset to default state."
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo states and timeline reset successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Debug Simulation Panel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetDemo(ref, context),
            tooltip: 'Reset Demo State',
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner explanation
          Card(
            color: AppTheme.primaryLight,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.primary, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Demo Simulation Tool',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trigger instant financial events to demonstrate the proactive agent reactions, recommendations, timeline logging, and voice capability for hackathon judges.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Telemetry / Debug Diagnostics Card
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Row(
                  children: [
                    const Icon(Icons.settings_suggest, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Diagnostics & Telemetry',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Builder(
                      builder: (context) {
                        final agentState = ref.watch(agentStateProvider);
                        final voiceState = ref.watch(voiceStateProvider);
                        final memory = ref.watch(agentMemoryProvider);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 16),
                            _buildTelemetryRow('Connection ID', (agentState.sessionId == null || agentState.sessionId!.isEmpty) ? 'None' : agentState.sessionId!),
                            _buildTelemetryRow('Connection Status', agentState.connectionStatus.toUpperCase()),
                            _buildTelemetryRow('Transport Type', agentState.transportType.toUpperCase()),
                            _buildTelemetryRow('WebSocket Status', agentState.webSocketStatus.toUpperCase()),
                            _buildTelemetryRow('REST Status', agentState.restStatus.toUpperCase()),
                            _buildTelemetryRow('Decision Source', agentState.decisionSource),
                            _buildTelemetryRow('Agent Mode', agentState.mode.name.toUpperCase()),
                            _buildTelemetryRow('Agent State', agentState.status.name.toUpperCase()),
                            _buildTelemetryRow('Voice Engine Status', voiceState.status.name.toUpperCase()),
                            _buildTelemetryRow('Last Tool Called', agentState.lastToolName ?? 'None'),
                            _buildTelemetryRow('Last Warning', agentState.lastWarning ?? 'None'),
                            _buildTelemetryRow('Last Error Message', agentState.lastError ?? 'None'),
                            const SizedBox(height: 12),
                            Text(
                              'Memory Summary:',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '• Primary Goal: ${memory.primaryGoal}\n'
                                '• Risk Level: ${memory.riskLevel}\n'
                                '• Preferences: ${memory.userPreferenceSummary}',
                                style: AppTheme.monoStyle(fontSize: 10, color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Simulation options title
          Text(
            'AVAILABLE DEMO TRIGGERS',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // 1. Fire Salary Credit
          _buildSimCard(
            title: '1. Fire Salary Credit',
            description: 'Adds a credit of ₹75,000, updates balance, triggers salary savings alert and speaks recommendation.',
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.green,
            onPressed: () => _fireSalaryCredit(ref),
          ),

          // 2. Missed SIP
          _buildSimCard(
            title: '2. Missed SIP Alert',
            description: 'Removes the current month SIP transaction, triggers missed mutual fund SIP detection, and prompts agent to speak.',
            icon: Icons.trending_down_outlined,
            color: Colors.amber[800]!,
            onPressed: () => _triggerMissedSIP(ref),
          ),

          // 3. Add Idle Balance
          _buildSimCard(
            title: '3. Add Idle Balance',
            description: 'Increases savings balance by ₹50,000, triggers Fixed Deposit recommendation, and speaks advice.',
            icon: Icons.savings_outlined,
            color: AppTheme.aiTeal,
            onPressed: () => _addIdleBalance(ref),
          ),

          // 4. Low Balance Mode
          _buildSimCard(
            title: '4. Low Balance Warning',
            description: 'Forces savings balance to ₹500, logs signal and triggers agent critical warning voice alert.',
            icon: Icons.warning_amber_rounded,
            color: AppTheme.accentOrange,
            onPressed: () => _triggerLowBalance(ref),
          ),

          // 5. Spending Spike
          _buildSimCard(
            title: '5. Spending Spike (Food)',
            description: 'Adds a large ₹25,000 transaction in food category, logs anomaly signal, and speaks budget spike warning.',
            icon: Icons.restaurant_outlined,
            color: Colors.purple,
            onPressed: () => _triggerSpendingSpike(ref),
          ),

          // 6. Complete KYC
          _buildSimCard(
            title: '6. Complete Onboarding KYC',
            description: 'Simulates video KYC success, marks Rohan onboarding complete, and transitions agent mode to banking.',
            icon: Icons.assignment_turned_in_outlined,
            color: Colors.blue,
            onPressed: () => _completeKYC(ref, context),
          ),

          // 7. Activate UPI
          _buildSimCard(
            title: '7. Force Activate UPI',
            description: 'Activates UPI services for Rohan, registers virtual address rohan@sbi, and triggers success prompt.',
            icon: Icons.qr_code_scanner_outlined,
            color: Colors.teal,
            onPressed: () => _activateUPI(ref, context),
          ),

          // 8. Create Savings Goal
          _buildSimCard(
            title: '8. Create "Shimla Vacation" Goal',
            description: 'Creates a new savings goal with target ₹50,000, triggers goal logging and agent validation voice response.',
            icon: Icons.flag_outlined,
            color: Colors.orange,
            onPressed: () => _createGoal(ref),
          ),

          const SizedBox(height: 16),
          // 9. Reset Button at the bottom
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.refresh),
            label: Text('9. Reset Demo to Default State', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            onPressed: () => _resetDemo(ref, context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSimCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: onPressed,
                      child: Text(
                        'Trigger Simulation',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: AppTheme.monoStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
