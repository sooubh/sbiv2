import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/data/models/models.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text('Goal Savings', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Saving Plan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.aiTeal, Color(0xFF00796B)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text('AI Saving Plan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Your "Dream Car" goal is on track. You can reach it 2 months early if you increase your monthly auto-save by ₹1,500.', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.4)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.aiTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {},
                      child: Text('Apply Plan', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Goals
            Text('Your Goals', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            
            ...goals.map((goal) => _buildGoalCard(context, ref, goal)),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Create New Goal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primary),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, Goal goal) {
    final progress = goal.savedAmount / goal.targetAmount;
    final remainingDays = goal.deadline.difference(DateTime.now()).inDays;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryLight.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('₹${goal.savedAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Target ($remainingDays days left)', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('₹${goal.targetAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(goalsProvider.notifier).boostGoal(goal.id, 1000);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added ₹1,000 to goal!')));
                },
                icon: const Icon(Icons.flash_on, size: 16),
                label: const Text('Boost with ₹1,000'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.accentOrange),
              ),
            )
          ],
        ),
      ),
    );
  }
}
