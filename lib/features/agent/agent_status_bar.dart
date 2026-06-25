import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/ai/agent/agent_orchestrator.dart';

// Provider for the currently active agent info
final activeAgentProvider = StateProvider<OrchestratorDecision?>((ref) => null);

class AgentStatusBar extends ConsumerWidget {
  const AgentStatusBar({super.key});

  Color _agentColor(ActiveAgent agent) {
    switch (agent) {
      case ActiveAgent.advisor:
        return const Color(0xFF10B981); // emerald green
      case ActiveAgent.transaction:
        return const Color(0xFF3B82F6); // blue
      case ActiveAgent.compliance:
        return const Color(0xFFF59E0B); // amber
      case ActiveAgent.none:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decision = ref.watch(activeAgentProvider);

    if (decision == null) return const SizedBox.shrink();

    final color = _agentColor(decision.agent);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _PulsingDot(color: color),
          const SizedBox(width: 8),
          Text(
            '${decision.agentEmoji} ${decision.agentDisplayName}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 1,
            height: 12,
            color: color.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              decision.routingReason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(activeAgentProvider.notifier).state = null,
            child: const Icon(Icons.close, size: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _anim.value),
          ),
        );
      },
    );
  }
}
