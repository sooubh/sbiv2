import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/pattern_engine.dart';

class EngagementScreen extends ConsumerStatefulWidget {
  const EngagementScreen({super.key});

  @override
  ConsumerState<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends ConsumerState<EngagementScreen> {
  // Track actions executed directly on this screen to display "Done ✅ by Agent"
  final Map<String, bool> _completedFeedActions = {};

  void _showWhyDialog(BuildContext context, String title, String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.psychology, color: AppTheme.aiTeal),
            const SizedBox(width: 8),
            Text('Why this recommendation?', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          reason,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final txs = ref.watch(transactionsProvider);
    final engagement = ref.watch(engagementProvider);
    final goals = ref.watch(goalsProvider);

    // Run PatternEngine
    final signals = PatternEngine.analyze(profile, txs);

    // Calculate dynamic spending breakdown for Donut Chart
    final debits = txs.where((t) => t.type == 'debit').toList();
    final Map<String, double> categoryTotals = {};
    double totalDebitAmount = 0.0;
    for (var tx in debits) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0.0) + tx.amount;
      totalDebitAmount += tx.amount;
    }

    // Build chart section list
    final List<PieChartSectionData> chartSections = [];
    final List<Color> sectionColors = [
      AppTheme.primary,
      AppTheme.accentOrange,
      AppTheme.accentGreen,
      Colors.indigo,
      Colors.teal,
    ];

    int colorIdx = 0;
    categoryTotals.forEach((cat, val) {
      final color = sectionColors[colorIdx % sectionColors.length];
      chartSections.add(
        PieChartSectionData(
          color: color,
          value: val,
          title: '${(val / totalDebitAmount * 100).toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIdx++;
    });

    // Dynamic AI Story Text
    String aiStoryTitle = "Weekly AI Story";
    String aiStoryContent = "Aapka account Rohan fresh state mein hai. Start spending using UPI to build your personalized financial story!";
    if (profile.name == 'Sourabh') {
      final recentSalary = txs.firstWhere((t) => t.category == 'Salary', orElse: () => txs.first);
      aiStoryContent = "Namaste Sourabh! TCS salary crediting of ₹${recentSalary.amount.toStringAsFixed(0)} was successfully logged on Jun 20. Rent was paid on Jun 21. Rent accounts for ${(categoryTotals['Rent'] ?? 0.0) / totalDebitAmount * 100}% of your total expenditure. The PatternEngine noticed your SBI Bluechip SIP was missed this month. Your idle savings balance of ₹${profile.balance.toStringAsFixed(0)} can generate higher yield.";
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Your Financial Story',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Gamification Row (streak 🔥, coins 🪙, next milestone)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Streak
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: AppTheme.accentOrange, size: 24),
                            const SizedBox(width: 4),
                            Text(
                              '${engagement.streakCount}',
                              style: AppTheme.monoStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Day Streak', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(
                      height: 32,
                      child: VerticalDivider(color: AppTheme.border, width: 1),
                    ),
                    // Coins
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                            const SizedBox(width: 4),
                            Text(
                              '${engagement.sbiCoins}',
                              style: AppTheme.monoStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('SBI Coins', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(
                      height: 32,
                      child: VerticalDivider(color: AppTheme.border, width: 1),
                    ),
                    // Next Milestone
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_events, color: AppTheme.primary, size: 22),
                            const SizedBox(width: 4),
                            Text(
                              'Level 2',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('300 coins to Gold', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Weekly AI Story Card (AI Teal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.aiTeal,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.aiTeal.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_stories, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        aiStoryTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.psychology, color: Colors.white, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    aiStoryContent,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Last updated today',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Donut Spending Breakdown Chart
          if (debits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Expense Breakdown',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: PieChart(
                              PieChartData(
                                sections: chartSections,
                                centerSpaceRadius: 30,
                                sectionsSpace: 2,
                                startDegreeOffset: -90,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categoryTotals.entries.map((entry) {
                                final colorIdxLocal = categoryTotals.keys.toList().indexOf(entry.key);
                                final color = sectionColors[colorIdxLocal % sectionColors.length];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(width: 12, height: 12, color: color),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        '₹${entry.value.toStringAsFixed(0)}',
                                        style: AppTheme.monoStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Agent Noticed Feed Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Agent Noticed Feed',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Agent Noticed Feed List
          if (profile.name == 'Sourabh') ...[
            // Card 1: Missed SIP
            if (signals.missedRecurring)
              _buildFeedCard(
                key: 'feed_sip',
                title: 'SIP Missed Alert',
                subtitle: 'June SBI Bluechip SIP missed. Restore now.',
                whyReason: 'PatternEngine detected you paid ₹5,000 for SBI Mutual Fund in May, but did not have a corresponding debit in June.',
                actionLabel: 'Resume SIP',
                onExecuted: () {
                  ref.read(servicesProvider.notifier).activateService('srv_sip');
                  ref.read(engagementProvider.notifier).addCoins(40);
                },
              ),

            // Card 2: Idle Balance
            if (signals.idleBalance)
              _buildFeedCard(
                key: 'feed_fd',
                title: 'Idle Cash Advisory',
                subtitle: 'Move ₹50,000 idle savings cash to Fixed Deposit (7.2%).',
                whyReason: 'Your current balance is ₹${profile.balance.toStringAsFixed(0)}, which is greater than 3x your average monthly spending. Idle funds lose real value to inflation. A safe Fixed Deposit gives guaranteed yield.',
                actionLabel: 'Open FD',
                onExecuted: () {
                  ref.read(servicesProvider.notifier).activateService('srv_fd');
                  ref.read(userProfileProvider.notifier).updateBalance(-50000);
                  ref.read(transactionsProvider.notifier).addTransaction(
                        Transaction(
                          id: 'tx_fd_${DateTime.now().millisecondsSinceEpoch}',
                          amount: 50000.0,
                          payee: 'SBI Fixed Deposit (AI)',
                          category: 'Investment',
                          date: DateTime.now(),
                          type: 'debit',
                        ),
                      );
                  ref.read(engagementProvider.notifier).addCoins(50);
                },
              ),

            // Card 3: Salary Saving
            if (signals.salaryNoSave)
              _buildFeedCard(
                key: 'feed_save',
                title: 'Salary Boost Nudge',
                subtitle: 'Salary received! Auto-save ₹500 to Dream Car Goal.',
                whyReason: 'Salary credited recently. Sticking to automatic investments on payday improves wealth building probability.',
                actionLabel: 'Boost Goal',
                onExecuted: () {
                  ref.read(goalsProvider.notifier).boostGoal('goal_01', 500);
                  ref.read(userProfileProvider.notifier).updateBalance(-500);
                  ref.read(transactionsProvider.notifier).addTransaction(
                        Transaction(
                          id: 'tx_boost_feed_${DateTime.now().millisecondsSinceEpoch}',
                          amount: 500.0,
                          payee: 'Goal Boost: Dream Car',
                          category: 'Investment',
                          date: DateTime.now(),
                          type: 'debit',
                        ),
                      );
                  ref.read(engagementProvider.notifier).addCoins(20);
                },
              ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No notices from agent yet. Onboard Rohan first to generate insights.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeedCard({
    required String key,
    required String title,
    required String subtitle,
    required String whyReason,
    required String actionLabel,
    required VoidCallback onExecuted,
  }) {
    final isDone = _completedFeedActions[key] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? AppTheme.accentGreen.withOpacity(0.3) : AppTheme.aiTeal.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isDone ? Icons.check_circle : Icons.offline_bolt,
                    color: isDone ? AppTheme.accentGreen : AppTheme.aiTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDone ? AppTheme.accentGreen : AppTheme.aiTeal,
                    ),
                  ),
                  const Spacer(),
                  // Why button
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: AppTheme.textSecondary, size: 18),
                    onPressed: () => _showWhyDialog(context, title, whyReason),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isDone)
                    Text(
                      'Done ✅ by Agent',
                      style: GoogleFonts.inter(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        onExecuted();
                        setState(() {
                          _completedFeedActions[key] = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$title completed successfully!'),
                            backgroundColor: AppTheme.accentGreen,
                          ),
                        );
                      },
                      child: Text(
                        actionLabel,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
