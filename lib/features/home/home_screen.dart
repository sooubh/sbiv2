import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/ai/behavior/next_best_action.dart';
import 'package:sbiv2/ai/agent/advisor_agent.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/features/agent/agent_status_bar.dart';
import 'package:sbiv2/features/agent/widgets/voice_copilot_overlay.dart';

// ── Utility ─────────────────────────────────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
  return 'U';
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'food':
    case 'dining':
      return Icons.restaurant_rounded;
    case 'shopping':
      return Icons.shopping_bag_rounded;
    case 'travel':
    case 'transport':
      return Icons.directions_car_rounded;
    case 'salary':
    case 'income':
      return Icons.account_balance_wallet_rounded;
    case 'investment':
    case 'sip':
      return Icons.trending_up_rounded;
    case 'utilities':
    case 'electricity':
      return Icons.bolt_rounded;
    case 'health':
    case 'medical':
      return Icons.favorite_rounded;
    default:
      return Icons.receipt_rounded;
  }
}

Color _categoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'food':
    case 'dining':
      return const Color(0xFFFF6B6B);
    case 'shopping':
      return const Color(0xFFA855F7);
    case 'travel':
    case 'transport':
      return const Color(0xFF3B82F6);
    case 'salary':
    case 'income':
      return AppTheme.accentGreen;
    case 'investment':
    case 'sip':
      return AppTheme.aiTeal;
    case 'utilities':
    case 'electricity':
      return const Color(0xFFF59E0B);
    case 'health':
    case 'medical':
      return const Color(0xFFEF4444);
    default:
      return AppTheme.primary;
  }
}

String _shortDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${date.day} ${months[date.month - 1]}';
}

// ── Home Screen ──────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final transactions = ref.watch(transactionsProvider);
    final goals = ref.watch(goalsProvider);
    final memory = ref.watch(agentMemoryProvider);
    final recommendations = ref.watch(recommendationsProvider);

    final action = AdvisorAgent.evaluate(
      profile: profile,
      transactions: transactions,
      goals: goals,
      memory: memory,
      recommendations: recommendations,
    );

    final recentTxns = transactions.take(3).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _LuxuryHeader(profile: profile),
          ),

          // ── Balance Card (floats over header) ────────────────────────────
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BalanceCard(profile: profile),
              ),
            ),
          ),

          // ── Agent Status Bar ─────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: AgentStatusBar(),
          ),

          // ── Agent Insight Mini-Popup ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _AgentInsightBanner(action: action),
          ),

          // ── Quick Actions Row ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _QuickActionsRow(ref: ref),
          ),

          // ── Recent Transactions ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: _RecentTransactions(transactions: recentTxns, ref: ref),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      floatingActionButton: Tooltip(
        message: 'AI Co-Pilot',
        child: FloatingActionButton(
          onPressed: () => VoiceCopilotOverlay.show(context),
          backgroundColor: AppTheme.primary,
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 1 — Luxury Header
// ─────────────────────────────────────────────────────────────────────────────

class _LuxuryHeader extends StatelessWidget {
  final UserProfile profile;
  const _LuxuryHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Avatar + Icons ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.aiTeal, AppTheme.accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(profile.name),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              // Right icons
              Row(
                children: [
                  // Coin badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.healthScore} pts',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Bell
                  Stack(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(Icons.notifications_rounded,
                            color: Colors.white, size: 20),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Greeting ─────────────────────────────────────────────────────
          Text(
            'Good Morning 🌤️',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile.name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 14),

          // ── Frosted Premier Pill ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded,
                    color: AppTheme.accentGreen, size: 14),
                const SizedBox(width: 6),
                Text(
                  'SBI YONO Premier',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 2 — Balance Card
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final UserProfile profile;
  const _BalanceCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          transform: const GradientRotation(135 * math.pi / 180),
          colors: const [Color(0xFF1E1B7B), Color(0xFF3D2DB5)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Balance + Health Ring row ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: balance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            _formatBalance(profile.balance),
                            style: AppTheme.monoStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right: Health Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(
                      value: profile.healthScore / 100,
                      strokeWidth: 5,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accentGreen),
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${profile.healthScore}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'score',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Status Chips ──────────────────────────────────────────────
          Row(
            children: [
              _statusChip('Debit Card 🟢 Active'),
              const SizedBox(width: 6),
              _statusChip('UPI ⚡ Live'),
              const SizedBox(width: 6),
              _statusChip('NetBanking ✓'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBalance(double balance) {
    if (balance >= 100000) {
      return (balance / 100000).toStringAsFixed(2) + 'L';
    }
    // Format with commas for Indian numbering
    final parts = balance.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    if (intPart.length > 3) {
      final lastThree = intPart.substring(intPart.length - 3);
      final remaining = intPart.substring(0, intPart.length - 3);
      final formatted = remaining.replaceAllMapped(
          RegExp(r'(\d)(?=(\d{2})+$)'), (m) => '${m[1]},');
      return '$formatted,$lastThree.$decPart';
    }
    return '$intPart.$decPart';
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 3 — Agent Insight Mini-Popup
// ─────────────────────────────────────────────────────────────────────────────

class _AgentInsightBanner extends StatefulWidget {
  final NextBestAction action;
  const _AgentInsightBanner({required this.action});

  @override
  State<_AgentInsightBanner> createState() => _AgentInsightBannerState();
}

class _AgentInsightBannerState extends State<_AgentInsightBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing dot
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Opacity(
              opacity: _pulseAnim.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '📊 Advisor: ${widget.action.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppTheme.primary,
              textStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Act →'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 4 — Quick Actions Row
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final WidgetRef ref;
  const _QuickActionsRow({required this.ref});

  static const _actions = [
    (icon: Icons.qr_code_scanner, label: 'Pay'),
    (icon: Icons.swap_horiz_rounded, label: 'Transfer'),
    (icon: Icons.savings_rounded, label: 'FD'),
    (icon: Icons.trending_up_rounded, label: 'SIP'),
    (icon: Icons.account_balance_rounded, label: 'Loan'),
    (icon: Icons.grid_view_rounded, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_actions.length, (i) {
                final a = _actions[i];
                return Padding(
                  padding: EdgeInsets.only(right: i < _actions.length - 1 ? 10 : 0),
                  child: _ActionPill(icon: a.icon, label: a.label),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatefulWidget {
  final IconData icon;
  final String label;
  const _ActionPill({required this.icon, required this.label});

  @override
  State<_ActionPill> createState() => _ActionPillState();
}

class _ActionPillState extends State<_ActionPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.reverse();
  void _onTapUp(TapUpDetails _) => _ctrl.forward();
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.aiTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 5 — Recent Transactions
// ─────────────────────────────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  final List<Transaction> transactions;
  final WidgetRef ref;
  const _RecentTransactions({required this.transactions, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppTheme.primary,
                  textStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: transactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No recent transactions',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(
                      transactions.length,
                      (i) => _TxnRow(
                        txn: transactions[i],
                        showDivider: i < transactions.length - 1,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  final Transaction txn;
  final bool showDivider;
  const _TxnRow({required this.txn, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.type == 'credit';
    final color = _categoryColor(txn.category);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(txn.category),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Description + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.payee,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${txn.category} • ${_shortDate(txn.date)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Text(
                '${isCredit ? '+' : '-'} ₹${txn.amount.toStringAsFixed(0)}',
                style: AppTheme.monoStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCredit ? AppTheme.accentGreen : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.border,
            indent: 68,
          ),
      ],
    );
  }
}
