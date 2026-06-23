import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';
import 'package:sbiv2/features/home/home_screen.dart';
import 'package:sbiv2/features/products/products_screen.dart';
import 'package:sbiv2/features/engagement/engagement_screen.dart';
import 'package:sbiv2/features/ai_chat/ai_chat_screen.dart';
import 'package:sbiv2/features/settings/settings_screen.dart';
import 'package:sbiv2/features/settings/debug_simulation_page.dart';

class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({super.key});

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const ProductsScreen(),
    const EngagementScreen(),
    const AiChatScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentNavIndexProvider);
    final aiState = ref.watch(aiCoordinatorProvider);
    final agentState = ref.watch(agentStateProvider);
    final coins = ref.watch(engagementProvider).sbiCoins;

    Color statusColor = AppTheme.aiTeal;
    String statusText = "AI Engine: Simulated Mode";

    if (agentState.transportType == "rest") {
      statusColor = AppTheme.accentGreen;
      statusText = "AI Engine: REST (Active)";
    } else if (agentState.status == AgentStatus.error) {
      statusColor = AppTheme.accentOrange;
      statusText = "AI Engine: Error (${agentState.lastError ?? 'Unknown'})";
    }

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
              ref.read(currentNavIndexProvider.notifier).state = 2; // Navigate to Engagement Screen
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
          GestureDetector(
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugSimulationPage()),
              );
            },
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                ref.read(currentNavIndexProvider.notifier).state = 4; // Navigate to Settings Screen
              },
            ),
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
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
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
          Expanded(child: _screens[currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(currentNavIndexProvider.notifier).state = index;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: AppTheme.primary),
            label: 'Home',
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings, color: AppTheme.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
