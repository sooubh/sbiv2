import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/engine/pattern_engine.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
                  const Icon(Icons.psychology, color: AppTheme.aiTeal, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'AI Decision Rationale',
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
                'How the Agent processes your requests:',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Parses intent: Extracts transfer details (recipient, amount), goal boosts, or investment desires.\n'
                '2. Evaluates context: Checks if savings buffer is adequate (PatternEngine check).\n'
                '3. Autonomously triggers tool actions (execute_transfer, boost_goal, suggest_service) and completes state modifications without requiring UI clicks.',
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Active Pattern Engine Context:',
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
                  child: const Text('Got it'),
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
    final aiState = ref.watch(aiCoordinatorProvider);

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
                backgroundColor: AppTheme.aiTeal.withOpacity(0.2),
                child: const Icon(Icons.chat, color: AppTheme.aiTeal),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SBI Conversational Assistant',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Zero-tap banking assistant',
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
                icon: const Icon(Icons.help_outline, color: Colors.white),
                tooltip: 'Why did agent do this?',
                onPressed: () => _showExplainabilitySheet(context),
              ),
            ],
          ),
        ),

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
                return _buildSystemLog(msg.text, msg.toolCall);
              }
              if (msg.sender == 'tool') {
                return _buildToolResult(msg.text, msg.toolCall);
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

        // Input Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (val) => _submitMessage(val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Type: "mom ko 2000 bhej do"...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              GestureDetector(
                onTap: () => _submitMessage(_textController.text.trim()),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
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

  Widget _buildSystemLog(String text, Map<String, dynamic>? toolCall) {
    final toolName = toolCall?['name'] ?? '';
    final args = toolCall?['args'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.aiTeal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.aiTeal.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology, color: AppTheme.aiTeal, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reasoning & Tool Call: $toolName',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.aiTeal,
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

  Widget _buildToolResult(String text, Map<String, dynamic>? toolCall) {
    final output = toolCall?['output'] ?? {};
    final status = output['status'] ?? 'success';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.done_all, color: AppTheme.accentGreen, size: 16),
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
}
