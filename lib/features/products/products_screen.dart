import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';

import 'package:sbiv2/features/products/accounts_screen.dart';
import 'package:sbiv2/features/products/money_management_screen.dart';
import 'package:sbiv2/features/products/investments_screen.dart';
import 'package:sbiv2/features/products/fd_screen.dart';
import 'package:sbiv2/features/products/goals_screen.dart';
import 'package:sbiv2/features/products/loans_screen.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final recommendations = ref.watch(recommendationsProvider);
    final goals = ref.watch(goalsProvider);
    final transactions = ref.watch(transactionsProvider);

    final activeRecs = recommendations.where((r) => !r.isCompleted).toList();
    activeRecs.sort((a, b) => a.priority.compareTo(b.priority));
    final nextBestAction = activeRecs.isNotEmpty ? activeRecs.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(profile),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (nextBestAction != null) _buildAIAssistantBanner(context, nextBestAction),
                if (nextBestAction != null) const SizedBox(height: 24),
                
                _buildSectionHeader(Icons.account_balance_wallet, 'Accounts & Transactions'),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                  child: _buildAccountsCard(profile, transactions),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader(Icons.pie_chart, 'Money Management'),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoneyManagementScreen())),
                  child: _buildMoneyManagementCard(profile),
                ),
                const SizedBox(height: 24),
                
                _buildSectionHeader(Icons.trending_up, 'Mutual Funds & SIPs'),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestmentsScreen())),
                  child: _buildSIPAndMutualFundsCard(),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader(Icons.savings, 'Fixed Deposits'),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FDScreen())),
                  child: _buildFixedDepositsCard(),
                ),
                const SizedBox(height: 24),
                
                _buildSectionHeader(Icons.flag, 'Goal Savings'),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                  child: _buildGoalSavingsCard(goals),
                ),
                const SizedBox(height: 24),
                
                _buildSectionHeader(Icons.real_estate_agent, 'Loans & Credit'),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoansScreen())),
                  child: _buildLoansCard(),
                ),
                
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(UserProfile profile) {
    return SliverAppBar(
      backgroundColor: AppTheme.primary,
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'Wealth Hub',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Net Worth', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('₹${(profile.balance + 850000).toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Health', style: GoogleFonts.inter(color: Colors.white, fontSize: 10)),
                      Text('${profile.healthScore}', style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  Widget _buildAIAssistantBanner(BuildContext context, Recommendation action) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.aiTeal, Color(0xFF00796B)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppTheme.aiTeal.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text('AI Financial Assistant', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Text('Next Best Action', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(action.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(action.aiReason, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.aiTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              onPressed: () {},
              child: Text('Take Action', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAccountsCard(UserProfile profile, List<Transaction> transactions) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Savings Account', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('₹${profile.balance.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text('View Statements', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary)),
                )
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.analytics, color: AppTheme.accentOrange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('You spent 15% less on Food this month. Keep it up!', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMoneyManagementCard(UserProfile profile) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Budget', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('₹32,000 / ₹45,000', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                CircularProgressIndicator(
                  value: 32000 / 45000,
                  backgroundColor: Colors.grey.shade200,
                  color: AppTheme.accentOrange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.aiTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: AppTheme.aiTeal, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Savings Opportunity: Switch to a 0-forex card for your upcoming international trip to save ~₹4,500.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSIPAndMutualFundsCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Portfolio Value', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.accentGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text('+12.4% XIRR', style: GoogleFonts.inter(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('₹2,45,000', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Text('Active SIPs', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildListTile('SBI Small Cap Fund', '₹5,000/mo', 'Next Date: 5th Jul'),
            const SizedBox(height: 8),
            _buildListTile('SBI Bluechip Fund', '₹10,000/mo', 'Next Date: 12th Jul'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: null,
                icon: const Icon(Icons.auto_graph, size: 16),
                label: const Text('View Auto-Invest Insights'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFixedDepositsCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total FDs', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('₹1,50,000', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Interest Earned', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('+ ₹8,450', style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _buildListTile('Tax Saving FD', 'Matures in 14 days', '7.1% p.a.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Recommendation: Auto-renew upcoming FD to lock in the current high 7.25% interest rate.', style: GoogleFonts.inter(fontSize: 11, color: Colors.orange.shade900)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSavingsCard(List<Goal> goals) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Goals', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            ...goals.map((goal) {
              final progress = goal.savedAmount / goal.targetAmount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(goal.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      color: AppTheme.primary,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text('₹${goal.savedAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              );
            }),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create New Goal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLoansCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildListTile('Home Loan', 'Outstanding: ₹32,45,000', 'Next EMI: ₹28,500 on 5th Jul'),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.aiTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.insights, color: AppTheme.aiTeal, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Eligibility Insight: You are pre-approved for a Car Loan up to ₹8,00,000 at 8.65% p.a.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        Text(trailing, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ],
    );
  }
}
