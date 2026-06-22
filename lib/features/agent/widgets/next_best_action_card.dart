import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/ai/behavior/next_best_action.dart';
import 'package:sbiv2/ai/behavior/proactive_agent_engine.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/features/agent/models/timeline_entry.dart';

class NextBestActionCard extends ConsumerWidget {
  final Function(int)? onNavigate;

  const NextBestActionCard({super.key, this.onNavigate});

  void _handleAction(BuildContext context, WidgetRef ref, NextBestAction action) {
    // Log acceptance to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.toolCompleted,
      title: 'Action Accepted: ${action.title}',
      description: 'User clicked the primary action button to resolve suggestion.',
      status: TimelineEntryStatus.success,
    );

    // Track last action completed in memory
    final memoryNotifier = ref.read(agentMemoryProvider.notifier);
    memoryNotifier.updateProactiveState(
      lastActionCompleted: action.id,
    );

    // Apply suggestion cooldown immediately after acceptance so it goes away
    memoryNotifier.updateCooldown(action.type.name, DateTime.now().millisecondsSinceEpoch);

    // Process action based on type
    switch (action.type) {
      case NextBestActionType.kyc:
        if (onNavigate != null) {
          onNavigate!(1); // Go to Onboarding (KYC App) screen
        }
        break;
      case NextBestActionType.sip:
        ref.read(aiCoordinatorProvider.notifier).sendMessage("Resume SIP");
        if (onNavigate != null) {
          onNavigate!(4); // Go to Chat screen to watch tool execution
        }
        break;
      case NextBestActionType.lowBalance:
        ref.read(aiCoordinatorProvider.notifier).sendMessage("Check Balance");
        if (onNavigate != null) {
          onNavigate!(4); // Go to Chat screen
        }
        break;
      case NextBestActionType.fd:
        ref.read(aiCoordinatorProvider.notifier).sendMessage("Open FD");
        if (onNavigate != null) {
          onNavigate!(4); // Go to Chat screen
        }
        break;
      case NextBestActionType.salarySave:
        ref.read(aiCoordinatorProvider.notifier).sendMessage("Boost Goal");
        if (onNavigate != null) {
          onNavigate!(4); // Go to Chat screen
        }
        break;
      case NextBestActionType.spendingSpike:
        ref.read(aiCoordinatorProvider.notifier).sendMessage("Review spending spike");
        if (onNavigate != null) {
          onNavigate!(4); // Go to Chat screen
        }
        break;
      case NextBestActionType.goalNudge:
        ref.read(aiCoordinatorProvider.notifier).sendMessage("Boost goal");
        if (onNavigate != null) {
          onNavigate!(4); // Go to Chat screen
        }
        break;
      case NextBestActionType.healthSummary:
        if (onNavigate != null) {
          onNavigate!(3); // Go to Engagement / insights screen
        }
        break;
    }
  }

  void _handleSnooze(BuildContext context, WidgetRef ref, NextBestAction action) {
    // 1. Put this suggestion category on cooldown
    ref.read(agentMemoryProvider.notifier).updateCooldown(
      action.type.name,
      DateTime.now().millisecondsSinceEpoch,
    );

    // 2. Log suppression to timeline
    ref.read(timelineProvider.notifier).log(
      type: TimelineEntryType.signalDetected,
      title: 'Action Snoozed: ${action.title}',
      description: 'Suggestion suppressed. Entering 30-second cooldown.',
      status: TimelineEntryStatus.info,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${action.title}" snoozed. Displaying next best priority.'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final txs = ref.watch(transactionsProvider);
    final goals = ref.watch(goalsProvider);
    final recs = ref.watch(recommendationsProvider);
    final memory = ref.watch(agentMemoryProvider);

    // Compute the absolute Next Best Action dynamically
    final action = ProactiveAgentEngine.determineNextBestAction(
      profile: profile,
      transactions: txs,
      goals: goals,
      memory: memory,
      recommendations: recs,
    );

    // Action color theme based on priority / status
    Color cardColor = AppTheme.primary;
    IconData actionIcon = Icons.star_border;

    switch (action.type) {
      case NextBestActionType.kyc:
      case NextBestActionType.lowBalance:
        cardColor = AppTheme.accentOrange;
        actionIcon = Icons.warning_amber_rounded;
        break;
      case NextBestActionType.sip:
      case NextBestActionType.spendingSpike:
        cardColor = Colors.purple[600]!;
        actionIcon = Icons.trending_down_outlined;
        break;
      case NextBestActionType.fd:
      case NextBestActionType.salarySave:
        cardColor = AppTheme.aiTeal;
        actionIcon = Icons.insights_outlined;
        break;
      case NextBestActionType.goalNudge:
        cardColor = Colors.indigo;
        actionIcon = Icons.flag_outlined;
        break;
      case NextBestActionType.healthSummary:
        cardColor = AppTheme.primary;
        actionIcon = Icons.insights;
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor,
            cardColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Stack(
        children: [
          // Snooze/Close Button
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _handleSnooze(context, ref, action),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(actionIcon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI Next Best Action',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Priority #${action.priority}',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  action.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: cardColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () => _handleAction(context, ref, action),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action.actionText,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: cardColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
