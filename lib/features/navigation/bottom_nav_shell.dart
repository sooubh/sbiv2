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

  void _switchProfile(WidgetRef ref, String val) {
    ref.read(profileTypeProvider.notifier).setProfile(val);
    ref.read(userProfileProvider.notifier).reset();
    ref.read(transactionsProvider.notifier).reset();
    ref.read(goalsProvider.notifier).reset();
    ref.read(recommendationsProvider.notifier).reset();
    ref.read(servicesProvider.notifier).reset();
    ref.read(engagementProvider.notifier).reset();
    ref.read(onboardingChatProvider.notifier).reset();
    ref.read(bankingChatProvider.notifier).reset();
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final profileType = ref.watch(profileTypeProvider);
            final apiKey = ref.watch(geminiApiKeyProvider);
            final apiKeyController = TextEditingController(text: apiKey);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.settings, color: AppTheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Settings & Developer Console',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Profile Switcher Section
                    Text(
                      'Select Active Demo Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Profile A card
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (profileType != 'A') {
                                _switchProfile(ref, 'A');
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Switched to Profile: Rohan (Naya Customer)'),
                                    backgroundColor: AppTheme.primary,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: profileType == 'A' ? AppTheme.primary : AppTheme.border,
                                  width: profileType == 'A' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Rohan',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (profileType == 'A')
                                        const Icon(Icons.check_circle, color: AppTheme.primary, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Naya Customer\nBalance: ₹5,000\nKYC: Incomplete\nUPI: Inactive',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Profile B card
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (profileType != 'B') {
                                _switchProfile(ref, 'B');
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Switched to Profile: Sourabh (Existing Customer)'),
                                    backgroundColor: AppTheme.primary,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: profileType == 'B' ? AppTheme.primary : AppTheme.border,
                                  width: profileType == 'B' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Sourabh',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (profileType == 'B')
                                        const Icon(Icons.check_circle, color: AppTheme.primary, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Existing Customer\nBalance: ₹1,24,500\nKYC: Complete\nUPI: Active',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // API Configuration Section
                    Text(
                      'Gemini API Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
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
                            'Enter Gemini API Key to enable Live WebSockets & REST. Leave empty to use local high-fidelity AI simulation.',
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: apiKeyController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Gemini API Key',
                              labelStyle: GoogleFonts.inter(fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                ref.read(aiCoordinatorProvider.notifier).updateApiKey(apiKeyController.text.trim());
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(apiKeyController.text.isNotEmpty
                                        ? 'API Key saved. Reconnecting...'
                                        : 'Switched to local simulation mode.'),
                                    backgroundColor: AppTheme.primary,
                                  ),
                                );
                              },
                              child: Text('Save Gemini API Config', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Reset Actions
                    Text(
                      'App Utilities',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: Text('Reset App Demo Data', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _switchProfile(ref, profileType);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Demo data has been reset to default mock values.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white.withValues(alpha: 0.15),
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
          
          // Gear Settings Button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettingsSheet(context),
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
