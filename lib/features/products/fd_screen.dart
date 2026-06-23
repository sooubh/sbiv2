import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';

class FDScreen extends ConsumerWidget {
  const FDScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fdList = ref.watch(fdListProvider);
    final totalFDValue = fdList.fold(0.0, (sum, fd) => sum + fd.principalAmount);
    final totalInterest = fdList.fold(0.0, (sum, fd) => sum + (fd.principalAmount * (fd.interestRate / 100) * 0.08));
    final principalValue = totalFDValue - totalInterest;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text('Fixed Deposits', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FD Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF004D40), Color(0xFF00796B)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total FD Value', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('₹${totalFDValue.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Principal', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                          Text('₹${principalValue.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Interest Earned', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                          Text('+ ₹${totalInterest.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Insight
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade800, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Renewal Recommendation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade900)),
                        Text('Auto-renew your upcoming Tax Saving FD to lock in the current high 7.25% interest rate.', style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade900)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active FDs
            Text('Active FDs', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            fdList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text('No active Fixed Deposits yet.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                    ),
                  )
                : Column(
                    children: fdList.map((fd) {
                      final daysLeft = fd.maturityDate.difference(DateTime.now()).inDays;
                      final maturityText = daysLeft <= 0
                          ? 'Matured'
                          : daysLeft > 30
                              ? '${(daysLeft / 30).floor()} months left'
                              : '$daysLeft days left';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildFDCard(
                          fd.title,
                          '${fd.interestRate.toStringAsFixed(2)}% p.a.',
                          '₹${fd.principalAmount.toStringAsFixed(0)}',
                          maturityText,
                        ),
                      );
                    }).toList(),
                  ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(fdListProvider.notifier).openFD('Standard FD', 50000.0);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opened a new Standard FD of ₹50,000!')));
                },
                icon: const Icon(Icons.add),
                label: const Text('Open New FD'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFDCard(String title, String rate, String amount, String maturity) {
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
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(rate, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Principal Amount', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    Text(amount, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Maturity', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    Text(maturity, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
