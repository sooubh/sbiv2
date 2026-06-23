import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';


class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text('Accounts & Transactions', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryDark, AppTheme.primaryLight]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Balance', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('₹${profile.balance.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('A/c No: XXXXXX4589', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                      Text('IFSC: SBIN0001234', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Insights
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.aiTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.aiTeal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insights, color: AppTheme.aiTeal, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spending Insight', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                        Text('Your grocery spending is 12% lower than last month. Great job managing expenses!', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            Text('Recent Transactions', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            
            transactions.isEmpty 
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('No transactions yet.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                ))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isCredit = tx.type == 'credit';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isCredit ? AppTheme.accentGreen.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? AppTheme.accentGreen : Colors.red,
                          size: 16,
                        ),
                      ),
                      title: Text(tx.payee, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text('${tx.category} • ${_formatDate(tx.date)}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                      trailing: Text(
                        '${isCredit ? '+' : '-'} ₹${tx.amount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCredit ? AppTheme.accentGreen : AppTheme.textPrimary,
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final hourNum = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final hour = hourNum.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $hour:$minute $period';
  }
}
