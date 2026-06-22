import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/features/navigation/bottom_nav_shell.dart';
import 'package:sbiv2/features/settings/settings_screen.dart';

class ExistingCustomerLoginScreen extends ConsumerStatefulWidget {
  const ExistingCustomerLoginScreen({super.key});

  @override
  ConsumerState<ExistingCustomerLoginScreen> createState() => _ExistingCustomerLoginScreenState();
}

class _ExistingCustomerLoginScreenState extends ConsumerState<ExistingCustomerLoginScreen> {
  final TextEditingController _usernameController = TextEditingController(text: "sourabh_sbi");
  String _mpin = "";
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

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
    // Simulate secure verify delay
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Allow mock MPIN access
    ref.read(isLoggedInProvider.notifier).state = true;
    ref.read(currentNavIndexProvider.notifier).state = 0; // default tab Home

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BottomNavShell()),
      (route) => false,
    );
  }

  void _triggerBiometric() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.primaryLight,
                      child: Icon(Icons.lock_person_outlined, color: AppTheme.primary, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back!',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Login to your YONO SBI account',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    // Username input
                    TextField(
                      controller: _usernameController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Username / User ID',
                        labelStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary),
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Enter 6-Digit MPIN',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Pin dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        bool filled = index < _mpin.length;
                        return Container(
                          width: 14,
                          height: 14,
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
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                      ),
                  ],
                ),
              ),
            ),
            
            // Numeric Keyboard
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: AppTheme.background,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['1', '2', '3'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['4', '5', '6'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['7', '8', '9'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric icon trigger
                      IconButton(
                        icon: const Icon(Icons.fingerprint, color: AppTheme.primary, size: 28),
                        onPressed: _triggerBiometric,
                      ),
                      _buildKey('0'),
                      // Backspace
                      IconButton(
                        icon: const Icon(Icons.backspace_outlined, color: AppTheme.textPrimary, size: 20),
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
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
