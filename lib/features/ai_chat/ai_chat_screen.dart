import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/engine/pattern_engine.dart';
import 'package:sbiv2/ai/voice/voice_service.dart';
import 'package:sbiv2/ai/voice/voice_state.dart';
import 'package:sbiv2/features/agent/widgets/agent_timeline.dart';
import 'package:sbiv2/ai/behavior/next_best_action.dart';
import 'package:sbiv2/ai/behavior/proactive_agent_engine.dart';
import 'package:sbiv2/ai/memory/agent_memory.dart';
import 'package:sbiv2/features/agent/models/timeline_entry.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialise VoiceService after first frame so Riverpod ref is ready.
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

  void _showExplainabilitySheet(BuildContext context) {
    final profile = ref.read(userProfileProvider);
    final txs = ref.read(transactionsProvider);
    final signals = PatternEngine.analyze(profile, txs);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedBrain,
                    color: AppTheme.aiTeal,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Decision',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Processing:',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Parses intent (e.g. transfers, goals, investments).\n'
                '2. Evaluates context (checks savings buffer).\n'
                '3. Executes tool actions autonomously.',
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Pattern Context:',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  signals.summaryForAgent,
                  style: AppTheme.monoStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(bankingChatProvider);

    // Auto-scroll when messages update
    ref.listen(bankingChatProvider, (prev, next) {
      _scrollToBottom();
    });

    final quickChips = [
      {'label': '💸 Send Money', 'text': 'mom ko 2000 bhej do'},
      {'label': '🏦 Open FD', 'text': 'meri idle savings se Fixed Deposit khol do'},
      {'label': '💳 Check Balance', 'text': 'mera account balance check karo'},
      {'label': '🏥 Coach Mode', 'text': 'mera financial health kaisa hai?'},
    ];

    return Column(
      children: [
        // Screen Header with "Why did agent do this?" Floating Info Button
        Container(
          width: double.infinity,
          color: AppTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.aiTeal.withValues(alpha: 0.2),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedBubbleChat,
                  color: AppTheme.aiTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Chat',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Zero-tap Assistant',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Floating Explainability Button
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedHelpCircle,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Why did agent do this?',
                onPressed: () => _showExplainabilitySheet(context),
              ),
            ],
          ),
        ),

        // Proactive suggestion banner
        _buildProactiveBanner(context, ref),

        // Chat Message History
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              if (msg.sender == 'system') {
                if (msg.toolStatus == 'pending') {
                  return _buildSystemLog(msg);
                }
                return const SizedBox.shrink();
              }
              if (msg.sender == 'tool') {
                return const SizedBox.shrink();
              }
              final isUser = msg.sender == 'user';
              return _buildChatBubble(msg.text, isUser);
            },
          ),
        ),

        // Floating Chip Suggestion Row
        Container(
          height: 48,
          color: AppTheme.background,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: quickChips.length,
            itemBuilder: (context, index) {
              final chip = quickChips[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ActionChip(
                  label: Text(
                    chip['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.border),
                  onPressed: () {
                    _submitMessage(chip['text']!);
                  },
                ),
              );
            },
          ),
        ),

        // ── Collapsible Agent Timeline ───────────────────────────────────────
        Consumer(
          builder: (context, ref, _) {
            final entries = ref.watch(timelineProvider);
            return Theme(
              // Remove ExpansionTile's default divider lines
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                backgroundColor: AppTheme.background,
                collapsedBackgroundColor: AppTheme.background,
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedClock01,
                  color: AppTheme.aiTeal,
                  size: 18,
                ),
                title: Row(
                  children: [
                    Text(
                      'Timeline',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.aiTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entries.length}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.aiTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  AgentTimeline(entries: entries),
                ],
              ),
            );
          },
        ),

        // ── TTS Speaking Banner ──────────────────────────────────────────────
        Consumer(
          builder: (context, ref, _) {
            final voice = ref.watch(voiceStateProvider);
            final isSpeaking = voice.status == VoiceStatus.speaking;
            final isPaused = voice.isPaused;
            final hasError = voice.status == VoiceStatus.error;

            if (!isSpeaking && !hasError) return const SizedBox.shrink();

            if (hasError) {
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

            // Speaking state pill
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.aiTeal.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedVolumeUp,
                    color: AppTheme.aiTeal,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPaused ? 'Paused' : 'Speaking…',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.aiTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Pause / Resume toggle
                  GestureDetector(
                    onTap: () {
                      final svc = ref.read(voiceServiceProvider);
                      if (isPaused) {
                        svc.resumeSpeaking();
                      } else {
                        svc.pauseSpeaking();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.aiTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPaused ? 'Resume' : 'Pause',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.aiTeal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Stop speaking
                  GestureDetector(
                    onTap: () => ref.read(voiceServiceProvider).stopSpeaking(),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedStopCircle,
                      color: AppTheme.aiTeal,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // ── Input Bar ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final voice = ref.watch(voiceStateProvider);
              final isListening = voice.status == VoiceStatus.listening;
              final isSpeaking = voice.status == VoiceStatus.speaking;
              final sttAvailable = voice.sttAvailable;

              return Row(
                children: [
                  // ── Mic button ──────────────────────────────────────────
                  if (sttAvailable)
                    GestureDetector(
                      onTap: () {
                        final svc = ref.read(voiceServiceProvider);
                        if (isListening) {
                          svc.cancelListening();
                        } else if (!isSpeaking) {
                          svc.startListening();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isListening
                              ? Colors.red.shade50
                              : AppTheme.background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isListening
                                ? Colors.red
                                : AppTheme.border,
                          ),
                        ),
                        child: HugeIcon(
                          icon: isListening ? HugeIcons.strokeRoundedMic01 : HugeIcons.strokeRoundedMicOff01,
                          color: isListening ? Colors.red : AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),

                  // ── Text Field ──────────────────────────────────────────
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (val) => _submitMessage(val.trim()),
                      decoration: InputDecoration(
                        hintText: sttAvailable
                            ? 'Type or tap mic to speak…'
                            : 'Type a message…',
                        hintStyle: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Send button ─────────────────────────────────────────
                  GestureDetector(
                    onTap: () => _submitMessage(_textController.text.trim()),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedSent,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.primaryLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isUser ? Colors.white : AppTheme.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemLog(ChatMessage msg) {
    final toolCall = msg.toolCall;
    final toolName = toolCall?['name'] ?? '';
    final args = toolCall?['args'] ?? {};
    final status = msg.toolStatus;

    if (status == 'pending') {
      return Container(
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedSecurityCheck,
                  color: AppTheme.aiTeal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Confirm Action',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'The Agent requests permission for:',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Action: $toolName',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...args.entries.map((e) => Text(
                        '${e.key}: ${e.value}',
                        style: AppTheme.monoStyle(fontSize: 11, color: AppTheme.textPrimary),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    ref.read(aiCoordinatorProvider.notifier).confirmToolCall(msg.toolCallId!, false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    ref.read(aiCoordinatorProvider.notifier).confirmToolCall(msg.toolCallId!, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.aiTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            )
          ],
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

  // ignore: unused_element
  Widget _buildToolResult(String text, Map<String, dynamic>? toolCall) {
    final output = toolCall?['output'] ?? {};
    final status = output['status'] ?? 'success';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedTickDouble01,
            color: AppTheme.accentGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tool Output: $status',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  output.toString(),
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
    if (action.type == NextBestActionType.kyc || action.type == NextBestActionType.lowBalance) {
      bannerColor = AppTheme.accentOrange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: bannerColor.withValues(alpha: 0.3), width: 1)),
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
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  "Why: ${action.aiReason}",
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: bannerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(timelineProvider.notifier).log(
                type: TimelineEntryType.toolCompleted,
                title: 'Accepted via Chat: ${action.title}',
                description: 'User initiated solution directly from the chat banner.',
                status: TimelineEntryStatus.success,
              );

              ref.read(agentMemoryProvider.notifier).updateCooldown(action.type.name, DateTime.now().millisecondsSinceEpoch);

              if (action.type == NextBestActionType.kyc) {
                ref.read(currentNavIndexProvider.notifier).state = 1; // Go to KYC
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
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
