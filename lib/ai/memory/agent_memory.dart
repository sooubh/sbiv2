import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/data/repositories/state_providers.dart' show kAgentMemoryBox, profileTypeProvider;

class AgentMemory {
  final String activeProfileType;
  final bool onboardingCompleted;
  final String kycStep;
  final SignalSummary? lastDetectedSignal;
  final String? lastRecommendedAction;
  final String? lastExecutedTool;
  final String userPreferenceSummary;
  final String primaryGoal;
  final String riskLevel;
  final String? lastSalaryDate;
  final String? lastSIPDate;
  final List<String> actionHistory;

  // New Prompt 5 fields for proactive/retention behaviors
  final String? lastSeenProfile;
  final String? lastWelcomeMessage;
  final String? lastProactiveSuggestion;
  final int? lastRecommendationTimestamp;
  final String? lastTriggeredSignal;
  final String? lastActionCompleted;
  final String userPatternSummary;
  final Map<String, int> suggestionCooldownMap;

  AgentMemory({
    required this.activeProfileType,
    required this.onboardingCompleted,
    required this.kycStep,
    this.lastDetectedSignal,
    this.lastRecommendedAction,
    this.lastExecutedTool,
    required this.userPreferenceSummary,
    required this.primaryGoal,
    required this.riskLevel,
    this.lastSalaryDate,
    this.lastSIPDate,
    required this.actionHistory,
    
    // New Prompt 5 fields
    this.lastSeenProfile,
    this.lastWelcomeMessage,
    this.lastProactiveSuggestion,
    this.lastRecommendationTimestamp,
    this.lastTriggeredSignal,
    this.lastActionCompleted,
    required this.userPatternSummary,
    required this.suggestionCooldownMap,
  });

  AgentMemory copyWith({
    String? activeProfileType,
    bool? onboardingCompleted,
    String? kycStep,
    SignalSummary? lastDetectedSignal,
    String? lastRecommendedAction,
    String? lastExecutedTool,
    String? userPreferenceSummary,
    String? primaryGoal,
    String? riskLevel,
    String? lastSalaryDate,
    String? lastSIPDate,
    List<String>? actionHistory,
    
    // New Prompt 5 fields
    String? lastSeenProfile,
    String? lastWelcomeMessage,
    String? lastProactiveSuggestion,
    int? lastRecommendationTimestamp,
    String? lastTriggeredSignal,
    String? lastActionCompleted,
    String? userPatternSummary,
    Map<String, int>? suggestionCooldownMap,
  }) {
    return AgentMemory(
      activeProfileType: activeProfileType ?? this.activeProfileType,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      kycStep: kycStep ?? this.kycStep,
      lastDetectedSignal: lastDetectedSignal ?? this.lastDetectedSignal,
      lastRecommendedAction: lastRecommendedAction ?? this.lastRecommendedAction,
      lastExecutedTool: lastExecutedTool ?? this.lastExecutedTool,
      userPreferenceSummary: userPreferenceSummary ?? this.userPreferenceSummary,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      riskLevel: riskLevel ?? this.riskLevel,
      lastSalaryDate: lastSalaryDate ?? this.lastSalaryDate,
      lastSIPDate: lastSIPDate ?? this.lastSIPDate,
      actionHistory: actionHistory ?? this.actionHistory,
      
      // New Prompt 5 fields
      lastSeenProfile: lastSeenProfile ?? this.lastSeenProfile,
      lastWelcomeMessage: lastWelcomeMessage ?? this.lastWelcomeMessage,
      lastProactiveSuggestion: lastProactiveSuggestion ?? this.lastProactiveSuggestion,
      lastRecommendationTimestamp: lastRecommendationTimestamp ?? this.lastRecommendationTimestamp,
      lastTriggeredSignal: lastTriggeredSignal ?? this.lastTriggeredSignal,
      lastActionCompleted: lastActionCompleted ?? this.lastActionCompleted,
      userPatternSummary: userPatternSummary ?? this.userPatternSummary,
      suggestionCooldownMap: suggestionCooldownMap ?? this.suggestionCooldownMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeProfileType': activeProfileType,
      'onboardingCompleted': onboardingCompleted,
      'kycStep': kycStep,
      'lastDetectedSignal': lastDetectedSignal?.toJson(),
      'lastRecommendedAction': lastRecommendedAction,
      'lastExecutedTool': lastExecutedTool,
      'userPreferenceSummary': userPreferenceSummary,
      'primaryGoal': primaryGoal,
      'riskLevel': riskLevel,
      'lastSalaryDate': lastSalaryDate,
      'lastSIPDate': lastSIPDate,
      'actionHistory': actionHistory,
      
      // New Prompt 5 fields
      'lastSeenProfile': lastSeenProfile,
      'lastWelcomeMessage': lastWelcomeMessage,
      'lastProactiveSuggestion': lastProactiveSuggestion,
      'lastRecommendationTimestamp': lastRecommendationTimestamp,
      'lastTriggeredSignal': lastTriggeredSignal,
      'lastActionCompleted': lastActionCompleted,
      'userPatternSummary': userPatternSummary,
      'suggestionCooldownMap': suggestionCooldownMap,
    };
  }

  factory AgentMemory.fromJson(Map<String, dynamic> json) {
    final cooldownRaw = json['suggestionCooldownMap'];
    final Map<String, int> cooldownMap = {};
    if (cooldownRaw != null) {
      Map<dynamic, dynamic>.from(cooldownRaw).forEach((key, val) {
        cooldownMap[key.toString()] = int.parse(val.toString());
      });
    }

    return AgentMemory(
      activeProfileType: json['activeProfileType'] ?? 'B',
      onboardingCompleted: json['onboardingCompleted'] ?? false,
      kycStep: json['kycStep'] ?? 'none',
      lastDetectedSignal: json['lastDetectedSignal'] != null
          ? SignalSummary.fromJson(Map<String, dynamic>.from(json['lastDetectedSignal']))
          : null,
      lastRecommendedAction: json['lastRecommendedAction'],
      lastExecutedTool: json['lastExecutedTool'],
      userPreferenceSummary: json['userPreferenceSummary'] ?? 'None',
      primaryGoal: json['primaryGoal'] ?? 'Savings',
      riskLevel: json['riskLevel'] ?? 'Low',
      lastSalaryDate: json['lastSalaryDate'],
      lastSIPDate: json['lastSIPDate'],
      actionHistory: List<String>.from(json['actionHistory'] ?? []),
      
      // New Prompt 5 fields
      lastSeenProfile: json['lastSeenProfile'],
      lastWelcomeMessage: json['lastWelcomeMessage'],
      lastProactiveSuggestion: json['lastProactiveSuggestion'],
      lastRecommendationTimestamp: json['lastRecommendationTimestamp'],
      lastTriggeredSignal: json['lastTriggeredSignal'],
      lastActionCompleted: json['lastActionCompleted'],
      userPatternSummary: json['userPatternSummary'] ?? 'Normal spender',
      suggestionCooldownMap: cooldownMap,
    );
  }
}

class AgentMemoryNotifier extends StateNotifier<AgentMemory> {
  final String profileType;

  AgentMemoryNotifier(this.profileType) : super(AgentMemory(
          activeProfileType: profileType,
          onboardingCompleted: false,
          kycStep: 'none',
          userPreferenceSummary: 'None',
          primaryGoal: 'Savings',
          riskLevel: 'Low',
          actionHistory: [],
          userPatternSummary: 'Normal spender',
          suggestionCooldownMap: const {},
        )) {
    loadMemory();
  }

  void loadMemory() {
    final box = Hive.box(kAgentMemoryBox);
    final key = 'memory_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      state = AgentMemory.fromJson(Map<String, dynamic>.from(cached));
    } else {
      state = AgentMemory(
        activeProfileType: profileType,
        onboardingCompleted: profileType == 'B',
        kycStep: profileType == 'B' ? 'complete' : 'none',
        userPreferenceSummary: profileType == 'B' ? 'Prefers low-risk wealth creation' : 'New saver',
        primaryGoal: profileType == 'B' ? 'Wealth Creation' : 'Emergency Fund',
        riskLevel: profileType == 'B' ? 'Medium' : 'Low',
        actionHistory: [],
        lastSeenProfile: profileType,
        userPatternSummary: profileType == 'B' ? 'Regular monthly saver. Prefers auto-investing.' : 'Manual saver. Highly reactive to UPI payments.',
        suggestionCooldownMap: const {},
      );
      saveMemory();
    }
  }

  void saveMemory() {
    final box = Hive.box(kAgentMemoryBox);
    box.put('memory_$profileType', state.toJson());
  }

  void updateMemory(AgentMemory newMemory) {
    state = newMemory;
    saveMemory();
  }

  void setKYCCompleted() {
    state = state.copyWith(onboardingCompleted: true, kycStep: 'complete');
    saveMemory();
  }

  void updateKYCStep(String step) {
    state = state.copyWith(kycStep: step, onboardingCompleted: step == 'complete');
    saveMemory();
  }

  void setLastDetectedSignal(SignalSummary signal) {
    state = state.copyWith(lastDetectedSignal: signal);
    saveMemory();
  }

  void setLastRecommendedAction(String action) {
    state = state.copyWith(lastRecommendedAction: action);
    saveMemory();
  }

  void logToolExecution(String toolName) {
    final history = [...state.actionHistory, toolName];
    if (history.length > 50) {
      history.removeAt(0);
    }
    state = state.copyWith(
      lastExecutedTool: toolName,
      actionHistory: history,
      lastActionCompleted: toolName,
    );
    saveMemory();
  }

  void updatePreferences(String pref) {
    state = state.copyWith(userPreferenceSummary: pref);
    saveMemory();
  }

  void updateSIPDate(String date) {
    state = state.copyWith(lastSIPDate: date);
    saveMemory();
  }

  void updateSalaryDate(String date) {
    state = state.copyWith(lastSalaryDate: date);
    saveMemory();
  }

  void updateCooldown(String key, int timestamp) {
    final updatedMap = Map<String, int>.from(state.suggestionCooldownMap);
    updatedMap[key] = timestamp;
    state = state.copyWith(suggestionCooldownMap: updatedMap);
    saveMemory();
  }

  void updateProactiveState({
    String? lastSeenProfile,
    String? lastWelcomeMessage,
    String? lastProactiveSuggestion,
    int? lastRecommendationTimestamp,
    String? lastTriggeredSignal,
    String? lastActionCompleted,
    String? userPatternSummary,
  }) {
    state = state.copyWith(
      lastSeenProfile: lastSeenProfile ?? state.lastSeenProfile,
      lastWelcomeMessage: lastWelcomeMessage ?? state.lastWelcomeMessage,
      lastProactiveSuggestion: lastProactiveSuggestion ?? state.lastProactiveSuggestion,
      lastRecommendationTimestamp: lastRecommendationTimestamp ?? state.lastRecommendationTimestamp,
      lastTriggeredSignal: lastTriggeredSignal ?? state.lastTriggeredSignal,
      lastActionCompleted: lastActionCompleted ?? state.lastActionCompleted,
      userPatternSummary: userPatternSummary ?? state.userPatternSummary,
    );
    saveMemory();
  }

  void reset() {
    state = AgentMemory(
      activeProfileType: profileType,
      onboardingCompleted: profileType == 'B',
      kycStep: profileType == 'B' ? 'complete' : 'none',
      userPreferenceSummary: profileType == 'B' ? 'Prefers low-risk wealth creation' : 'New saver',
      primaryGoal: profileType == 'B' ? 'Wealth Creation' : 'Emergency Fund',
      riskLevel: profileType == 'B' ? 'Medium' : 'Low',
      actionHistory: [],
      lastSeenProfile: profileType,
      userPatternSummary: profileType == 'B' ? 'Regular monthly saver. Prefers auto-investing.' : 'Manual saver. Highly reactive to UPI payments.',
      suggestionCooldownMap: const {},
    );
    saveMemory();
  }
}

final agentMemoryProvider = StateNotifierProvider<AgentMemoryNotifier, AgentMemory>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return AgentMemoryNotifier(profileType);
});
