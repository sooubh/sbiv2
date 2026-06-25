import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/features/login/existing_customer_login_screen.dart';
import 'package:sbiv2/features/onboarding/onboarding_screen.dart';
import 'package:sbiv2/features/settings/settings_screen.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';
import 'package:sbiv2/ai/events/agent_event.dart';

class CustomerSelectionScreen extends ConsumerWidget {
  const CustomerSelectionScreen({super.key});

  void _setupProfile(WidgetRef ref, String profileType) {
    // 1. Clear Hive data for Profile A before switching to prevent stale profile loading
    if (profileType == 'A') {
      Hive.box(kProfileBox).delete('profile_A');
      Hive.box(kAgentMemoryBox).delete('memory_A');
      Hive.box(kTransactionsBox).delete('txs_A');
      Hive.box(kFDBox).delete('fds_A');
      Hive.box(kSipBox).delete('sips_A');
      Hive.box(kLoanBox).delete('loans_A');
      Hive.box(kBudgetBox).delete('budget_A');
      Hive.box(kTimelineBox).delete('entries_A');
    }

    // 2. Set the profile type provider (triggers coordinator updates)
    ref.read(profileTypeProvider.notifier).setProfile(profileType);
    ref.read(isLoggedInProvider.notifier).state = false;

    // 3. Reset all providers to clean defaults
    if (profileType == 'A') {
      ref.read(userProfileProvider.notifier).clearForOnboarding();
    } else {
      ref.read(userProfileProvider.notifier).reset();
    }
    
    ref.read(transactionsProvider.notifier).reset();
    ref.read(goalsProvider.notifier).reset();
    ref.read(recommendationsProvider.notifier).reset();
    ref.read(servicesProvider.notifier).reset();
    ref.read(engagementProvider.notifier).reset();
    ref.read(onboardingChatProvider.notifier).reset();
    ref.read(bankingChatProvider.notifier).reset();
    ref.read(timelineProvider.notifier).clear();
    ref.read(agentEventProvider.notifier).clear();
    ref.read(agentStateProvider.notifier).reset();
    ref.read(agentMemoryProvider.notifier).reset();

    final isOnboarding = profileType == 'A';
    ref.read(agentStateProvider.notifier).setMode(
      isOnboarding ? AgentMode.onboarding : AgentMode.banking
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'YONO SBI 2.0',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Namaste! Welcome',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select your customer profile type to begin.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 36),
              Expanded(
                child: Column(
                  children: [
                    _buildProfileCard(
                      context: context,
                      title: 'New Customer',
                      subtitle: 'Start secure digital onboarding and UPI activation',
                      details: '• Zero-balance Account Opening\n• Instant UPI VPA Setup\n• AI-Guided Document Check\n• Interactive video verification',
                      icon: Icons.person_add_alt_1_outlined,
                      gradientColors: [AppTheme.primary, AppTheme.aiTeal],
                      onTap: () {
                        _setupProfile(ref, 'A');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildProfileCard(
                      context: context,
                      title: 'Existing Customer',
                      subtitle: 'Sign in to access your dashboard & proactive assistant',
                      details: '• Standard SBI Savings Profile\n• Portfolio Intelligence Advisor\n• Pre-Approved Loan & FD Options\n• Gamified Streak tracking',
                      icon: Icons.login_outlined,
                      gradientColors: [AppTheme.primaryDark, AppTheme.accentGreen],
                      onTap: () {
                        _setupProfile(ref, 'B');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExistingCustomerLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String details,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                bottom: -24,
                child: Icon(
                  icon,
                  size: 140,
                  color: AppTheme.border.withValues(alpha: 0.35),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      details,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
