import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sips = ref.watch(sipListProvider).where((s) => s.status == 'active').toList();
    final totalInvested = sips.fold(0.0, (sum, s) => sum + s.amount) * 14.5;
    final gain = totalInvested * 0.124;
    final totalValue = totalInvested + gain;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text('Mutual Funds & SIPs', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Portfolio Value', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.accentGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text('+12.4% XIRR', style: GoogleFonts.inter(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('₹${totalValue.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invested', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                          Text('₹${totalInvested.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Gain', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                          Text('+ ₹${gain.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 16, fontWeight: FontWeight.w600)),
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
                color: AppTheme.aiTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.aiTeal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_graph, color: AppTheme.aiTeal, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auto-Invest Insight', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                        Text('Based on your salary credit, we recommend increasing your SIP in SBI Bluechip Fund by ₹2,000.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active SIPs
            Text('Active SIPs', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            sips.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text('No active Mutual Fund SIPs yet.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                    ),
                  )
                : Column(
                    children: sips.map((sip) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildFundCard(
                          sip.fundName,
                          sip.category,
                          '₹${sip.amount.toStringAsFixed(0)}',
                          sip.nextPaymentDate,
                          '+14.2%',
                        ),
                      );
                    }).toList(),
                  ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(sipListProvider.notifier).createSIP('SBI Bluechip Fund', 10000.0, category: 'Large Cap');
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Created a new SIP of ₹10,000 in SBI Bluechip Fund!')));
                },
                icon: const Icon(Icons.explore),
                label: const Text('Explore New Funds'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFundCard(String title, String type, String amount, String date, String returnRate) {
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
                Text(returnRate, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
              ],
            ),
            const SizedBox(height: 4),
            Text(type, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('$amount/mo', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Next Date', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    Text(date, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
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
