import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/pattern_engine.dart';

class EngagementScreen extends ConsumerStatefulWidget {
  const EngagementScreen({super.key});

  @override
  ConsumerState<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends ConsumerState<EngagementScreen>
    with TickerProviderStateMixin {
  // Track actions executed directly on this screen to display "Done ✅ by Agent"
  final Map<String, bool> _completedFeedActions = {};

  // Quiz state: null = not answered, true = correct, false = wrong
  int? _selectedQuizOption; // 0=A, 1=B, 2=C
  bool? _quizAnswerCorrect;

  // Animation controller for streak fire
  late AnimationController _fireController;
  late Animation<double> _fireAnimation;

  @override
  void initState() {
    super.initState();
    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fireAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _fireController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fireController.dispose();
    super.dispose();
  }

  // ───────────────────────────── dialogs ─────────────────────────────

  void _showWhyDialog(BuildContext context, String title, String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.psychology, color: AppTheme.aiTeal),
            const SizedBox(width: 8),
            Text('Why this recommendation?',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          reason,
          style: GoogleFonts.inter(
              fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showQuizSuccessDialog(BuildContext context, int newStreak) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, val, child) {
            return Transform.scale(
              scale: val,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: AppTheme.accentGreen, size: 64),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Correct Answer! 🎉',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You earned +50 SBI Coins!\nYour streak is now $newStreak 🔥',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Awesome!',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuizFailureDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, val, child) {
            return Transform.scale(
              scale: val,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cancel_rounded,
                          color: AppTheme.accentOrange, size: 64),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Oops, incorrect! 😓',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Compounding means earning interest on principal + accumulated interest. But you still earned +10 SBI Coins for participating!\nYour streak was reset to 0.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Try again tomorrow',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────────── HEADER ─────────────────────────────

  Widget _buildGradientHeader(EngagementState engagement) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B7B), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Financial Wellness',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // SBI Coins chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentOrange, Color(0xFFFFB347)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentOrange.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      '${engagement.sbiCoins} Coins',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your personalized financial health dashboard',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          // Streak pill inside header
          Row(
            children: [
              AnimatedBuilder(
                animation: _fireAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _fireAnimation.value,
                  child: const Icon(Icons.local_fire_department,
                      color: Color(0xFFFFB347), size: 20),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${engagement.streakCount}-Day Streak',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── HEALTH SCORE CARD ────────────────────────

  Widget _buildHealthScoreCard(UserProfile profile, bool hasActiveSip) {
    final kycDone = profile.kycComplete;
    final upiDone = profile.upiEnabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Score Ring (60%)
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow ring background
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentGreen
                                        .withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            CircularProgressIndicator(
                              value: profile.healthScore / 100,
                              strokeWidth: 10,
                              backgroundColor:
                                  Colors.grey.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.accentGreen),
                              strokeCap: StrokeCap.round,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${profile.healthScore}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentGreen,
                                  ),
                                ),
                                Text(
                                  '/100',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Top 20% of SBI Savers 🏆',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right: Breakdown (40%)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score Breakdown',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildMiniBreakdown(
                          label: 'KYC',
                          pts: '+30 pts',
                          done: kycDone),
                      const SizedBox(height: 8),
                      _buildMiniBreakdown(
                          label: 'SIP',
                          pts: '+40 pts',
                          done: hasActiveSip),
                      const SizedBox(height: 8),
                      _buildMiniBreakdown(
                          label: 'UPI',
                          pts: '+30 pts',
                          done: upiDone),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBreakdown({
    required String label,
    required String pts,
    required bool done,
  }) {
    return Row(
      children: [
        Text(
          done ? '✅' : '⬜',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: done
                ? AppTheme.accentGreen.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            pts,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: done ? AppTheme.accentGreen : AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── SAVER LEVEL MILESTONES ─────────────────────

  Widget _buildSaverLevelMilestones(EngagementState engagement) {
    final coins = engagement.sbiCoins;
    String tierName;
    String tierEmoji;
    String nextTierName;
    List<Color> gradientColors;
    int nextTierLimit;
    int currentTierBase;

    if (coins >= 600) {
      tierName = 'Platinum';
      tierEmoji = '💎';
      nextTierName = '';
      nextTierLimit = 600;
      currentTierBase = 600;
      gradientColors = [const Color(0xFF2196F3), const Color(0xFF3F51B5)];
    } else if (coins >= 300) {
      tierName = 'Gold';
      tierEmoji = '🥇';
      nextTierName = 'Platinum';
      nextTierLimit = 600;
      currentTierBase = 300;
      gradientColors = [const Color(0xFFFFB300), const Color(0xFFFFD700)];
    } else if (coins >= 100) {
      tierName = 'Silver';
      tierEmoji = '🥈';
      nextTierName = 'Gold';
      nextTierLimit = 300;
      currentTierBase = 100;
      gradientColors = [const Color(0xFF9E9E9E), const Color(0xFFC0C0C0)];
    } else {
      tierName = 'Bronze';
      tierEmoji = '🥉';
      nextTierName = 'Silver';
      nextTierLimit = 100;
      currentTierBase = 0;
      gradientColors = [const Color(0xFFB57C50), const Color(0xFFCD7F32)];
    }

    final range = nextTierLimit - currentTierBase;
    final progress =
        range > 0 ? ((coins - currentTierBase) / range).clamp(0.0, 1.0) : 1.0;
    final coinsNeeded = nextTierLimit - coins;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Text(
                  'SAVER LEVEL',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                Text(
                  '$coins coins',
                  style: AppTheme.monoStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Level name + emoji
            Row(
              children: [
                Text(
                  tierEmoji,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      coins >= 600
                          ? 'Ultimate Platinum Level! 🎉'
                          : '$coinsNeeded coins to $nextTierName',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Glowing gradient progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ShaderMask(
                shaderCallback: (Rect bounds) => LinearGradient(
                  colors: gradientColors,
                ).createShader(bounds),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Milestone row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final item in [
                  ('🥉', 'Bronze', 0),
                  ('🥈', 'Silver', 100),
                  ('🥇', 'Gold', 300),
                  ('💎', 'Plat', 600),
                ])
                  Column(
                    children: [
                      Text(item.$1,
                          style: TextStyle(
                              fontSize: 14,
                              color: coins >= item.$3
                                  ? null
                                  : Colors.grey.shade400)),
                      Text(
                        item.$2,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: coins >= item.$3
                              ? AppTheme.textPrimary
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────── DAILY QUIZ ─────────────────────────────

  Widget _buildDailyQuiz(EngagementState engagement) {
    bool takenToday = false;
    if (engagement.lastQuizTakenTimestamp > 0) {
      final quizDate =
          DateTime.fromMillisecondsSinceEpoch(engagement.lastQuizTakenTimestamp);
      final now = DateTime.now();
      takenToday = quizDate.year == now.year &&
          quizDate.month == now.month &&
          quizDate.day == now.day;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), AppTheme.primary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.quiz_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily Financial Quiz',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (takenToday)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check,
                            color: AppTheme.accentGreen, size: 12),
                        const SizedBox(width: 4),
                        Text('Done',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentGreen,
                            )),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (takenToday) ...[
              Center(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _fireAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _fireAnimation.value,
                        child: const Text('🔥',
                            style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Streak: ${engagement.quizStreak} 🔥  Come back tomorrow!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You\'re on fire! Keep going.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Which of the following describes the power of compounding interest?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _buildPremiumQuizOption(
                index: 0,
                label: 'A) Earning interest only on original principal',
                isCorrect: false,
              ),
              const SizedBox(height: 8),
              _buildPremiumQuizOption(
                index: 1,
                label:
                    'B) Earning interest on principal + accumulated interest',
                isCorrect: true,
              ),
              const SizedBox(height: 8),
              _buildPremiumQuizOption(
                index: 2,
                label: 'C) Paying off debt early',
                isCorrect: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumQuizOption({
    required int index,
    required String label,
    required bool isCorrect,
  }) {
    final isSelected = _selectedQuizOption == index;
    final answered = _selectedQuizOption != null;

    Color bgColor = Colors.white;
    Color borderColor = AppTheme.primary.withValues(alpha: 0.25);
    Color textColor = AppTheme.textPrimary;
    Widget? trailingIcon;

    if (isSelected && _quizAnswerCorrect == true) {
      bgColor = AppTheme.accentGreen.withValues(alpha: 0.12);
      borderColor = AppTheme.accentGreen;
      textColor = AppTheme.accentGreen;
      trailingIcon =
          const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 18);
    } else if (isSelected && _quizAnswerCorrect == false) {
      bgColor = const Color(0xFFFFEBEB);
      borderColor = Colors.redAccent;
      textColor = Colors.redAccent;
      trailingIcon =
          const Icon(Icons.cancel, color: Colors.redAccent, size: 18);
    } else if (answered && isCorrect) {
      // Show correct answer after wrong pick
      bgColor = AppTheme.accentGreen.withValues(alpha: 0.06);
      borderColor = AppTheme.accentGreen.withValues(alpha: 0.4);
    }

    return GestureDetector(
      onTap: answered
          ? null
          : () {
              setState(() {
                _selectedQuizOption = index;
                _quizAnswerCorrect = isCorrect;
              });
              if (isCorrect) {
                ref.read(engagementProvider.notifier).takeQuiz(true);
                final updatedStreak =
                    ref.read(engagementProvider).quizStreak;
                _showQuizSuccessDialog(context, updatedStreak);
              } else {
                ref.read(engagementProvider.notifier).takeQuiz(false);
                _showQuizFailureDialog(context);
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── AI STORY BANNER ─────────────────────────

  Widget _buildAiStoryBanner(String aiStoryContent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.aiTeal.withValues(alpha: 0.08),
              AppTheme.primary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppTheme.aiTeal.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.aiTeal, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                aiStoryContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────── FEED CARDS ─────────────────────────────

  Widget _buildFeedCard({
    required String key,
    required String title,
    required String subtitle,
    required String whyReason,
    required String actionLabel,
    required Color accentColor,
    required IconData iconData,
    required VoidCallback onExecuted,
  }) {
    final isDone = _completedFeedActions[key] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: accentColor, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDone ? AppTheme.accentGreen : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action area
              if (isDone)
                Text(
                  'Done ✅',
                  style: GoogleFonts.inter(
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                )
              else
                Column(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: accentColor.withValues(alpha: 0.1),
                        foregroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        onExecuted();
                        setState(() {
                          _completedFeedActions[key] = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$title completed successfully!'),
                            backgroundColor: AppTheme.accentGreen,
                          ),
                        );
                      },
                      child: Text(
                        actionLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showWhyDialog(context, title, whyReason),
                      child: Text(
                        'Why?',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────── BUILD ───────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final txs = ref.watch(transactionsProvider);
    final engagement = ref.watch(engagementProvider);
    final sips = ref.watch(sipListProvider);
    final hasActiveSip = sips.any((s) => s.status == 'active');

    // Run PatternEngine
    final signals = PatternEngine.analyze(profile, txs);

    // Calculate dynamic spending breakdown for Donut Chart
    final debits = txs.where((t) => t.type == 'debit').toList();
    final Map<String, double> categoryTotals = {};
    double totalDebitAmount = 0.0;
    for (var tx in debits) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0.0) + tx.amount;
      totalDebitAmount += tx.amount;
    }

    // Build chart section list
    final List<PieChartSectionData> chartSections = [];
    final List<Color> sectionColors = [
      AppTheme.primary,
      AppTheme.accentOrange,
      AppTheme.accentGreen,
      Colors.indigo,
      Colors.teal,
    ];

    int colorIdx = 0;
    categoryTotals.forEach((cat, val) {
      final color = sectionColors[colorIdx % sectionColors.length];
      chartSections.add(
        PieChartSectionData(
          color: color,
          value: val,
          title:
              '${(val / totalDebitAmount * 100).toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIdx++;
    });

    // Dynamic AI Story Text
    String aiStoryContent =
        'Aapka account Rohan fresh state mein hai. Start spending using UPI to build your personalized financial story!';
    if (profile.name == 'Sourabh') {
      final recentSalary = txs.firstWhere(
          (t) => t.category == 'Salary',
          orElse: () => txs.first);
      aiStoryContent =
          'Namaste Sourabh! TCS salary crediting of ₹${recentSalary.amount.toStringAsFixed(0)} was logged Jun 20. Rent accounts for ${((categoryTotals['Rent'] ?? 0.0) / totalDebitAmount * 100).toStringAsFixed(0)}% of expenditure. SBI Bluechip SIP was missed this month. Idle savings of ₹${profile.balance.toStringAsFixed(0)} can generate higher yield.';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Gradient Header ──
          _buildGradientHeader(engagement),

          const SizedBox(height: 4),

          // ── 2. AI Story Banner ──
          _buildAiStoryBanner(aiStoryContent),

          // ── 3. Health Score Card ──
          _buildHealthScoreCard(profile, hasActiveSip),

          // ── 4. Saver Level Milestones ──
          _buildSaverLevelMilestones(engagement),

          // ── 5. Daily Quiz ──
          _buildDailyQuiz(engagement),

          // ── 6. Donut Spending Breakdown Chart ──
          if (debits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.donut_small_rounded,
                              color: AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Monthly Expense Breakdown',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: PieChart(
                            PieChartData(
                              sections: chartSections,
                              centerSpaceRadius: 30,
                              sectionsSpace: 2,
                              startDegreeOffset: -90,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                categoryTotals.entries.map((entry) {
                              final colorIdxLocal =
                                  categoryTotals.keys.toList().indexOf(entry.key);
                              final color = sectionColors[
                                  colorIdxLocal % sectionColors.length];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius:
                                            BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      '₹${entry.value.toStringAsFixed(0)}',
                                      style: AppTheme.monoStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── 7. Agent Noticed Feed ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.offline_bolt,
                    color: AppTheme.aiTeal, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Agent Noticed Feed',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          if (profile.name == 'Sourabh') ...[
            if (signals.missedRecurring)
              _buildFeedCard(
                key: 'feed_sip',
                title: 'SIP Missed Alert',
                subtitle: 'June SBI Bluechip SIP missed. Restore now.',
                whyReason:
                    'PatternEngine detected you paid ₹5,000 for SBI Mutual Fund in May, but did not have a corresponding debit in June.',
                actionLabel: 'Resume SIP',
                accentColor: AppTheme.accentOrange,
                iconData: Icons.replay_circle_filled,
                onExecuted: () {
                  ref
                      .read(servicesProvider.notifier)
                      .activateService('srv_sip');
                  ref.read(engagementProvider.notifier).addCoins(40);
                },
              ),
            if (signals.idleBalance)
              _buildFeedCard(
                key: 'feed_fd',
                title: 'Idle Cash Advisory',
                subtitle:
                    'Move ₹50,000 idle savings cash to Fixed Deposit (7.2%).',
                whyReason:
                    'Your current balance is ₹${profile.balance.toStringAsFixed(0)}, which is greater than 3x your average monthly spending. Idle funds lose real value to inflation. A safe Fixed Deposit gives guaranteed yield.',
                actionLabel: 'Open FD',
                accentColor: AppTheme.primary,
                iconData: Icons.account_balance,
                onExecuted: () {
                  ref
                      .read(servicesProvider.notifier)
                      .activateService('srv_fd');
                  ref
                      .read(userProfileProvider.notifier)
                      .updateBalance(-50000);
                  ref.read(transactionsProvider.notifier).addTransaction(
                        Transaction(
                          id: 'tx_fd_${DateTime.now().millisecondsSinceEpoch}',
                          amount: 50000.0,
                          payee: 'SBI Fixed Deposit (AI)',
                          category: 'Investment',
                          date: DateTime.now(),
                          type: 'debit',
                        ),
                      );
                  ref.read(engagementProvider.notifier).addCoins(50);
                },
              ),
            if (signals.salaryNoSave)
              _buildFeedCard(
                key: 'feed_save',
                title: 'Salary Boost Nudge',
                subtitle:
                    'Salary received! Auto-save ₹500 to Dream Car Goal.',
                whyReason:
                    'Salary credited recently. Sticking to automatic investments on payday improves wealth building probability.',
                actionLabel: 'Boost Goal',
                accentColor: AppTheme.accentGreen,
                iconData: Icons.rocket_launch_rounded,
                onExecuted: () {
                  ref
                      .read(goalsProvider.notifier)
                      .boostGoal('goal_01', 500);
                  ref
                      .read(userProfileProvider.notifier)
                      .updateBalance(-500);
                  ref.read(transactionsProvider.notifier).addTransaction(
                        Transaction(
                          id:
                              'tx_boost_feed_${DateTime.now().millisecondsSinceEpoch}',
                          amount: 500.0,
                          payee: 'Goal Boost: Dream Car',
                          category: 'Investment',
                          date: DateTime.now(),
                          type: 'debit',
                        ),
                      );
                  ref.read(engagementProvider.notifier).addCoins(20);
                },
              ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No notices from agent yet. Onboard Rohan first to generate insights.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
