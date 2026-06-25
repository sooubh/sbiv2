import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/voice/voice_service.dart';
import 'package:sbiv2/ai/voice/voice_state.dart';
import 'package:sbiv2/ai/behavior/next_best_action.dart';
import 'package:sbiv2/ai/behavior/proactive_agent_engine.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/features/agent/models/timeline_entry.dart';
import 'package:sbiv2/features/agent/widgets/ai_avatar.dart';

// ── Typing Indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Small AI avatar circle
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.aiTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1B7B),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topLeft: Radius.circular(4),
                ),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      // Stagger each dot by 200ms offset
                      final double start = i * 0.25;
                      final double end = start + 0.5;
                      final double opacity = _controller.value >= start &&
                              _controller.value <= end
                          ? ((_controller.value - start) / 0.25).clamp(0.0, 1.0)
                          : _controller.value > end
                              ? 1.0 - ((_controller.value - end) / 0.25).clamp(0.0, 1.0)
                              : 0.3;
                      return Container(
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: opacity.clamp(0.3, 1.0)),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main Screen ───────────────────────────────────────────────────────────────
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceServiceProvider).initialize();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitMessage(String text) {
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(aiCoordinatorProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AIAvatar(size: 80),
              const SizedBox(height: 16),
              Text(
                'How can I help you today?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask me to transfer money, open an FD, prepay loans, or check your balance.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Premium AppBar ────────────────────────────────────────────────────────
  Widget _buildPremiumAppBar(String currentLang, bool handsFreeEnabled) {
    return Container(
      color: AppTheme.primaryDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 8,
        right: 8,
        bottom: 10,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Small AI Avatar
          ClipOval(
            child: SizedBox(
              width: 32,
              height: 32,
              child: const AIAvatar(size: 32),
            ),
          ),
          const SizedBox(width: 10),
          // Title Column
          Expanded(
            child: Text(
              'YONO AI',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Language toggle chips (EN / हिं)
          _buildLangChip('EN', 'en', currentLang),
          const SizedBox(width: 6),
          _buildLangChip('हिं', 'hi', currentLang),
          const SizedBox(width: 2),
          // Hands-Free toggle icon
          IconButton(
            onPressed: () {
              ref.read(handsFreeVoiceProvider.notifier).update((s) => !s);
            },
            icon: Icon(
              Icons.hearing,
              color: handsFreeEnabled ? AppTheme.aiTeal : Colors.white,
              size: 22,
            ),
            tooltip: 'Hands-Free Mode',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String label, String langCode, String currentLang) {
    final isActive = currentLang == langCode;
    return GestureDetector(
      onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ── Shortcut Action Chips Bar ─────────────────────────────────────────────
  Widget _buildShortcutChipsBar() {
    final chips = [
      {'label': 'Prepay Home Loan', 'text': 'Prepay Home Loan'},
      {'label': 'Check Health Score', 'text': 'Check Health Score'},
      {'label': 'Resume SIP', 'text': 'Resume SIP'},
      {'label': 'Check Balance', 'text': 'mera account balance check karo'},
      {'label': 'Open FD', 'text': 'meri idle savings se Fixed Deposit khol do'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: chips.map((chip) {
            return GestureDetector(
              onTap: () => _submitMessage(chip['text']!),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  chip['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(bankingChatProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final handsFreeEnabled = ref.watch(handsFreeVoiceProvider);
    final coordinator = ref.watch(aiCoordinatorProvider);
    final isThinking = coordinator.isThinking;

    // Auto-scroll when messages update
    ref.listen(bankingChatProvider, (prev, next) {
      _scrollToBottom();
    });
    ref.listen(aiCoordinatorProvider, (prev, next) {
      if (next.isThinking) _scrollToBottom();
    });

    final showHelpers = messages.isEmpty;

    return Column(
      children: [
        // ── Premium AppBar ──────────────────────────────────────────────────
        _buildPremiumAppBar(currentLang, handsFreeEnabled),

        if (showHelpers) ...[
          // ── Shortcut Action Chips Bar ─────────────────────────────────────
          _buildShortcutChipsBar(),

          // ── Proactive suggestion banner ───────────────────────────────────
          _buildProactiveBanner(context, ref),
        ],

        // ── Chat Message History ────────────────────────────────────────────
        Expanded(
          child: showHelpers
              ? _buildEmptyState(context, ref)
              : ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  // Extra item for typing indicator
                  itemCount: messages.length + (isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Typing indicator as last item
                    if (isThinking && index == messages.length) {
                      return const _TypingIndicator();
                    }
                    final msg = messages[index];
                    if (msg.sender == 'system') {
                      if (msg.toolStatus == 'pending') {
                        return _buildSystemLog(msg);
                      }
                      return const SizedBox.shrink();
                    }
                    if (msg.sender == 'tool') {
                      return _buildToolResultChip(msg.text);
                    }
                    return _buildChatBubble(msg.text, msg.sender);
                  },
                ),
        ),

        // Error display for Voice status
        Consumer(
          builder: (context, ref, _) {
            final voice = ref.watch(voiceStateProvider);
            if (voice.status == VoiceStatus.error) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedMicOff01,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        voice.error ?? 'Voice unavailable. Using text input.',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.red),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(voiceStateProvider.notifier).clearError(),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        if (handsFreeEnabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              "• Hands-free mode: speak when the agent stops",
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.aiTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // ── Premium Input Bar ─────────────────────────────────────────────────
        Consumer(
          builder: (context, ref, _) {
            final voice = ref.watch(voiceStateProvider);
            final isListening = voice.status == VoiceStatus.listening;
            final isSpeaking = voice.status == VoiceStatus.speaking;
            final sttAvailable = voice.sttAvailable;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  // Mic / Speak / Stop button
                  if (sttAvailable)
                    GestureDetector(
                      onTap: () {
                        final svc = ref.read(voiceServiceProvider);
                        if (isListening) {
                          svc.cancelListening();
                        } else if (isSpeaking) {
                          svc.stopSpeaking();
                        } else {
                          svc.startListening();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isListening
                              ? Colors.red.shade50
                              : isSpeaking
                                  ? AppTheme.accentOrange.withValues(alpha: 0.1)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isListening
                              ? Icons.stop
                              : isSpeaking
                                  ? Icons.volume_up
                                  : Icons.mic,
                          color: isListening
                              ? Colors.red
                              : isSpeaking
                                  ? AppTheme.accentOrange
                                  : AppTheme.aiTeal,
                          size: 24,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 4),

                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (val) => _submitMessage(val.trim()),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask YONO AI anything...',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button — gradient when active, grayed when empty
                  GestureDetector(
                    onTap: _hasText
                        ? () => _submitMessage(_textController.text.trim())
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _hasText
                            ? const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.aiTeal],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  AppTheme.border,
                                  AppTheme.border,
                                ],
                              ),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Premium Message Bubble ────────────────────────────────────────────────
  Widget _buildChatBubble(String text, String sender) {
    final isUser = sender == 'user';
    // Rough timestamp display
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Agent bubble
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Small gradient AI avatar
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.aiTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Bubble
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1B7B),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    topLeft: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🤖 YONO AI',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.aiTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tool Approval Card ────────────────────────────────────────────────────
  Widget _buildSystemLog(ChatMessage msg) {
    final toolCall = msg.toolCall;
    final toolName = toolCall?['name'] ?? '';
    final args = toolCall?['args'] ?? {};
    final status = msg.toolStatus;

    if (status == 'pending') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.aiTeal.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtle gradient top-edge accent strip
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: AppTheme.aiTeal, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "Action Confirmation Required",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "The agent wants to execute a transaction on your behalf:",
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        msg.text,
                        style: AppTheme.monoStyle(fontSize: 11, color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => ref
                              .read(aiCoordinatorProvider.notifier)
                              .confirmToolCall(msg.toolCallId!, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text("Deny",
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(aiCoordinatorProvider.notifier)
                              .confirmToolCall(msg.toolCallId!, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.aiTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text("Approve",
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isApproved
            ? AppTheme.aiTeal.withValues(alpha: 0.08)
            : isRejected
                ? Colors.red.withValues(alpha: 0.05)
                : AppTheme.aiTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApproved
              ? AppTheme.aiTeal.withValues(alpha: 0.3)
              : isRejected
                  ? Colors.red.withValues(alpha: 0.2)
                  : AppTheme.aiTeal.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: isApproved
                ? HugeIcons.strokeRoundedSecurityCheck
                : isRejected
                    ? HugeIcons.strokeRoundedCancelCircle
                    : HugeIcons.strokeRoundedBrain,
            color: isApproved
                ? AppTheme.aiTeal
                : isRejected
                    ? Colors.red
                    : AppTheme.aiTeal,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApproved
                      ? 'Approved Tool Action: $toolName'
                      : isRejected
                          ? 'Cancelled Tool Action: $toolName'
                          : 'Reasoning & Tool Call: $toolName',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isApproved
                        ? AppTheme.aiTeal
                        : isRejected
                            ? Colors.red
                            : AppTheme.aiTeal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  args.toString(),
                  style: AppTheme.monoStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolResultChip(String text) {
    final isSuccess = text.contains('✅');
    final isError = text.contains('❌');
    final displayText =
        text.replaceAll('✅', '').replaceAll('❌', '').trim();
    final color = isSuccess
        ? AppTheme.accentGreen
        : (isError ? Colors.red : AppTheme.textSecondary);
    final icon = isSuccess
        ? Icons.check_circle_outline
        : (isError ? Icons.error_outline : Icons.info_outline);
    final bgColor = isSuccess
        ? AppTheme.accentGreen.withValues(alpha: 0.1)
        : (isError
            ? Colors.red.withValues(alpha: 0.1)
            : AppTheme.background);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              displayText,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProactiveBanner(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final txs = ref.watch(transactionsProvider);
    final goals = ref.watch(goalsProvider);
    final recs = ref.watch(recommendationsProvider);
    final memory = ref.watch(agentMemoryProvider);

    final action = ProactiveAgentEngine.determineNextBestAction(
      profile: profile,
      transactions: txs,
      goals: goals,
      memory: memory,
      recommendations: recs,
    );

    if (action.type == NextBestActionType.healthSummary) {
      return const SizedBox.shrink();
    }

    Color bannerColor = AppTheme.aiTeal;
    if (action.type == NextBestActionType.kyc ||
        action.type == NextBestActionType.lowBalance) {
      bannerColor = AppTheme.accentOrange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        border: Border(
            bottom: BorderSide(
                color: bannerColor.withValues(alpha: 0.3), width: 1)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedIdea,
            color: bannerColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Suggestion: ${action.title}",
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                ),
                Text(
                  "Why: ${action.aiReason}",
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: bannerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(timelineProvider.notifier).log(
                    type: TimelineEntryType.toolCompleted,
                    title: 'Accepted via Chat: ${action.title}',
                    description:
                        'User initiated solution directly from the chat banner.',
                    status: TimelineEntryStatus.success,
                  );

              ref
                  .read(agentMemoryProvider.notifier)
                  .updateCooldown(action.type.name,
                      DateTime.now().millisecondsSinceEpoch);

              if (action.type == NextBestActionType.kyc) {
                ref.read(currentNavIndexProvider.notifier).state = 1;
              } else if (action.type == NextBestActionType.healthSummary) {
                ref.read(currentNavIndexProvider.notifier).state = 3;
              } else {
                switch (action.type) {
                  case NextBestActionType.sip:
                    _submitMessage("Resume SIP");
                    break;
                  case NextBestActionType.lowBalance:
                    _submitMessage("Check Balance");
                    break;
                  case NextBestActionType.fd:
                    _submitMessage("Open FD");
                    break;
                  case NextBestActionType.salarySave:
                    _submitMessage("Boost Goal");
                    break;
                  case NextBestActionType.spendingSpike:
                    _submitMessage("Review spending spike");
                    break;
                  case NextBestActionType.goalNudge:
                    _submitMessage("Boost goal");
                    break;
                  default:
                    break;
                }
              }
            },
            child: Text(
              "Start",
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
