# Target Architecture Migration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate YONO SBI 2.0's onboarding, login, profile-switching, settings, and splash flows to a structured target architecture including Splash, Customer Selection, Existing Customer Login, New Customer AI Onboarding, dedicated Settings and Debug pages.

**Architecture:** Introduce Splash and Customer Selection screens as the entry points, separating New Customer Onboarding (Rohan) from Existing Customer Login (Sourabh). Route both to a clean Bottom Navigation Shell (Banking Agent Mode) featuring home, products, engagement, AI chat (Banking Assistant), and settings.

**Tech Stack:** Flutter, Riverpod, Hive, Google Fonts, Material 3

---

### Task 1: Setup State Providers for Auth
**Files:**
- Modify: `lib/data/repositories/state_providers.dart`

**Step 1: Write state provider test or definition**
Define the `isLoggedInProvider` to keep track of PIN/Biometric login state:
```dart
final isLoggedInProvider = StateProvider<bool>((ref) => false);
```

Update the profile switching logic in `ProfileTypeNotifier` to invalidate/reset login state on switch.

**Step 2: Commit**
```bash
git add lib/data/repositories/state_providers.dart
git commit -m "state: add isLoggedInProvider for existing customer authentication"
```

---

### Task 2: Implement Splash Screen
**Files:**
- Create: `lib/features/splash/splash_screen.dart`
- Modify: `lib/main.dart`

**Step 1: Create Splash Screen Widget**
Implement a beautiful Material 3 Splash Screen utilizing `AppTheme.primary` with SBI colors, YONO 2.0 branding, a fade transition animation, and an automatic redirection to `CustomerSelectionScreen` after 2 seconds:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/features/customer_selection/customer_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerSelectionScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'yono',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
              Text(
                'sbi 2.0',
                style: GoogleFonts.poppins(
                  color: AppTheme.aiTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppTheme.aiTeal),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Modify `lib/main.dart` home page**
Update `main.dart` home property to point to `SplashScreen`.

**Step 3: Commit**
```bash
git add lib/features/splash/splash_screen.dart lib/main.dart
git commit -m "feat: add splash screen and set as app main entry point"
```

---

### Task 3: Implement Customer Selection Screen
**Files:**
- Create: `lib/features/customer_selection/customer_selection_screen.dart`

**Step 1: Create Customer Selection Screen**
Develop the selection dashboard card list comparing "Rohan (New)" vs "Sourabh (Existing)". Use rich gradient borders, stats icons, and descriptions:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/features/login/existing_customer_login_screen.dart';
import 'package:sbiv2/features/onboarding/onboarding_screen.dart';

class CustomerSelectionScreen extends ConsumerWidget {
  const CustomerSelectionScreen({super.key});

  void _setupProfile(WidgetRef ref, String profileType) {
    ref.read(profileTypeProvider.notifier).setProfile(profileType);
    ref.read(userProfileProvider.notifier).reset();
    ref.read(transactionsProvider.notifier).reset();
    ref.read(goalsProvider.notifier).reset();
    ref.read(recommendationsProvider.notifier).reset();
    ref.read(servicesProvider.notifier).reset();
    ref.read(engagementProvider.notifier).reset();
    ref.read(onboardingChatProvider.notifier).reset();
    ref.read(bankingChatProvider.notifier).reset();
    ref.read(timelineProvider.notifier).clear();
    ref.read(agentEventProvider.notifier).clear();
    ref.read(agentStateProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to YONO SBI 2.0',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a user profile to explore the proactive banking & onboarding simulation.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 36),
              Expanded(
                child: Column(
                  children: [
                    _buildProfileCard(
                      context: context,
                      title: 'Rohan (New Customer)',
                      subtitle: 'Needs AI Onboarding & UPI Activation',
                      details: '• Income: ₹0-5 Lakhs\n• KYC: Incomplete\n• UPI: Inactive\n• Balance: ₹5,000',
                      icon: Icons.person_add_alt_1_outlined,
                      gradientColors: [AppTheme.primary, AppTheme.aiTeal],
                      onTap: () {
                        _setupProfile(ref, 'A');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Scaffold(
                              body: OnboardingScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildProfileCard(
                      context: context,
                      title: 'Sourabh (Existing Customer)',
                      subtitle: 'Accesses Personalized Banking Assistant',
                      details: '• Income: ₹15-25 Lakhs\n• KYC: Verified\n• UPI: Active\n• Balance: ₹1,24,500',
                      icon: Icons.admin_panel_settings_outlined,
                      gradientColors: [AppTheme.primaryDark, AppTheme.accentGreen],
                      onTap: () {
                        _setupProfile(ref, 'B');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExistingCustomerLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String details,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 150,
                  color: AppTheme.border.withValues(alpha: 0.4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      details,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Commit**
```bash
git add lib/features/customer_selection/customer_selection_screen.dart
git commit -m "feat: implement customer selection screen with rich profiles A & B"
```

---

### Task 4: Implement Existing Customer Login (MPIN / Biometric)
**Files:**
- Create: `lib/features/login/existing_customer_login_screen.dart`

**Step 1: Create Existing Customer Login Screen**
Build an authentic MPIN input screen with custom keyboard support and a biometric prompt toggle that routes to the main shell (`BottomNavShell`) on successful entry:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/features/navigation/bottom_nav_shell.dart';

class ExistingCustomerLoginScreen extends ConsumerStatefulWidget {
  const ExistingCustomerLoginScreen({super.key});

  @override
  ConsumerState<ExistingCustomerLoginScreen> createState() => _ExistingCustomerLoginScreenState();
}

class _ExistingCustomerLoginScreenState extends ConsumerState<ExistingCustomerLoginScreen> {
  String _mpin = "";
  bool _isLoading = false;

  void _keypressed(String value) {
    if (_mpin.length >= 6) return;
    setState(() {
      _mpin += value;
    });

    if (_mpin.length == 6) {
      _verifyLogin();
    }
  }

  void _backspace() {
    if (_mpin.isEmpty) return;
    setState(() {
      _mpin = _mpin.substring(0, _mpin.length - 1);
    });
  }

  Future<void> _verifyLogin() async {
    setState(() {
      _isLoading = true;
    });
    // Simulate secure network verification
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    if (_mpin == "123456" || _mpin.length == 6) { // allow any 6 digit mock login
      ref.read(isLoggedInProvider.notifier).state = true;
      ref.read(currentNavIndexProvider.notifier).state = 0; // Default to Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavShell()),
        (route) => false,
      );
    } else {
      setState(() {
        _mpin = "";
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid MPIN, please try again.')),
      );
    }
  }

  void _triggerBiometric() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    
    ref.read(isLoggedInProvider.notifier).state = true;
    ref.read(currentNavIndexProvider.notifier).state = 0;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BottomNavShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryLight,
                      child: Icon(Icons.lock_person_outlined, color: AppTheme.primary, size: 36),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back, Sourabh!',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your 6-digit MPIN to access your account.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 36),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        bool filled = index < _mpin.length;
                        return Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled ? AppTheme.primary : Colors.transparent,
                            border: Border.all(color: AppTheme.border, width: 2),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
            ),
            
            // Numeric Keyboard
            Container(
              padding: const EdgeInsets.all(24),
              color: AppTheme.background,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['1', '2', '3'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['4', '5', '6'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['7', '8', '9'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric Button
                      IconButton(
                        icon: const Icon(Icons.fingerprint, color: AppTheme.primary, size: 28),
                        onPressed: _triggerBiometric,
                      ),
                      _buildKey('0'),
                      // Backspace Button
                      IconButton(
                        icon: const Icon(Icons.backspace_outlined, color: AppTheme.textPrimary, size: 24),
                        onPressed: _backspace,
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

  Widget _buildKey(String value) {
    return InkWell(
      onTap: () => _keypressed(value),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        child: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Commit**
```bash
git add lib/features/login/existing_customer_login_screen.dart
git commit -m "feat: implement MPIN & biometric login panel for existing customer Sourabh"
```

---

### Task 5: Refactor Onboarding Screen for Rohan (New Customer)
**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`

**Step 1: Edit Onboarding Screen**
Remove the conditional redirect card that triggers when Sourabh is active. Update the screen so it strictly runs Rohan's flow. Add a visual verification splash screen once KYC completes, providing a prominent button to "Proceed to Banking Agent Mode":
- Target: lines 54-137 (Redirection UI block)
- Replacement Content:
  ```dart
  // If user is Rohan and KYC is completed, show a verification success page with navigation to Banking Mode
  if (profile.kycComplete) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(24),
      child: Center(
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
                  'KYC & UPI Verified!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Namaste, Rohan! Your KYC is completed and UPI VPA is registered.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
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
    );
  }
  ```

**Step 2: Commit**
```bash
git add lib/features/onboarding/onboarding_screen.dart
git commit -m "refactor: isolate onboarding screen to Rohan and implement banking entry gateway"
```

---

### Task 6: Create Dedicated Settings & API Configuration Screen
**Files:**
- Create: `lib/features/settings/settings_screen.dart`

**Step 1: Create Settings Screen Widget**
Move the settings bottom sheet options into a dedicated tab dashboard:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
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

  void _switchProfileBack(WidgetRef ref) {
    ref.read(isLoggedInProvider.notifier).state = false;
    ref.read(profileTypeProvider.notifier).setProfile('B'); // Default reset
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(geminiApiKeyProvider);
    final activeProfile = ref.watch(profileTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings & Keys',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'API CONFIGURATION',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
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
                  'Enter your Gemini API key to enable Live Websockets. Leave blank to run offline simulation.',
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
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(aiCoordinatorProvider.notifier).updateApiKey(_apiKeyController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gemini API settings updated.')),
                      );
                    },
                    child: const Text('Save API Key'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'UTILITIES',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.aiTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.bug_report),
            label: const Text('Open Developer Debug Panel'),
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
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Switch Profile / Exit App'),
            onPressed: () => _switchProfileBack(ref),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**
```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat: add dedicated SettingsScreen replacing the settings modal sheet"
```

---

### Task 7: Refactor Bottom Navigation Shell
**Files:**
- Modify: `lib/features/navigation/bottom_nav_shell.dart`

**Step 1: Replace Onboarding Screen and Add Settings tab**
Rearrange screens array and labels inside `bottom_nav_shell.dart` to support standard banking experience:
- Replace `OnboardingScreen` (index 1) with `ProductsScreen`, `EngagementScreen` (index 2), `AiChatScreen` (index 3), and `SettingsScreen` (index 4).
- Clean up obsolete `_showSettingsSheet` sheet implementation.
- Target code: lines 24-30 (list of screens)
- Replacement Content:
  ```dart
  final List<Widget> _screens = [
    const HomeScreen(),
    const ProductsScreen(),
    const EngagementScreen(),
    const AiChatScreen(),
    const SettingsScreen(),
  ];
  ```

Update `BottomNavigationBar` items array (lines 512-544) to match this structure:
- Tab 0: Home
- Tab 1: Products
- Tab 2: Gamification (Engagement)
- Tab 3: Banking AI Assistant
- Tab 4: Settings & Keys

**Step 2: Commit**
```bash
git add lib/features/navigation/bottom_nav_shell.dart
git commit -m "refactor: update BottomNavShell tab indices to incorporate new target architecture"
```

---

### Task 8: Refactor Debug Simulation Page Routing
**Files:**
- Modify: `lib/features/settings/debug_simulation_page.dart`

**Step 1: Align Onboarding Completion redirect**
In `debug_simulation_page.dart`, find `_completeKYC` method:
- Target code: lines 286-290 (simulate response statement)
- Add route redirection inside `_completeKYC` to transition user from OnboardingScreen directly to BottomNavShell if Rohan is completing KYC:
  ```dart
  ref.read(currentNavIndexProvider.notifier).state = 0;
  // Use navigation checks to see if OnboardingScreen is the current route and route replacement
  ```

**Step 2: Commit**
```bash
git add lib/features/settings/debug_simulation_page.dart
git commit -m "refactor: update debug simulation page KYC trigger to redirect to shell"
```
