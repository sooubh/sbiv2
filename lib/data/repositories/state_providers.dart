import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sbiv2/data/mock/mock_data.dart';
import 'package:sbiv2/data/models/models.dart';
import 'package:sbiv2/features/agent/models/timeline_entry.dart';

// Hive Box Names
const String kProfileBox = 'profile_box';
const String kTransactionsBox = 'transactions_box';
const String kGoalsBox = 'goals_box';
const String kRecommendationsBox = 'recommendations_box';
const String kServicesBox = 'services_box';
const String kEngagementBox = 'engagement_box';
const String kSystemBox = 'system_box'; // stores current profile type
const String kAgentMemoryBox = 'agent_memory_box';
const String kTimelineBox = 'timeline_box';

// Initializer function for Hive
Future<void> initHive() async {
  await Hive.initFlutter();
  await Hive.openBox(kProfileBox);
  await Hive.openBox(kTransactionsBox);
  await Hive.openBox(kGoalsBox);
  await Hive.openBox(kRecommendationsBox);
  await Hive.openBox(kServicesBox);
  await Hive.openBox(kEngagementBox);
  await Hive.openBox(kSystemBox);
  await Hive.openBox(kAgentMemoryBox);
  await Hive.openBox(kTimelineBox);
}

// Profile Type: 'A' (Rohan, new) or 'B' (Sourabh, existing)
final profileTypeProvider = StateNotifierProvider<ProfileTypeNotifier, String>((ref) {
  return ProfileTypeNotifier();
});

class ProfileTypeNotifier extends StateNotifier<String> {
  ProfileTypeNotifier() : super('B') {
    final box = Hive.box(kSystemBox);
    state = box.get('active_profile', defaultValue: 'B');
  }

  void setProfile(String type) {
    state = type;
    Hive.box(kSystemBox).put('active_profile', type);
  }
}

// Track PIN login status for the existing customer (Sourabh)
final isLoggedInProvider = StateProvider<bool>((ref) => false);

// User Profile Notifier
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return UserProfileNotifier(profileType);
});

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final String profileType;

  UserProfileNotifier(this.profileType) : super(MockData.profileB) {
    loadProfile();
  }

  void loadProfile() {
    final box = Hive.box(kProfileBox);
    final key = 'profile_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      state = UserProfile.fromJson(Map<String, dynamic>.from(cached));
    } else {
      // Default fallback
      state = profileType == 'A' ? MockData.profileA : MockData.profileB;
      saveProfile();
    }
  }

  void saveProfile() {
    final box = Hive.box(kProfileBox);
    box.put('profile_$profileType', state.toJson());
  }

  void updateProfile(UserProfile newProfile) {
    state = newProfile;
    saveProfile();
  }

  void updateBalance(double amount) {
    state = state.copyWith(balance: state.balance + amount);
    saveProfile();
  }

  void setBalance(double balance) {
    state = state.copyWith(balance: balance);
    saveProfile();
  }

  void updateKYCStep(String step) {
    bool complete = step == 'complete';
    state = state.copyWith(kycStep: step, kycComplete: complete);
    saveProfile();
  }

  void enableUPI(bool enabled) {
    state = state.copyWith(upiEnabled: enabled);
    saveProfile();
  }

  void updateQualifyData({required String incomeBracket, required String bankingNeed, required String existingBank}) {
    state = state.copyWith(
      incomeBracket: incomeBracket,
      bankingNeed: bankingNeed,
      existingBank: existingBank,
    );
    saveProfile();
  }

  void clearForOnboarding() {
    state = UserProfile(
      name: '',
      balance: 5000.0,
      kycComplete: false,
      kycStep: 'none',
      upiEnabled: false,
      incomeBracket: '0-5 Lakhs',
      bankingNeed: 'Savings & UPI',
      existingBank: 'None',
      healthScore: 40,
      mobileNumber: '',
      address: '',
    );
    saveProfile();
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
    saveProfile();
  }

  void updateMobileNumber(String mobileNumber) {
    state = state.copyWith(mobileNumber: mobileNumber);
    saveProfile();
  }

  void updateAddress(String address) {
    state = state.copyWith(address: address);
    saveProfile();
  }

  void reset() {
    state = profileType == 'A' ? MockData.profileA : MockData.profileB;
    saveProfile();
  }
}

// Transactions Notifier
final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return TransactionsNotifier(profileType);
});

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final String profileType;

  TransactionsNotifier(this.profileType) : super([]) {
    loadTransactions();
  }

  void loadTransactions() {
    final box = Hive.box(kTransactionsBox);
    final key = 'txs_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      final list = List<dynamic>.from(cached);
      state = list.map((e) => Transaction.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      state = profileType == 'A' ? MockData.transactionsA : MockData.transactionsB;
      saveTransactions();
    }
  }

  void saveTransactions() {
    final box = Hive.box(kTransactionsBox);
    box.put('txs_$profileType', state.map((e) => e.toJson()).toList());
  }

  void addTransaction(Transaction tx) {
    state = [tx, ...state];
    saveTransactions();
  }

  void removeSIPTransactions() {
    state = state.where((tx) => !(tx.payee.contains('SIP') || tx.payee.contains('Mutual Fund'))).toList();
    saveTransactions();
  }

  void reset() {
    state = profileType == 'A' ? MockData.transactionsA : MockData.transactionsB;
    saveTransactions();
  }
}

// Goals Notifier
final goalsProvider = StateNotifierProvider<GoalsNotifier, List<Goal>>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return GoalsNotifier(profileType);
});

class GoalsNotifier extends StateNotifier<List<Goal>> {
  final String profileType;

  GoalsNotifier(this.profileType) : super([]) {
    loadGoals();
  }

  void loadGoals() {
    final box = Hive.box(kGoalsBox);
    final key = 'goals_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      final list = List<dynamic>.from(cached);
      state = list.map((e) => Goal.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      state = MockData.mockGoals;
      saveGoals();
    }
  }

  void saveGoals() {
    final box = Hive.box(kGoalsBox);
    box.put('goals_$profileType', state.map((e) => e.toJson()).toList());
  }

  void addGoal(Goal goal) {
    state = [...state, goal];
    saveGoals();
  }

  void boostGoal(String goalId, double amount) {
    state = state.map((g) {
      if (g.id == goalId) {
        return g.copyWith(savedAmount: g.savedAmount + amount);
      }
      return g;
    }).toList();
    saveGoals();
  }

  void reset() {
    state = MockData.mockGoals;
    saveGoals();
  }
}

// Recommendations Notifier
final recommendationsProvider = StateNotifierProvider<RecommendationsNotifier, List<Recommendation>>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return RecommendationsNotifier(profileType);
});

class RecommendationsNotifier extends StateNotifier<List<Recommendation>> {
  final String profileType;

  RecommendationsNotifier(this.profileType) : super([]) {
    loadRecommendations();
  }

  void loadRecommendations() {
    final box = Hive.box(kRecommendationsBox);
    final key = 'recs_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      final list = List<dynamic>.from(cached);
      state = list.map((e) => Recommendation.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      state = MockData.mockRecommendations;
      saveRecommendations();
    }
  }

  void saveRecommendations() {
    final box = Hive.box(kRecommendationsBox);
    box.put('recs_$profileType', state.map((e) => e.toJson()).toList());
  }

  void completeRecommendation(String id) {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(isCompleted: true);
      }
      return r;
    }).toList();
    saveRecommendations();
  }

  void addRecommendation(Recommendation rec) {
    // Remove if already exists to update priority or content
    state = [rec, ...state.where((r) => r.id != rec.id)].toList();
    state.sort((a, b) => a.priority.compareTo(b.priority));
    saveRecommendations();
  }

  void reset() {
    state = MockData.mockRecommendations;
    saveRecommendations();
  }
}

// Services Notifier
final servicesProvider = StateNotifierProvider<ServicesNotifier, List<Service>>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return ServicesNotifier(profileType);
});

class ServicesNotifier extends StateNotifier<List<Service>> {
  final String profileType;

  ServicesNotifier(this.profileType) : super([]) {
    loadServices();
  }

  void loadServices() {
    final box = Hive.box(kServicesBox);
    final key = 'services_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      final list = List<dynamic>.from(cached);
      state = list.map((e) => Service.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      state = MockData.mockServices;
      saveServices();
    }
  }

  void saveServices() {
    final box = Hive.box(kServicesBox);
    box.put('services_$profileType', state.map((e) => e.toJson()).toList());
  }

  void activateService(String id) {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(isActivated: true);
      }
      return s;
    }).toList();
    saveServices();
  }

  void recommendService(String id, String reason) {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(isRecommended: true, aiReason: reason);
      }
      return s;
    }).toList();
    saveServices();
  }

  void reset() {
    state = MockData.mockServices;
    saveServices();
  }
}

// Engagement Notifier
final engagementProvider = StateNotifierProvider<EngagementNotifier, EngagementState>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return EngagementNotifier(profileType);
});

class EngagementNotifier extends StateNotifier<EngagementState> {
  final String profileType;

  EngagementNotifier(this.profileType) : super(MockData.mockEngagement) {
    loadEngagement();
  }

  void loadEngagement() {
    final box = Hive.box(kEngagementBox);
    final key = 'engagement_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      state = EngagementState.fromJson(Map<String, dynamic>.from(cached));
    } else {
      state = MockData.mockEngagement;
      saveEngagement();
    }
  }

  void saveEngagement() {
    final box = Hive.box(kEngagementBox);
    box.put('engagement_$profileType', state.toJson());
  }

  void addCoins(int count) {
    state = state.copyWith(sbiCoins: state.sbiCoins + count);
    saveEngagement();
  }

  void addAchievement(String achievement) {
    if (!state.achievements.contains(achievement)) {
      state = state.copyWith(achievements: [...state.achievements, achievement]);
      saveEngagement();
    }
  }

  void reset() {
    state = MockData.mockEngagement;
    saveEngagement();
  }
}

// Simple Chat Message Model for UI
class ChatMessage {
  final String sender; // "user", "agent", "system", "tool"
  final String text;
  final DateTime timestamp;
  final Map<String, dynamic>? toolCall; // Optional tool call metadata

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.toolCall,
  });
}

// Onboarding Chat Messages Notifier
final onboardingChatProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier(isOnboarding: true);
});

// General Banking Assistant Chat Messages Notifier
final bankingChatProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier(isOnboarding: false);
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final bool isOnboarding;

  ChatMessagesNotifier({required this.isOnboarding}) : super([]) {
    reset();
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void reset() {
    if (isOnboarding) {
      state = [
        ChatMessage(
          sender: 'agent',
          text: 'Namaste! SBI mein khata kholna chahte hain?',
          timestamp: DateTime.now(),
        ),
      ];
    } else {
      state = [
        ChatMessage(
          sender: 'agent',
          text: 'Hello! I am your YONO SBI 2.0 Agent. How can I help you today?\nYou can ask me to "Send Money", "Open FD", "Check Balance", or check your "Financial Health".',
          timestamp: DateTime.now(),
        ),
      ];
    }
  }
}

// ── Agent Timeline ────────────────────────────────────────────────────────────

class TimelineNotifier extends StateNotifier<List<TimelineEntry>> {
  static const int _maxEntries = 50;

  TimelineNotifier() : super([]) {
    _load();
  }

  /// Adds a new entry at the front (newest first). Trims to 50.
  void addEntry(TimelineEntry entry) {
    final updated = [entry, ...state];
    if (updated.length > _maxEntries) {
      updated.removeLast();
    }
    state = updated;
    _save();
  }

  /// Convenience factory caller to reduce boilerplate at call sites.
  void log({
    required TimelineEntryType type,
    required String title,
    required String description,
    required TimelineEntryStatus status,
  }) {
    addEntry(TimelineEntry.create(
      type: type,
      title: title,
      description: description,
      status: status,
    ));
  }

  void clear() {
    state = [];
    Hive.box(kTimelineBox).clear();
  }

  void _save() {
    final box = Hive.box(kTimelineBox);
    box.put('entries', state.map((e) => e.toJson()).toList());
  }

  void _load() {
    final box = Hive.box(kTimelineBox);
    final raw = box.get('entries');
    if (raw != null) {
      try {
        final list = List<dynamic>.from(raw);
        state = list
            .map((e) => TimelineEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }
}

final timelineProvider =
    StateNotifierProvider<TimelineNotifier, List<TimelineEntry>>((ref) {
  return TimelineNotifier();
});

class AiModelConfig {
  final String liveModel;
  final String restModel;

  const AiModelConfig({
    required this.liveModel,
    required this.restModel,
  });

  AiModelConfig copyWith({
    String? liveModel,
    String? restModel,
  }) {
    return AiModelConfig(
      liveModel: liveModel ?? this.liveModel,
      restModel: restModel ?? this.restModel,
    );
  }
}

class AiModelConfigNotifier extends StateNotifier<AiModelConfig> {
  AiModelConfigNotifier() : super(const AiModelConfig(
    liveModel: 'models/gemini-2.0-flash-live-001',
    restModel: 'gemini-2.0-flash',
  )) {
    final box = Hive.box(kSystemBox);
    final savedLive = box.get('ai_live_model', defaultValue: 'models/gemini-2.0-flash-live-001');
    final savedRest = box.get('ai_rest_model', defaultValue: 'gemini-2.0-flash');
    state = AiModelConfig(liveModel: savedLive, restModel: savedRest);
  }

  void updateModels({String? liveModel, String? restModel}) {
    state = state.copyWith(liveModel: liveModel, restModel: restModel);
    final box = Hive.box(kSystemBox);
    if (liveModel != null) box.put('ai_live_model', liveModel);
    if (restModel != null) box.put('ai_rest_model', restModel);
  }
}

final aiModelConfigProvider = StateNotifierProvider<AiModelConfigNotifier, AiModelConfig>((ref) {
  return AiModelConfigNotifier();
});

final currentNavIndexProvider = StateProvider<int>((ref) => 0);
