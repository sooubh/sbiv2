import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/voice/voice_service.dart';
import 'package:sbiv2/ai/voice/voice_state.dart';
import 'package:sbiv2/features/agent/widgets/ai_avatar.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/agent/agent_orchestrator.dart';
import 'package:sbiv2/features/products/money_management_screen.dart';
import 'package:sbiv2/features/products/fd_screen.dart';
import 'package:sbiv2/features/products/loans_screen.dart';
import 'package:sbiv2/features/products/investments_screen.dart';

class VoiceCopilotOverlay extends ConsumerStatefulWidget {
  const VoiceCopilotOverlay({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'VoiceCopilotOverlay',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: const VoiceCopilotOverlay(),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  ConsumerState<VoiceCopilotOverlay> createState() =>
      _VoiceCopilotOverlayState();
}

class _VoiceCopilotOverlayState extends ConsumerState<VoiceCopilotOverlay> {
  String _recognizedText = '';
  String? _activeAgentName;
  String? _activeAgentEmoji;
  Color _activeAgentColor = AppTheme.aiTeal;
  final TextEditingController _textController = TextEditingController();
  bool _showTextInput = false;

  static const _chips = [
    'Check budget',
    'Open FD',
    'Pay EMI',
    'Health score',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voiceSvc = ref.read(voiceServiceProvider);
      voiceSvc.setCustomCallback((text) {
        if (!mounted) return;
        setState(() => _recognizedText = text);
        _processCommand(text);
      });
      voiceSvc.startListening();
    });
  }

  @override
  void dispose() {
    final voiceSvc = ref.read(voiceServiceProvider);
    voiceSvc.setCustomCallback(null);
    voiceSvc.cancelListening();
    _textController.dispose();
    super.dispose();
  }

  void _updateAgentBanner(ActiveAgent agent, String name, String emoji) {
    if (!mounted) return;
    setState(() {
      _activeAgentName = name;
      _activeAgentEmoji = emoji;
      switch (agent) {
        case ActiveAgent.advisor:
          _activeAgentColor = const Color(0xFF10B981);
          break;
        case ActiveAgent.transaction:
          _activeAgentColor = const Color(0xFF3B82F6);
          break;
        case ActiveAgent.compliance:
          _activeAgentColor = const Color(0xFFF59E0B);
          break;
        case ActiveAgent.none:
          _activeAgentColor = AppTheme.aiTeal;
          break;
      }
    });
  }

  void _processCommand(String text) async {
    final cmd = text.toLowerCase().trim();
    if (cmd.isEmpty) return;

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final voiceSvc = ref.read(voiceServiceProvider);
    final nav = ref.read(currentNavIndexProvider.notifier);

    if (cmd.contains('budget') ||
        cmd.contains('spent') ||
        cmd.contains('money management')) {
      _updateAgentBanner(ActiveAgent.transaction, 'Transaction Agent', '💳');
      nav.state = 1;
      Navigator.pop(context);
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const MoneyManagementScreen()));
      voiceSvc.speak('Opening your budget and money management dashboard.');
      return;
    }

    if (cmd.contains('fd') ||
        cmd.contains('fixed deposit') ||
        cmd.contains('deposit')) {
      _updateAgentBanner(ActiveAgent.advisor, 'Financial Advisor', '📊');
      nav.state = 1;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FDScreen()));
      final amountMatch = RegExp(r'\d+').firstMatch(cmd);
      voiceSvc.speak(amountMatch != null
          ? 'Navigating to Fixed Deposits. Deposit of ₹${amountMatch.group(0)} ready.'
          : 'Opening Fixed Deposits.');
      return;
    }

    if (cmd.contains('loan') ||
        cmd.contains('prepay') ||
        cmd.contains('emi')) {
      _updateAgentBanner(ActiveAgent.transaction, 'Transaction Agent', '💳');
      nav.state = 1;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoansScreen()));
      voiceSvc.speak('Opening your Loan and EMI dashboard.');
      return;
    }

    if (cmd.contains('sip') ||
        cmd.contains('mutual fund') ||
        cmd.contains('investment')) {
      _updateAgentBanner(ActiveAgent.advisor, 'Financial Advisor', '📊');
      nav.state = 1;
      Navigator.pop(context);
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const InvestmentsScreen()));
      final amountMatch = RegExp(r'\d+').firstMatch(cmd);
      voiceSvc.speak(amountMatch != null
          ? 'Navigating to Mutual Funds. SIP of ₹${amountMatch.group(0)} ready.'
          : 'Opening Mutual Fund investments.');
      return;
    }

    if (cmd.contains('health') ||
        cmd.contains('score') ||
        cmd.contains('quiz') ||
        cmd.contains('streak') ||
        cmd.contains('coin')) {
      _updateAgentBanner(ActiveAgent.advisor, 'Financial Advisor', '📊');
      nav.state = 2;
      Navigator.pop(context);
      voiceSvc.speak('Navigating to your Financial Health dashboard.');
      return;
    }

    // Default fallback: AI Chat
    _updateAgentBanner(ActiveAgent.advisor, 'Financial Advisor', '📊');
    nav.state = 3;
    Navigator.pop(context);
    ref.read(aiCoordinatorProvider.notifier).sendMessage(text);
    voiceSvc.speak('Asking YONO Assistant: $text');
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceStateProvider);
    final status = voiceState.status;

    String instruction = "Say: 'show budget', 'open FD', 'pay EMI'";
    String statusLabel = 'Tap mic to speak';
    Color statusColor = AppTheme.aiTeal;

    if (status == VoiceStatus.listening) {
      statusLabel = 'Listening...';
      statusColor = Colors.blue;
      instruction = 'Speak your request clearly...';
    } else if (status == VoiceStatus.processing) {
      statusLabel = 'Processing...';
      statusColor = AppTheme.accentOrange;
      instruction = 'Analyzing voice command...';
    } else if (status == VoiceStatus.speaking) {
      statusLabel = 'Responding...';
      statusColor = AppTheme.accentGreen;
      instruction = 'Agent is responding...';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AppTheme.aiTeal.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _showTextInput = !_showTextInput);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _showTextInput
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.keyboard_alt_outlined,
                          size: 18,
                          color: _showTextInput
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: AppTheme.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Agent attribution banner (shows when an agent is active)
            if (_activeAgentName != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _activeAgentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _activeAgentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      _activeAgentEmoji ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_activeAgentName is handling this',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _activeAgentColor,
                      ),
                    ),
                  ],
                ),
              ),

            // AI Avatar
            const AIAvatar(size: 110),
            const SizedBox(height: 16),

            // Instruction text
            Text(
              instruction,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Voice text preview
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              alignment: Alignment.center,
              child: Text(
                _recognizedText.isEmpty
                    ? (status == VoiceStatus.listening
                        ? 'Speak now...'
                        : 'Listening active')
                    : '"$_recognizedText"',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _recognizedText.isEmpty
                      ? Colors.grey
                      : AppTheme.textPrimary,
                  fontStyle: _recognizedText.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: _chips
                  .map(
                    (chip) => GestureDetector(
                      onTap: () {
                        setState(() => _recognizedText = chip);
                        _processCommand(chip);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          chip,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),

            // Text input (shown when keyboard icon tapped)
            if (_showTextInput)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        autofocus: true,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Type your request...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.background,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() => _recognizedText = val.trim());
                            _processCommand(val.trim());
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final val = _textController.text.trim();
                        if (val.isNotEmpty) {
                          setState(() => _recognizedText = val);
                          _processCommand(val);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

            // Mic button
            GestureDetector(
              onTap: () {
                final voiceSvc = ref.read(voiceServiceProvider);
                if (status == VoiceStatus.listening) {
                  voiceSvc.cancelListening();
                } else if (status != VoiceStatus.speaking &&
                    status != VoiceStatus.processing) {
                  voiceSvc.startListening();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status == VoiceStatus.listening
                      ? Colors.red.withValues(alpha: 0.1)
                      : AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: status == VoiceStatus.listening
                        ? Colors.red
                        : AppTheme.primary,
                    width: 2,
                  ),
                ),
                child: Icon(
                  status == VoiceStatus.listening ? Icons.stop : Icons.mic,
                  color: status == VoiceStatus.listening
                      ? Colors.red
                      : AppTheme.primary,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
