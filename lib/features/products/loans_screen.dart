import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/data/models/models.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanList = ref.watch(loanListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text('Loans & Credit', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pre-approved Offer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppTheme.accentGreen, size: 20),
                      const SizedBox(width: 8),
                      Text('Pre-Approved Offer', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Car Loan up to ₹8,00,000', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Instant disbursal • 8.65% p.a. • Zero processing fee', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    onPressed: () {},
                    child: Text('Claim Offer', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Loans
            Text('Active Loans', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            loanList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text('No active Loans yet.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                    ),
                  )
                : Column(
                    children: loanList.map((loan) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildLoanCard(context, ref, loan),
                      );
                    }).toList(),
                  ),
            
            const SizedBox(height: 24),
            
            // AI Eligibility Insights
            Text('Eligibility Insights', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.aiTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.aiTeal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics, color: AppTheme.aiTeal, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prepayment Suggestion', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                        Text('Using ₹50,000 from your idle savings to prepay your Home Loan can save you ₹1.2L in interest.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, WidgetRef ref, Loan loan) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loan.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
                    Text('A/c: ${loan.accountNumber}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Active', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outstanding Balance', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('₹${loan.outstandingBalance.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Next EMI', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('₹${loan.emiAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text('Due: ${loan.nextDueDate}', style: GoogleFonts.inter(fontSize: 10, color: Colors.red)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: loan.percentRepaid,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text('${(loan.percentRepaid * 100).toStringAsFixed(0)}% Repaid', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final profile = ref.read(userProfileProvider);
                      if (profile.balance < loan.emiAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance to pay EMI!')));
                        return;
                      }
                      ref.read(userProfileProvider.notifier).updateBalance(-loan.emiAmount);
                      ref.read(loanListProvider.notifier).payEMI(loan.id, loan.emiAmount);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('EMI of ₹${loan.emiAmount.toStringAsFixed(0)} paid!')));
                    },
                    child: const Text('Pay EMI'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(loanListProvider.notifier).prepayLoan(loan.id, 10000.0);
                      ref.read(userProfileProvider.notifier).updateBalance(-10000.0);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prepaid ₹10,000 on Loan outstanding!')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    child: const Text('Prepay ₹10k'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
