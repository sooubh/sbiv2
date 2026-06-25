import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';
import 'package:sbiv2/features/home/home_screen.dart';
import 'package:sbiv2/features/products/products_screen.dart';
import 'package:sbiv2/features/engagement/engagement_screen.dart';
import 'package:sbiv2/features/ai_chat/ai_chat_screen.dart';
import 'package:sbiv2/features/settings/settings_screen.dart';
import 'package:sbiv2/features/settings/debug_simulation_page.dart';
import 'package:sbiv2/features/agent/models/timeline_entry.dart';

class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({super.key});

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const ProductsScreen(),
    const EngagementScreen(),
    const AiChatScreen(),
    const SettingsScreen(),
  ];

  void _showNotificationsCenter(BuildContext context, List<Recommendation> activeRecs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top drag line
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI Recommendations',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: activeRecs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'All caught up!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You have no pending recommendations.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: activeRecs.length,
                            separatorBuilder: (context, index) => const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final rec = activeRecs[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.aiTeal.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome,
                                          color: AppTheme.aiTeal,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rec.title,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              rec.subtitle,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.lightbulb_outline,
                                          color: AppTheme.accentOrange,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            rec.aiReason,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppTheme.textPrimary,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        
                                        // Determine command/action based on recommendation
                                        String command = "";
                                        if (rec.id == 'rec_01' || rec.title.toLowerCase().contains('fd') || rec.title.toLowerCase().contains('fixed deposit')) {
                                          command = "Open FD";
                                        } else if (rec.id == 'rec_02' || rec.title.toLowerCase().contains('sip')) {
                                          command = "Resume SIP";
                                        } else {
                                          command = rec.title;
                                        }
                                        
                                        // Mark completed
                                        ref.read(recommendationsProvider.notifier).completeRecommendation(rec.id);
                                        
                                        // Log timeline event
                                        ref.read(timelineProvider.notifier).log(
                                          type: TimelineEntryType.toolCompleted,
                                          title: 'Recommendation Accepted: ${rec.title}',
                                          description: 'User initiated action via Notifications Center.',
                                          status: TimelineEntryStatus.success,
                                        );
                                        
                                        // Trigger action
                                        ref.read(aiCoordinatorProvider.notifier).sendMessage(command);
                                        ref.read(currentNavIndexProvider.notifier).state = 3; // Go to AI Chat screen
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Take Action',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.arrow_forward, size: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentNavIndexProvider);
    final aiState = ref.watch(aiCoordinatorProvider);
    final agentState = ref.watch(agentStateProvider);
    final coins = ref.watch(engagementProvider).sbiCoins;

    Color statusColor = AppTheme.aiTeal;
    String statusText = "AI Engine: Simulated Mode";

    if (agentState.transportType == "rest") {
      statusColor = AppTheme.accentGreen;
      statusText = "AI Engine: REST (Active)";
    } else if (agentState.status == AgentStatus.error) {
      statusColor = AppTheme.accentOrange;
      statusText = "AI Engine: Error (${agentState.lastError ?? 'Unknown'})";
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'yono',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              ' sbi',
              style: GoogleFonts.poppins(
                color: AppTheme.aiTeal,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '2.0',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Coins indicator
          GestureDetector(
            onTap: () {
              ref.read(currentNavIndexProvider.notifier).state = 2; // Navigate to Engagement Screen
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$coins',
                    style: AppTheme.monoStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notification bell icon button
          Consumer(
            builder: (context, ref, child) {
              final recommendations = ref.watch(recommendationsProvider);
              final activeRecs = recommendations.where((r) => !r.isCompleted).toList();
              final count = activeRecs.length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      _showNotificationsCenter(context, activeRecs);
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentOrange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          
          // Gear Settings Button
          GestureDetector(
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugSimulationPage()),
              );
            },
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                ref.read(currentNavIndexProvider.notifier).state = 4; // Navigate to Settings Screen
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // AI status line
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: AppTheme.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (aiState.isThinking)
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.aiTeal),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Thinking...",
                        style: GoogleFonts.inter(color: AppTheme.aiTeal, fontSize: 10, fontWeight: FontWeight.bold),
                      )
                    ],
                  )
              ],
            ),
          ),
          Expanded(child: _screens[currentIndex]),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: AppTheme.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, currentIndex: currentIndex, onTap: (i) => ref.read(currentNavIndexProvider.notifier).state = i),
              _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Products', index: 1, currentIndex: currentIndex, onTap: (i) => ref.read(currentNavIndexProvider.notifier).state = i),
              _NavItem(icon: Icons.emoji_events_rounded, label: 'Rewards', index: 2, currentIndex: currentIndex, onTap: (i) => ref.read(currentNavIndexProvider.notifier).state = i),
              _NavItem(icon: Icons.smart_toy_rounded, label: 'AI Chat', index: 3, currentIndex: currentIndex, onTap: (i) => ref.read(currentNavIndexProvider.notifier).state = i),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', index: 4, currentIndex: currentIndex, onTap: (i) => ref.read(currentNavIndexProvider.notifier).state = i),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
