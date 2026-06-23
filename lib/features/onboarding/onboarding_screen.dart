import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/voice/voice_service.dart';
import 'package:sbiv2/ai/voice/voice_state.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';
import 'package:sbiv2/features/settings/settings_screen.dart';
import 'package:sbiv2/features/navigation/bottom_nav_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isVideoKycVerifying = false;

  @override
  void initState() {
    super.initState();
    // Initialise voice service for STT/TTS on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceServiceProvider).initialize();
      // Let the agent introduce the name prompt
      final messages = ref.read(onboardingChatProvider);
      if (messages.length <= 1) {
        ref.read(voiceServiceProvider).speak("Aapka swagat hai! Let's start. Please enter your full name.");
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int _determineActiveStep(UserProfile profile) {
    if (profile.name.isEmpty) return 0;
    if (profile.mobileNumber.isEmpty) return 1;
    if (profile.kycStep == 'none') return 2;
    if (profile.kycStep == 'pan') return 3;
    if (profile.kycStep == 'aadhaar' && profile.address.isEmpty) return 4;
    if (profile.kycStep == 'aadhaar' && profile.address.isNotEmpty) return 5;
    if (profile.kycStep == 'complete' && !profile.upiEnabled) return 6;
    return 7; // Completed
  }

  String _getStepLabel(int step) {
    switch (step) {
      case 0:
        return "Name";
      case 1:
        return "Mobile";
      case 2:
        return "PAN";
      case 3:
        return "Aadhaar";
      case 4:
        return "Address";
      case 5:
        return "Video KYC";
      case 6:
        return "UPI Setup";
      default:
        return "Success";
    }
  }

  void _submitInput(String text) {
    if (text.isEmpty) return;
    _textController.clear();
    
    // Send text to AICoordinator so it handles logs, state transitions, and voice output
    ref.read(aiCoordinatorProvider.notifier).sendMessage(text);
  }

  void _runMockVideoKyc() async {
    setState(() {
      _isVideoKycVerifying = true;
    });
    // Simulate camera verification lag
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() {
      _isVideoKycVerifying = false;
    });

    ref.read(aiCoordinatorProvider.notifier).sendMessage("verify video kyc");
  }

  void _runMockUpiSetup() {
    final profile = ref.read(userProfileProvider);
    String vpa = _textController.text.trim();
    if (vpa.isEmpty) {
      vpa = "${profile.name.toLowerCase().replaceAll(' ', '')}@sbi";
    }
    _submitInput(vpa);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final messages = ref.watch(onboardingChatProvider);
    final voiceState = ref.watch(voiceStateProvider);
    final aiState = ref.watch(aiCoordinatorProvider);

    final activeStep = _determineActiveStep(profile);
    final agentMessages = messages.where((m) => m.sender == 'agent').toList();
    final currentAgentPrompt = agentMessages.isNotEmpty 
        ? agentMessages.last.text 
        : "Aapka swagat hai! Let's start. Please enter your full name.";
    
    // Speak the latest agent response text dynamically if it changed
    ref.listen(onboardingChatProvider, (prev, next) {
      if (next.isNotEmpty && next.last.sender == 'agent') {
        ref.read(voiceServiceProvider).speak(next.last.text);
      }
    });

    if (profile.kycComplete && profile.upiEnabled) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text('Onboarding Successful', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        color: AppTheme.accentGreen,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'KYC & UPI Active!',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Congratulations! Your SBI digital account is now open and fully authenticated.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Enter YONO SBI 2.0 Banking'),
                        onPressed: () {
                          ref.read(agentStateProvider.notifier).setMode(AgentMode.banking);
                          ref.read(currentNavIndexProvider.notifier).state = 0; // go to Home
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const BottomNavShell()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'SBI Digital Onboarding',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Step progress indicator bar
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                bool isDone = index < activeStep;
                bool isActive = index == activeStep;

                Color circleColor = Colors.white24;
                Color textColor = Colors.white70;
                if (isDone) {
                  circleColor = AppTheme.accentGreen;
                  textColor = Colors.white;
                } else if (isActive) {
                  circleColor = AppTheme.aiTeal;
                  textColor = Colors.white;
                }

                return Column(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: circleColor,
                      child: isDone
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStepLabel(index),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          
          // Speaking / thinking alert
          if (voiceState.status == VoiceStatus.speaking)
            Container(
              color: AppTheme.aiTeal.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, size: 16, color: AppTheme.aiTeal),
                  const SizedBox(width: 8),
                  Text(
                    'Agent is speaking...',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.aiTeal),
                  ),
                ],
              ),
            ),
          
          // Agent dialogue box
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Agent Avatar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 3),
                      ),
                      child: const Icon(Icons.support_agent, color: AppTheme.primary, size: 48),
                    ),
                    const SizedBox(height: 24),
                    // Agent speech bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'SBI Assistant',
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 8),
                              if (aiState.isThinking)
                                const SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.aiTeal),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentAgentPrompt,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // User Guided Input Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.border)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activeStep == 5) ...[
                  // Video KYC Panel
                  _buildVideoKycCard(),
                ] else if (activeStep == 6) ...[
                  // UPI Setup Panel
                  _buildUpiCard(),
                ] else ...[
                  // Normal Text Input Panel
                  _buildTextInputRow(activeStep),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputRow(int activeStep) {
    final voiceState = ref.watch(voiceStateProvider);
    final isListening = voiceState.status == VoiceStatus.listening;

    String hintText = "Type your answer...";
    TextInputType keyboardType = TextInputType.text;
    if (activeStep == 1) {
      hintText = "e.g. 9876543210";
      keyboardType = TextInputType.phone;
    } else if (activeStep == 2) {
      hintText = "e.g. ABCDE1234F";
    } else if (activeStep == 3) {
      hintText = "e.g. 123456789012";
      keyboardType = TextInputType.number;
    }

    return Row(
      children: [
        // Voice mic dictation button
        GestureDetector(
          onTap: () {
            final svc = ref.read(voiceServiceProvider);
            if (isListening) {
              svc.cancelListening();
            } else if (voiceState.status != VoiceStatus.speaking) {
              svc.startListening();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isListening ? Colors.red.withValues(alpha: 0.1) : AppTheme.background,
              shape: BoxShape.circle,
              border: Border.all(color: isListening ? Colors.red : AppTheme.border),
            ),
            child: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening ? Colors.red : AppTheme.textSecondary,
              size: 22,
            ),
          ),
        ),
        // Input text field
        Expanded(
          child: TextField(
            controller: _textController,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.send,
            onSubmitted: _submitInput,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Submit Button
        GestureDetector(
          onTap: () => _submitInput(_textController.text.trim()),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoKycCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_call, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'SBI Video Verification Portal',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isVideoKycVerifying) ...[
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              'Running live face-match & document OCR scan...',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ] else ...[
            Text(
              'Connect with our automated video agent to complete document checks.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                icon: const Icon(Icons.videocam),
                label: const Text('Start Video Verification'),
                onPressed: _runMockVideoKyc,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpiCard() {
    final profile = ref.watch(userProfileProvider);
    final defaultVpa = "${profile.name.toLowerCase().replaceAll(' ', '')}@sbi";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configure Virtual VPA ID',
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: defaultVpa,
                  hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: _runMockUpiSetup,
              child: const Text('Activate UPI'),
            ),
          ],
        ),
      ],
    );
  }
}
