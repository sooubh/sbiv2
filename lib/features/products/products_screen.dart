import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';

import 'package:sbiv2/features/products/accounts_screen.dart';
import 'package:sbiv2/features/products/investments_screen.dart';
import 'package:sbiv2/features/products/fd_screen.dart';
import 'package:sbiv2/features/products/goals_screen.dart';
import 'package:sbiv2/features/products/loans_screen.dart';

// ─── Animated blinking dot ────────────────────────────────────────────────────
class _BlinkingDot extends StatefulWidget {
  final Color color;
  const _BlinkingDot({required this.color});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.2, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pulsing dot (for loans EMI) ─────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Premium section card wrapper ─────────────────────────────────────────────
class _PremiumCard extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const _PremiumCard({required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
        // Colored left accent strip
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Main screen ──────────────────────────────────────────────────────────────
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
      backgroundColor: const Color(0xFFF4F5FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(profile),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Money Management Spend Chips Banner
                _buildSpendChipsBanner(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      if (nextBestAction != null) ...[
                        _buildAIAssistantBanner(context, nextBestAction),
                        const SizedBox(height: 24),
                      ],

                      // Accounts & Transactions
                      _buildCardSectionHeader(
                        Icons.account_balance_wallet_rounded,
                        'Accounts & Transactions',
                        AppTheme.primary,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                        child: _buildAccountsCard(profile, transactions),
                      ),
                      const SizedBox(height: 24),

                      // Fixed Deposits
                      _buildCardSectionHeader(
                        Icons.savings_rounded,
                        'Fixed Deposits',
                        AppTheme.accentGreen,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FDScreen())),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FDScreen())),
                        child: _buildFixedDepositsCard(),
                      ),
                      const SizedBox(height: 24),

                      // Mutual Funds & SIPs
                      _buildCardSectionHeader(
                        Icons.trending_up_rounded,
                        'Mutual Funds & SIPs',
                        AppTheme.aiTeal,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestmentsScreen())),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestmentsScreen())),
                        child: _buildSIPAndMutualFundsCard(),
                      ),
                      const SizedBox(height: 24),

                      // Loans & Credit
                      _buildCardSectionHeader(
                        Icons.real_estate_agent_rounded,
                        'Loans & Credit',
                        AppTheme.accentOrange,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoansScreen())),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoansScreen())),
                        child: _buildLoansCard(),
                      ),
                      const SizedBox(height: 24),

                      // Goal Savings
                      _buildCardSectionHeader(
                        Icons.flag_rounded,
                        'Goal Savings',
                        AppTheme.primary,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                        child: _buildGoalSavingsCard(goals),
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SliverAppBar: Financial Command Center header ──────────────────────────
  Widget _buildSliverAppBar(UserProfile profile) {
    final netWorth = profile.balance + 850000;
    return SliverAppBar(
      backgroundColor: const Color(0xFF1E1B7B),
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1B7B), Color(0xFF3D2DB5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative orb top-right
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        'Total Net Worth',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // Net Worth
                      Text(
                        '₹${_formatAmount(netWorth)}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // YTD pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentGreen.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '↑ 12.4% YTD',
                          style: GoogleFonts.inter(
                            color: AppTheme.accentGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Mini stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMiniStat('Investments', '₹2.3L'),
                          _buildMiniStatDivider(),
                          _buildMiniStat('FDs', '₹1.8L'),
                          _buildMiniStatDivider(),
                          _buildMiniStat('Loans', '₹28.5K'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 9)),
        const SizedBox(height: 1),
        Text(value, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMiniStatDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 20,
      color: Colors.white24,
    );
  }

  // ── Spend Chips Banner ─────────────────────────────────────────────────────
  Widget _buildSpendChipsBanner() {
    final chips = [
      {'label': 'Food', 'amount': '₹12K', 'emoji': '🍔', 'color': const Color(0xFFFF6B6B)},
      {'label': 'Travel', 'amount': '₹3K', 'emoji': '✈️', 'color': const Color(0xFF4ECDC4)},
      {'label': 'Rent', 'amount': '₹25K', 'emoji': '🏠', 'color': const Color(0xFF45B7D1)},
      {'label': 'Shopping', 'amount': '₹8K', 'emoji': '🛍️', 'color': const Color(0xFFFFB347)},
    ];

    return Container(
      color: const Color(0xFFF4F5FB),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month\'s Spending',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((chip) {
                final color = chip['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(chip['emoji'] as String, style: const TextStyle(fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chip['label'] as String,
                            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                          Text(
                            chip['amount'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card section header ────────────────────────────────────────────────────
  Widget _buildCardSectionHeader(
    IconData icon,
    String title,
    Color iconColor,
    VoidCallback onViewAll,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [iconColor.withValues(alpha: 0.9), iconColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View All',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ── AI Banner ─────────────────────────────────────────────────────────────
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
          ),
        ],
      ),
    );
  }

  // ── Accounts Card ─────────────────────────────────────────────────────────
  Widget _buildAccountsCard(UserProfile profile, List<Transaction> transactions) {
    return _PremiumCard(
      accentColor: AppTheme.primary,
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
                    Text('₹${profile.balance.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text('Statements', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.analytics, color: AppTheme.accentOrange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You spent 15% less on Food this month. Keep it up!',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Fixed Deposits Card ───────────────────────────────────────────────────
  Widget _buildFixedDepositsCard() {
    return _PremiumCard(
      accentColor: AppTheme.accentGreen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total FDs', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('₹1,50,000',
                        style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Interest Earned', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('+ ₹8,450',
                        style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            // Tax Saving FD row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tax Saving FD',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      // Matures row with blinking dot
                      Row(
                        children: [
                          const _BlinkingDot(color: Colors.redAccent),
                          const SizedBox(width: 5),
                          Text('Matures in 14 days',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Rate badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text('7.25% p.a.',
                      style: GoogleFonts.inter(color: AppTheme.accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                // Renew ElevatedButton.icon
                ElevatedButton.icon(
                  icon: const Icon(Icons.autorenew, size: 14),
                  label: Text('Renew', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Recommendation banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-renew this FD to lock in the current high 7.25% interest rate.',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SIP / Mutual Funds Card ───────────────────────────────────────────────
  Widget _buildSIPAndMutualFundsCard() {
    return _PremiumCard(
      accentColor: AppTheme.aiTeal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Portfolio Value', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.35)),
                  ),
                  child: Text('+12.4% XIRR',
                      style: GoogleFonts.inter(color: AppTheme.accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('₹2,45,000',
                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            // Invested vs current progress bar
            Row(
              children: [
                Text('Invested ₹1,96,000', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
                const Spacer(),
                Text('Gain ₹49,000',
                    style: GoogleFonts.inter(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 196000 / 245000,
                minHeight: 5,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.aiTeal),
              ),
            ),
            const Divider(height: 24),
            Text('Active SIPs', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildSIPRow('SBI', 'SBI Bluechip Fund', '₹10,000', '+14.2%',
                const [Color(0xFF1565C0), Color(0xFF1976D2)]),
            const SizedBox(height: 10),
            _buildSIPRow('SBI', 'SBI Small Cap Fund', '₹5,000', '+18.7%',
                const [Color(0xFF00796B), Color(0xFF00897B)]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: null,
                icon: const Icon(Icons.auto_graph, size: 16),
                label: const Text('View Auto-Invest Insights'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSIPRow(
    String initials,
    String fundName,
    String monthly,
    String xirr,
    List<Color> gradientColors,
  ) {
    return Row(
      children: [
        // Circle avatar with gradient
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(initials,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        // Name + monthly
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fundName,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text('Monthly $monthly',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        // XIRR badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(xirr,
              style: GoogleFonts.inter(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ── Loans Card ────────────────────────────────────────────────────────────
  Widget _buildLoansCard() {
    final now = DateTime.now();
    final dueDate = DateTime(now.year, 7, 5);
    final daysUntilDue = dueDate.difference(now).inDays.abs();

    return _PremiumCard(
      accentColor: AppTheme.accentOrange,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan name + outstanding
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Home Loan',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text('Outstanding: ₹32,45,000',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                // Prepay button
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.7)),
                    foregroundColor: AppTheme.accentOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Prepay', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 20),
            // Next EMI with pulsing dot
            Row(
              children: [
                const _PulsingDot(color: AppTheme.accentOrange),
                const SizedBox(width: 6),
                Text('Due Jul 5 · in $daysUntilDue days',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            // EMI amount
            Text('₹28,500',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                )),
            const SizedBox(height: 14),
            // Repayment progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('65% repaid',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.accentGreen, fontWeight: FontWeight.w600)),
                Text('₹60.5L of ₹93L',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.65,
                minHeight: 6,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
              ),
            ),
            const SizedBox(height: 14),
            // Insight banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.aiTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.aiTeal.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insights, color: AppTheme.aiTeal, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pre-approved for a Car Loan up to ₹8,00,000 at 8.65% p.a.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Goal Savings Card ─────────────────────────────────────────────────────
  Widget _buildGoalSavingsCard(List<Goal> goals) {
    return _PremiumCard(
      accentColor: AppTheme.primary,
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
                        Text('${(progress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade100,
                        color: AppTheme.primary,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${goal.savedAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                    ),
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
                  backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.4),
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
