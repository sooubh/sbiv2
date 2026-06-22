import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/pattern_engine.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final txs = ref.watch(transactionsProvider);
    final recommendations = ref.watch(recommendationsProvider);

    // Analyze transactions to get signals
    final signals = PatternEngine.analyze(profile, txs);

    // Get next best action (highest priority recommendation that is not completed)
    final activeRecommendations = recommendations.where((r) => !r.isCompleted).toList();
    final nextBestAction = activeRecommendations.isNotEmpty ? activeRecommendations.first : null;

    // Get the core signal text for the "Agent is watching" card
    String agentInsightTitle = "SBI Agent Advisor";
    String agentInsightText = "Everything looks good! Your financial health is on track.";
    Color agentInsightColor = AppTheme.aiTeal;

    if (profile.kycComplete == false) {
      agentInsightTitle = "KYC Onboarding Active";
      agentInsightText = "Namaste Rohan! Click the 'KYC App' tab to finish Aadhaar/PAN verification & activate UPI.";
      agentInsightColor = AppTheme.accentOrange;
    } else if (signals.missedRecurring) {
      agentInsightTitle = "Missed SIP Detected";
      agentInsightText = "Salary credited but SBI Bluechip SIP was missed this month. TAP here or go to AI Chat to resolve.";
      agentInsightColor = AppTheme.accentOrange;
    } else if (signals.idleBalance) {
      agentInsightTitle = "Idle Balance Advisory";
      agentInsightText = "₹${profile.balance.toStringAsFixed(0)} is idle in savings. Transfer it to SBI FD at 7.2% secure interest.";
      agentInsightColor = AppTheme.aiTeal;
    } else if (signals.salaryNoSave) {
      agentInsightTitle = "Salary Savings Alert";
      agentInsightText = "Salary credited 2 days ago. Allocate a portion to your savings goal to maintain investment streak.";
      agentInsightColor = AppTheme.aiTeal;
    } else if (signals.lowBalance) {
      agentInsightTitle = "Low Balance Buffer";
      agentInsightText = "Balance is currently low. Avoid heavy debits or load funds via UPI.";
      agentInsightColor = AppTheme.accentOrange;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // YONO Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Good Morning,',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      profile.kycComplete ? 'Premium Account' : 'Incomplete KYC',
                      style: GoogleFonts.inter(
                        color: profile.kycComplete ? AppTheme.accentGreen : AppTheme.accentOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),

          // Balance Card overlapping slightly
          Transform.translate(
            offset: const Offset(0, -12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.transparent),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Savings Account',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            profile.name == 'Sourabh' ? 'SB A/c *******4821' : 'SB A/c *******9901',
                            style: AppTheme.monoStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile.balance.toStringAsFixed(2),
                            style: AppTheme.monoStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Agent is watching Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: agentInsightColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: agentInsightColor.withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        agentInsightColor == AppTheme.aiTeal ? Icons.insights : Icons.warning_amber_rounded,
                        color: agentInsightColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        agentInsightTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: agentInsightColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: agentInsightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Agent Mode',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    agentInsightText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Actions Grid (UPI Pay, FD, Send Money, SIP)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildQuickActionItem(
                      icon: Icons.qr_code_scanner,
                      label: 'UPI Pay',
                      color: AppTheme.primary,
                      enabled: profile.upiEnabled,
                    ),
                    _buildQuickActionItem(
                      icon: Icons.account_balance,
                      label: 'Open FD',
                      color: AppTheme.primary,
                      enabled: profile.kycComplete,
                    ),
                    _buildQuickActionItem(
                      icon: Icons.send,
                      label: 'Send Money',
                      color: AppTheme.primary,
                      enabled: profile.kycComplete,
                    ),
                    _buildQuickActionItem(
                      icon: Icons.trending_up,
                      label: 'SIP (MF)',
                      color: AppTheme.primary,
                      enabled: profile.kycComplete,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Next Best Action Recommendation
          if (nextBestAction != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Best Action',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.aiTeal.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: AppTheme.aiTeal, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Agent Pick',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.aiTeal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Priority #${nextBestAction.priority}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            nextBestAction.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextBestAction.subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const Divider(height: 24, color: AppTheme.border),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.aiTeal, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Reason: ${nextBestAction.aiReason}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                // Mark as completed and execute action
                                ref.read(recommendationsProvider.notifier).completeRecommendation(nextBestAction.id);
                                // Give coins
                                ref.read(engagementProvider.notifier).addCoins(40);
                                ref.read(engagementProvider.notifier).addAchievement('Action Completed');

                                if (nextBestAction.id == 'rec_02') {
                                  // Re-activate SIP
                                  ref.read(servicesProvider.notifier).activateService('srv_sip');
                                } else if (nextBestAction.id == 'rec_01') {
                                  // Open FD
                                  ref.read(servicesProvider.notifier).activateService('srv_fd');
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Agent executed: ${nextBestAction.title}! Awarded 40 Coins.'),
                                    backgroundColor: AppTheme.accentGreen,
                                  ),
                                );
                              },
                              child: Text(
                                nextBestAction.id == 'rec_02' ? 'Resume SIP (1-Click)' : 'Activate Now',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled
              ? () {
                  // Standard quick action tap
                }
              : null,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
