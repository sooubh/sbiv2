import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/voice/voice_service.dart';
import 'package:sbiv2/ai/voice/voice_state.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';
import 'package:sbiv2/features/settings/settings_screen.dart';
import 'package:sbiv2/features/navigation/bottom_nav_shell.dart';
import 'package:sbiv2/features/agent/widgets/ai_avatar.dart';

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
      final profile = ref.read(userProfileProvider);
      if (profile.kycComplete && profile.upiEnabled) {
        ref.read(agentStateProvider.notifier).setMode(AgentMode.banking);
        ref.read(currentNavIndexProvider.notifier).state = 0; // go to Home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavShell()),
          (route) => false,
        );
        return;
      }

      ref.read(voiceServiceProvider).initialize();
      // Let the agent introduce the name prompt
      final messages = ref.read(onboardingChatProvider);
      if (messages.length <= 1) {
        ref.read(voiceServiceProvider).speak("Aapka swagat hai! Let's start. Please enter your full name.");
      }

      // Check if onboarding already started
      if (profile.name.isNotEmpty) {
        final activeStep = _determineActiveStep(profile);
        if (activeStep < 7) {
          final stepLabel = _getStepLabel(activeStep);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Resume Onboarding', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Text(
                "Welcome back ${profile.name}! Let's resume your onboarding from the $stepLabel step.",
                style: GoogleFonts.inter(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Resume'),
                ),
              ],
            ),
          );
        }
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

  void _showCelebrationDialog(BuildContext context, String stepName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.primaryDark,
                  AppTheme.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative design elements
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.aiTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Confetti / Celebration icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentGreen.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.celebration,
                          color: AppTheme.accentGreen,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Congratulations!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$stepName Complete ✅',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              '+50 SBI Coins awarded!',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Awesome!',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button top right
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performDemoAutofillOnboarding() {
    final notifier = ref.read(userProfileProvider.notifier);
    notifier.updateProfile(
      ref.read(userProfileProvider).copyWith(
        name: ref.read(userProfileProvider).name.isEmpty ? 'Rohan' : ref.read(userProfileProvider).name,
        mobileNumber: ref.read(userProfileProvider).mobileNumber.isEmpty ? '9876543210' : ref.read(userProfileProvider).mobileNumber,
        kycStep: 'complete',
        kycComplete: true,
        upiEnabled: true,
        address: ref.read(userProfileProvider).address.isEmpty ? 'SBI HQ, Mumbai' : ref.read(userProfileProvider).address,
      ),
    );
    ref.read(agentStateProvider.notifier).setMode(AgentMode.banking);
    ref.read(currentNavIndexProvider.notifier).state = 0; // go to Home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BottomNavShell()),
      (route) => false,
    );
  }

  Widget _buildHandsFreeTipCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.aiTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.aiTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.aiTeal, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Hands-free mode active. Speak when the agent stops.",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpChip(int activeStep, UserProfile profile) {
    String label = "";
    VoidCallback? onTap;

    switch (activeStep) {
      case 0:
        label = "Autofill: Rohan";
        onTap = () {
          _textController.text = "Rohan";
          _submitInput("Rohan");
        };
        break;
      case 1:
        label = "Autofill: 9876543210";
        onTap = () {
          _textController.text = "9876543210";
          _submitInput("9876543210");
        };
        break;
      case 2:
        label = "Autofill: ABCDE1234F";
        onTap = () {
          _textController.text = "ABCDE1234F";
          _submitInput("ABCDE1234F");
        };
        break;
      case 3:
        label = "Autofill: 123456789012";
        onTap = () {
          _textController.text = "123456789012";
          _submitInput("123456789012");
        };
        break;
      case 4:
        label = "Autofill: SBI HQ, Mumbai";
        onTap = () {
          _textController.text = "SBI HQ, Mumbai";
          _submitInput("SBI HQ, Mumbai");
        };
        break;
      case 5:
        label = "Autofill Video KYC";
        onTap = () {
          ref.read(aiCoordinatorProvider.notifier).sendMessage("verify video kyc");
        };
        break;
      case 6:
        label = "Autofill UPI VPA";
        onTap = () {
          String vpa = "${profile.name.toLowerCase().replaceAll(' ', '')}@sbi";
          if (vpa.isEmpty || vpa == "@sbi") {
            vpa = "rohan@sbi";
          }
          _textController.text = vpa;
          _runMockUpiSetup();
        };
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: const Icon(Icons.help_outline, size: 14, color: AppTheme.primary),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppTheme.border),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final messages = ref.watch(onboardingChatProvider);
    final voiceState = ref.watch(voiceStateProvider);
    final aiState = ref.watch(aiCoordinatorProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final handsFreeEnabled = ref.watch(handsFreeVoiceProvider);

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

    // Listen to profile updates for key step completions
    ref.listen<UserProfile>(userProfileProvider, (previous, next) {
      if (previous == null) return;
      
      // Aadhaar completed (transition from previous step to 'aadhaar')
      if (previous.kycStep != 'aadhaar' && next.kycStep == 'aadhaar') {
        ref.read(engagementProvider.notifier).addCoins(50);
        _showCelebrationDialog(context, "Aadhaar Validation");
      }
      
      // Video KYC completed (transition from 'aadhaar' to 'complete')
      if (previous.kycStep != 'complete' && next.kycStep == 'complete') {
        ref.read(engagementProvider.notifier).addCoins(50);
        _showCelebrationDialog(context, "Video KYC");
      }

      // Check if both KYC and UPI became complete
      if ((!previous.kycComplete || !previous.upiEnabled) && next.kycComplete && next.upiEnabled) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!context.mounted) return;
          ref.read(agentStateProvider.notifier).setMode(AgentMode.banking);
          ref.read(currentNavIndexProvider.notifier).state = 0; // go to Home
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavShell()),
            (route) => false,
          );
        });
      }
    });

    if (profile.kycComplete && profile.upiEnabled) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text('Success', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedSecurityCheck,
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
                      'Your SBI digital account is set up and active.',
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
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text('Enter Banking'),
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
          'Onboarding',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.flash_on, color: Colors.amber, size: 16),
            label: Text(
              'Demo Autofill',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            onPressed: _performDemoAutofillOnboarding,
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings01,
              color: Colors.white,
              size: 24,
            ),
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
          // Language & Hands-free controls bar
          Container(
            color: AppTheme.primary.withValues(alpha: 0.95),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Language: ',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    ref.read(appLanguageProvider.notifier).setLanguage('en');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: currentLang == 'en' ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      'English',
                      style: GoogleFonts.inter(
                        color: currentLang == 'en' ? AppTheme.primary : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    ref.read(appLanguageProvider.notifier).setLanguage('hi');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: currentLang == 'hi' ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      'हिंदी',
                      style: GoogleFonts.inter(
                        color: currentLang == 'hi' ? AppTheme.primary : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    ref.read(handsFreeVoiceProvider.notifier).update((state) => !state);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: handsFreeEnabled ? AppTheme.aiTeal : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: handsFreeEnabled ? Colors.transparent : Colors.white30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          handsFreeEnabled ? Icons.mic : Icons.mic_none,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hands-Free',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                            ? const HugeIcon(
                                icon: HugeIcons.strokeRoundedTick01,
                                size: 12,
                                color: Colors.white,
                              )
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
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedVolumeUp,
                      size: 16,
                      color: AppTheme.aiTeal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Speaking...',
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
                      const AIAvatar(size: 110),
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
                                'AI Agent',
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
                if (handsFreeEnabled)
                  _buildHandsFreeTipCard(),
                _buildHelpChip(activeStep, profile),
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
            child: HugeIcon(
              icon: isListening ? HugeIcons.strokeRoundedMic01 : HugeIcons.strokeRoundedMicOff01,
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
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedSent,
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
              const HugeIcon(
                icon: HugeIcons.strokeRoundedVideo01,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Video KYC',
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
              'Connect with video agent to verify documents.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedVideo01,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text('Start Video KYC'),
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
          'Configure UPI VPA',
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
              child: const Text('Activate'),
            ),
          ],
        ),
      ],
    );
  }
}
