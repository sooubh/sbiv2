import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/behavior/proactive_agent_engine.dart';
import 'package:sbiv2/ai/behavior/next_best_action.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';

/// A compact, non-intrusive AI insight strip.
/// Appears as a thin notification-style banner between the balance card and quick actions.
class NextBestActionCard extends ConsumerStatefulWidget {
  const NextBestActionCard({super.key});

  @override
  ConsumerState<NextBestActionCard> createState() => _NextBestActionCardState();
}

class _NextBestActionCardState extends ConsumerState<NextBestActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _actionColor(NextBestActionType type) {
    switch (type) {
      case NextBestActionType.kyc:
        return AppTheme.accentOrange;
      case NextBestActionType.sip:
        return AppTheme.aiTeal;
      case NextBestActionType.fd:
        return AppTheme.accentGreen;
      case NextBestActionType.lowBalance:
        return const Color(0xFFEF4444);
      case NextBestActionType.goalNudge:
        return AppTheme.primary;
      default:
        return AppTheme.primary;
    }
  }

  IconData _actionIcon(NextBestActionType type) {
    switch (type) {
      case NextBestActionType.kyc:
        return Icons.verified_user_outlined;
      case NextBestActionType.sip:
        return Icons.trending_up;
      case NextBestActionType.fd:
        return Icons.savings_outlined;
      case NextBestActionType.lowBalance:
        return Icons.warning_amber_rounded;
      case NextBestActionType.goalNudge:
        return Icons.flag_outlined;
      case NextBestActionType.salarySave:
        return Icons.account_balance_wallet_outlined;
      case NextBestActionType.spendingSpike:
        return Icons.bar_chart;
      default:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final profile = ref.watch(userProfileProvider);
    final transactions = ref.watch(transactionsProvider);
    final goals = ref.watch(goalsProvider);
    final memory = ref.watch(agentMemoryProvider);
    final recs = ref.watch(recommendationsProvider);

    final action = ProactiveAgentEngine.determineNextBestAction(
      profile: profile,
      transactions: transactions,
      goals: goals,
      memory: memory,
      recommendations: recs,
    );

    final color = _actionColor(action.type);
    final icon = _actionIcon(action.type);

    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
        ),
        child: Row(
          children: [
            // Pulsing dot
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: _pulseAnim.value),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Icon
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            // Text
            Expanded(
              child: Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Act button
            GestureDetector(
              onTap: () {
                ref.read(aiCoordinatorProvider.notifier).sendMessage(action.actionText);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Act',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Dismiss
            GestureDetector(
              onTap: () => setState(() => _dismissed = true),
              child: const Icon(Icons.close, size: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
