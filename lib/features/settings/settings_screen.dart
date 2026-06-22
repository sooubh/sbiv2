import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';
import 'package:sbiv2/ai/voice/voice_state.dart';
import 'package:sbiv2/features/splash/splash_screen.dart';
import 'package:sbiv2/features/settings/debug_simulation_page.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final apiKey = ref.read(geminiApiKeyProvider);
    _apiKeyController = TextEditingController(text: apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _logoutAndExit(WidgetRef ref) {
    ref.read(isLoggedInProvider.notifier).state = false;
    ref.read(profileTypeProvider.notifier).setProfile('B'); // Reset to default
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentStateProvider);
    final voiceState = ref.watch(voiceStateProvider);
    final aiState = ref.watch(aiCoordinatorProvider);

    String connectionStatus = agentState.connectionStatus.toUpperCase();
    Color connectionColor = AppTheme.textSecondary;
    if (connectionStatus == "CONNECTED") {
      connectionColor = AppTheme.accentGreen;
    } else if (connectionStatus == "CONNECTING") {
      connectionColor = Colors.amber;
    } else if (connectionStatus == "DISCONNECTED") {
      connectionColor = AppTheme.accentOrange;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings & Config',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Gemini API Section
          Text(
            'API KEY CONFIGURATION',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemini API Settings',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provide a valid Gemini API Key to enable voice and REST integrations. If left empty, the application runs in offline-simulation mode.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    labelStyle: GoogleFonts.inter(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: const Icon(Icons.key, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(aiCoordinatorProvider.notifier).updateApiKey(_apiKeyController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gemini API configuration successfully updated.'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    },
                    child: Text('Save Configuration', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Connection Status Card
          Text(
            'ENGINE STATUS & RUNTIME',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _buildStatusRow(
                  label: 'Gemini Live Status',
                  value: connectionStatus,
                  valueColor: connectionColor,
                  icon: Icons.wifi,
                ),
                const Divider(height: 24),
                _buildStatusRow(
                  label: 'Model Mode',
                  value: aiState.mode.name.toUpperCase(),
                  valueColor: AppTheme.primary,
                  icon: Icons.psychology,
                ),
                const Divider(height: 24),
                _buildStatusRow(
                  label: 'Voice Engine',
                  value: voiceState.status.name.toUpperCase(),
                  valueColor: voiceState.status == VoiceStatus.error ? AppTheme.accentOrange : AppTheme.aiTeal,
                  icon: Icons.mic_none,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Developer Access
          Text(
            'DEVELOPER ACCESS',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.aiTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.bug_report),
            label: Text('Open Developer Debug Portal', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugSimulationPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.exit_to_app),
            label: Text('Switch Profile / Exit Session', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            onPressed: () => _logoutAndExit(ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: AppTheme.monoStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
