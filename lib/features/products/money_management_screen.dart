import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';

class MoneyManagementScreen extends ConsumerWidget {
  const MoneyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text('Money Management', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Score
            Center(
              child: Column(
                children: [
                  Text('Financial Health Score', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CircularProgressIndicator(
                          value: profile.healthScore / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                      Text('${profile.healthScore}', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('You are in the top 20% of savers!', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Budget Planning
            Text('Monthly Budget', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final budget = ref.watch(budgetProvider);
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Spent: ₹${budget.spent.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            Text('Limit: ₹${budget.limit.toStringAsFixed(0)}', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: budget.limit > 0 ? (budget.spent / budget.limit).clamp(0.0, 1.0) : 0.0,
                          backgroundColor: Colors.grey.shade200,
                          color: AppTheme.accentOrange,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 16),
                        ...budget.categoryLimits.entries.map((entry) {
                          final category = entry.key;
                          final limit = entry.value;
                          final spent = budget.categorySpent[category] ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildCategoryRow(category, spent, limit),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // AI Savings Opportunities
            Text('Savings Opportunities', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            _buildOpportunityCard('Switch to 0-Forex Card', 'Save ~₹4,500 on international trips based on your past travel patterns.'),
            const SizedBox(height: 8),
            _buildOpportunityCard('Optimize Subscriptions', 'You have 3 active OTT subscriptions. Consolidating could save you ₹500/month.'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String name, double spent, double limit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
        Text('₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildOpportunityCard(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.aiTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: AppTheme.aiTeal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
