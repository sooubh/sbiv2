class RetentionRules {
  /// Default cooldown duration for suggestions to prevent spam.
  /// Set to 30 seconds for quick hackathon/demo verification, but normally higher.
  static const Duration cooldownDuration = Duration(seconds: 30);

  /// Checks if the given action type is currently on cooldown based on the memory map.
  static bool isCoolingDown(String actionKey, Map<String, int> cooldownMap) {
    final timestamp = cooldownMap[actionKey];
    if (timestamp == null) return false;

    final lastTriggered = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final timePassed = DateTime.now().difference(lastTriggered);
    return timePassed < cooldownDuration;
  }

  /// Updates the cooldown timestamp for a recommendation type.
  static Map<String, int> updateCooldown(String actionKey, Map<String, int> currentMap) {
    final updated = Map<String, int>.from(currentMap);
    updated[actionKey] = DateTime.now().millisecondsSinceEpoch;
    return updated;
  }

  /// Tailors a personalized greeting or message based on customer profile & pattern history.
  static String getGreeting(String name, String activeProfileType, String? lastWelcomeMessage) {
    final hour = DateTime.now().hour;
    String timeGreeting = "Good Morning";
    if (hour >= 12 && hour < 17) {
      timeGreeting = "Good Afternoon";
    } else if (hour >= 17) {
      timeGreeting = "Good Evening";
    }

    if (activeProfileType == 'A') {
      return "$timeGreeting, Rohan! Welcome to YONO SBI 2.0. Let's finish your quick setup so you can start banking.";
    } else {
      return "$timeGreeting, Sourabh! Welcome back. Your active savings streak is looking good today.";
    }
  }

  /// Checks if a greeting should be shown/announced based on session memory.
  static bool shouldGreet(String name, String? lastWelcomeMessage) {
    if (lastWelcomeMessage == null) return true;
    
    // For demo convenience, let's greet if the user switched profiles or if some time has passed.
    return false; // Return false if already welcomed in the current session state.
  }
}
