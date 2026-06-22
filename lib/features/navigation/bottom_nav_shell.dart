import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/features/home/home_screen.dart';
import 'package:sbiv2/features/onboarding/onboarding_screen.dart';
import 'package:sbiv2/features/products/products_screen.dart';
import 'package:sbiv2/features/engagement/engagement_screen.dart';
import 'package:sbiv2/features/ai_chat/ai_chat_screen.dart';

class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({super.key});

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const OnboardingScreen(),
    const ProductsScreen(),
    const EngagementScreen(),
    const AiChatScreen(),
  ];

  void _showApiKeyDialog(BuildContext context) {
    final apiKeyController = TextEditingController(text: ref.read(geminiApiKeyProvider));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Gemini API Settings',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Gemini API Key to enable Live WebSockets & REST. Leave empty to use local high-fidelity AI simulation.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(aiCoordinatorProvider.notifier).updateApiKey(apiKeyController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(apiKeyController.text.isNotEmpty
                        ? 'Gemini API Key updated. Reconnecting...'
                        : 'Switched to simulated AI mode.'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileType = ref.watch(profileTypeProvider);
    final profile = ref.watch(userProfileProvider);
    final aiState = ref.watch(aiCoordinatorProvider);
    final coins = ref.watch(engagementProvider).sbiCoins;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'yono',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              ' sbi',
              style: GoogleFonts.poppins(
                color: AppTheme.aiTeal,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '2.0',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Coins indicator
          GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 3; // Navigate to Engagement Screen (coins tracker)
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$coins',
                    style: AppTheme.monoStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Profile Switcher (A/B)
          DropdownButton<String>(
            value: profileType,
            dropdownColor: AppTheme.primaryDark,
            underline: const SizedBox(),
            icon: const Icon(Icons.switch_account, color: Colors.white),
            items: const [
              DropdownMenuItem(
                value: 'A',
                child: Text(' Rohan (Naya)  ', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              DropdownMenuItem(
                value: 'B',
                child: Text(' Sourabh (Existing)  ', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                ref.read(profileTypeProvider.notifier).setProfile(val);
                ref.read(userProfileProvider.notifier).reset();
                ref.read(transactionsProvider.notifier).reset();
                ref.read(goalsProvider.notifier).reset();
                ref.read(recommendationsProvider.notifier).reset();
                ref.read(servicesProvider.notifier).reset();
                ref.read(engagementProvider.notifier).reset();
                ref.read(onboardingChatProvider.notifier).reset();
                ref.read(bankingChatProvider.notifier).reset();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched to profile: ${val == 'A' ? 'Rohan (New Customer)' : 'Sourabh (Existing Customer)'}'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              }
            },
          ),
          // API Settings
          IconButton(
            icon: Icon(
              Icons.vpn_key,
              color: aiState.mode == AIServiceMode.simulated ? Colors.white70 : AppTheme.aiTeal,
            ),
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // AI status line
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: AppTheme.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: aiState.mode == AIServiceMode.live
                            ? AppTheme.accentGreen
                            : (aiState.mode == AIServiceMode.rest ? Colors.amber : AppTheme.aiTeal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      aiState.mode == AIServiceMode.live
                          ? "Agent Connection: Live (WebSocket)"
                          : (aiState.mode == AIServiceMode.rest ? "Agent Connection: REST API" : "Agent Connection: Local Simulation"),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (aiState.isThinking)
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.aiTeal),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Thinking...",
                        style: GoogleFonts.inter(color: AppTheme.aiTeal, fontSize: 10, fontWeight: FontWeight.bold),
                      )
                    ],
                  )
              ],
            ),
          ),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: AppTheme.primary),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_outlined),
            activeIcon: Icon(Icons.person_add, color: AppTheme.primary),
            label: 'KYC App',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag, color: AppTheme.primary),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights, color: AppTheme.primary),
            label: 'Engagement',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble, color: AppTheme.primary),
            label: 'AI Chat',
          ),
        ],
      ),
    );
  }
}
