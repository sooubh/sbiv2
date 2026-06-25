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
const String kFDBox = 'fd_box';
const String kSipBox = 'sip_box';
const String kLoanBox = 'loan_box';
const String kBudgetBox = 'budget_box';
const String kOnboardingChatBox = 'onboarding_chat_box';
const String kBankingChatBox = 'banking_chat_box';

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
  await Hive.openBox(kFDBox);
  await Hive.openBox(kSipBox);
  await Hive.openBox(kLoanBox);
  await Hive.openBox(kBudgetBox);
  await Hive.openBox(kOnboardingChatBox);
  await Hive.openBox(kBankingChatBox);
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

  void reset() {
    state = 'B';
    Hive.box(kSystemBox).put('active_profile', 'B');
  }
}

// Language Provider: 'en' (English) or 'hi' (Hindi)
final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, String>((ref) {
  return AppLanguageNotifier();
});

class AppLanguageNotifier extends StateNotifier<String> {
  AppLanguageNotifier() : super('en') {
    final box = Hive.box(kSystemBox);
    state = box.get('app_language', defaultValue: 'en');
  }

  void setLanguage(String lang) {
    state = lang;
    Hive.box(kSystemBox).put('app_language', lang);
  }

  void reset() {
    state = 'en';
    Hive.box(kSystemBox).put('app_language', 'en');
  }
}

// Hands-free Voice Provider
final handsFreeVoiceProvider = StateProvider<bool>((ref) => false);


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

  void takeQuiz(bool isCorrect) {
    state = state.copyWith(
      sbiCoins: state.sbiCoins + (isCorrect ? 50 : 10),
      lastQuizTakenTimestamp: DateTime.now().millisecondsSinceEpoch,
      quizStreak: isCorrect ? state.quizStreak + 1 : 0,
    );
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
  final String? toolStatus; // "pending", "approved", "rejected"
  final String? toolCallId; // Unique ID to identify which functionCall needs approval

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.toolCall,
    this.toolStatus,
    this.toolCallId,
  });

  ChatMessage copyWith({
    String? sender,
    String? text,
    DateTime? timestamp,
    Map<String, dynamic>? toolCall,
    String? toolStatus,
    String? toolCallId,
  }) {
    return ChatMessage(
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      toolCall: toolCall ?? this.toolCall,
      toolStatus: toolStatus ?? this.toolStatus,
      toolCallId: toolCallId ?? this.toolCallId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'toolCall': toolCall,
      'toolStatus': toolStatus,
      'toolCallId': toolCallId,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      toolCall: json['toolCall'] != null ? Map<String, dynamic>.from(json['toolCall'] as Map) : null,
      toolStatus: json['toolStatus'] as String?,
      toolCallId: json['toolCallId'] as String?,
    );
  }
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
    _loadMessages();
  }

  void _loadMessages() {
    final boxName = isOnboarding ? kOnboardingChatBox : kBankingChatBox;
    final box = Hive.box(boxName);
    final cached = box.get('messages');
    if (cached != null) {
      final list = List<dynamic>.from(cached);
      state = list.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      reset();
    }
  }

  void _saveMessages() {
    final boxName = isOnboarding ? kOnboardingChatBox : kBankingChatBox;
    final box = Hive.box(boxName);
    box.put('messages', state.map((e) => e.toJson()).toList());
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
    _saveMessages();
  }

  void updateMessageStatus(String toolCallId, String status) {
    state = state.map((msg) {
      if (msg.toolCallId == toolCallId) {
        return msg.copyWith(toolStatus: status);
      }
      return msg;
    }).toList();
    _saveMessages();
  }

  void clearChat() {
    final boxName = isOnboarding ? kOnboardingChatBox : kBankingChatBox;
    Hive.box(boxName).clear();
    reset();
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
    _saveMessages();
  }
}

// ── Agent Timeline ────────────────────────────────────────────────────────────

class TimelineNotifier extends StateNotifier<List<TimelineEntry>> {
  static const int _maxEntries = 50;
  final String profileType;

  TimelineNotifier(this.profileType) : super([]) {
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
    Hive.box(kTimelineBox).delete('entries_$profileType');
  }

  void reset() {
    clear();
  }

  void _save() {
    final box = Hive.box(kTimelineBox);
    box.put('entries_$profileType', state.map((e) => e.toJson()).toList());
  }

  void _load() {
    final box = Hive.box(kTimelineBox);
    final raw = box.get('entries_$profileType');
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
  final profileType = ref.watch(profileTypeProvider);
  return TimelineNotifier(profileType);
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
    liveModel: 'models/gemini-3.1-flash-live-preview',
    restModel: 'gemini-2.5-flash',
  )) {
    final box = Hive.box(kSystemBox);
    var savedLive = box.get('ai_live_model', defaultValue: 'models/gemini-3.1-flash-live-preview') as String;
    final savedRest = box.get('ai_rest_model', defaultValue: 'gemini-2.5-flash') as String;

    // AUTO-MIGRATION: Replace deprecated/shutdown live models with the current default.
    // This prevents users who previously saved an old model from hitting WebSocket 1007 errors.
    const deprecatedModels = <String>{
      'models/gemini-2.0-flash-live-001',
      'models/gemini-live-2.5-flash-preview-native-audio',
      'models/gemini-2.0-flash-live',
      'gemini-2.0-flash-live-001',
      'gemini-live-2.5-flash-preview-native-audio',
      'gemini-2.0-flash-live',
    };
    if (deprecatedModels.contains(savedLive)) {
      savedLive = 'models/gemini-3.1-flash-live-preview';
      box.put('ai_live_model', savedLive);
    }

    state = AiModelConfig(liveModel: savedLive, restModel: savedRest);
  }

  void updateModels({String? liveModel, String? restModel}) {
    state = state.copyWith(liveModel: liveModel, restModel: restModel);
    final box = Hive.box(kSystemBox);
    if (liveModel != null) box.put('ai_live_model', liveModel);
    if (restModel != null) box.put('ai_rest_model', restModel);
  }

  void reset() {
    state = const AiModelConfig(
      liveModel: 'models/gemini-3.1-flash-live-preview',
      restModel: 'gemini-2.5-flash',
    );
    final box = Hive.box(kSystemBox);
    box.put('ai_live_model', state.liveModel);
    box.put('ai_rest_model', state.restModel);
  }
}

final aiModelConfigProvider = StateNotifierProvider<AiModelConfigNotifier, AiModelConfig>((ref) {
  return AiModelConfigNotifier();
});

final currentNavIndexProvider = StateProvider<int>((ref) => 0);

// FD List Provider
final fdListProvider = StateNotifierProvider<FDListNotifier, List<FixedDeposit>>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return FDListNotifier(profileType);
});

class FDListNotifier extends StateNotifier<List<FixedDeposit>> {
  final String profileType;

  FDListNotifier(this.profileType) : super([]) {
    loadFDs();
  }

  void loadFDs() {
    final box = Hive.box(kFDBox);
    final key = 'fds_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      final list = List<dynamic>.from(cached);
      state = list.map((e) => FixedDeposit.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      state = profileType == 'A' ? [] : [
        FixedDeposit(
          id: 'fd_01',
          title: 'Tax Saving FD',
          principalAmount: 50000.0,
          interestRate: 7.10,
          maturityDate: DateTime.now().add(const Duration(days: 14)),
          isAutoRenew: true,
        ),
        FixedDeposit(
          id: 'fd_02',
          title: 'Standard FD (1 Yr)',
          principalAmount: 100000.0,
          interestRate: 6.80,
          maturityDate: DateTime.now().add(const Duration(days: 240)),
          isAutoRenew: false,
        ),
      ];
      saveFDs();
    }
  }

  void saveFDs() {
    final box = Hive.box(kFDBox);
    box.put('fds_$profileType', state.map((e) => e.toJson()).toList());
  }

  void openFD(String title, double amount, {bool autoRenew = false, double rate = 7.20}) {
    final fd = FixedDeposit(
      id: 'fd_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      principalAmount: amount,
      interestRate: rate,
      maturityDate: DateTime.now().add(const Duration(days: 365)),
      isAutoRenew: autoRenew,
    );
    state = [...state, fd];
    saveFDs();
  }

  void closeFD(String id) {
    state = state.where((fd) => fd.id != id).toList();
    saveFDs();
  }

  void toggleAutoRenew(String id) {
    state = state.map((fd) {
      if (fd.id == id) {
        return fd.copyWith(isAutoRenew: !fd.isAutoRenew);
      }
      return fd;
    }).toList();
    saveFDs();
  }

  void reset() {
    Hive.box(kFDBox).delete('fds_$profileType');
    loadFDs();
  }
}

// SIP List Provider
final sipListProvider = StateNotifierProvider<SipListNotifier, List<SipInvestment>>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return SipListNotifier(profileType);
});

class SipListNotifier extends StateNotifier<List<SipInvestment>> {
  final String profileType;

  SipListNotifier(this.profileType) : super([]) {
    loadSIPs();
  }

  void loadSIPs() {
    final box = Hive.box(kSipBox);
    final key = 'sips_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      final list = List<dynamic>.from(cached);
      state = list.map((e) => SipInvestment.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      state = profileType == 'A' ? [] : [
        SipInvestment(
          id: 'sip_01',
          fundName: 'SBI Bluechip Fund',
          amount: 10000.0,
          nextPaymentDate: '12th of every month',
          category: 'Large Cap',
          status: 'active',
        ),
        SipInvestment(
          id: 'sip_02',
          fundName: 'SBI Small Cap Fund',
          amount: 5000.0,
          nextPaymentDate: '5th of every month',
          category: 'Small Cap',
          status: 'active',
        ),
      ];
      saveSIPs();
    }
  }

  void saveSIPs() {
    final box = Hive.box(kSipBox);
    box.put('sips_$profileType', state.map((e) => e.toJson()).toList());
  }

  void createSIP(String fundName, double amount, {String category = 'Equity'}) {
    final sip = SipInvestment(
      id: 'sip_${DateTime.now().millisecondsSinceEpoch}',
      fundName: fundName,
      amount: amount,
      nextPaymentDate: '15th of every month',
      category: category,
      status: 'active',
    );
    state = [...state, sip];
    saveSIPs();
  }

  void updateSIP(String id, double newAmount) {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(amount: newAmount);
      }
      return s;
    }).toList();
    saveSIPs();
  }

  void cancelSIP(String id) {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(status: 'cancelled');
      }
      return s;
    }).toList();
    saveSIPs();
  }

  void reset() {
    Hive.box(kSipBox).delete('sips_$profileType');
    loadSIPs();
  }
}

// Loan List Provider
final loanListProvider = StateNotifierProvider<LoanListNotifier, List<Loan>>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return LoanListNotifier(profileType);
});

class LoanListNotifier extends StateNotifier<List<Loan>> {
  final String profileType;

  LoanListNotifier(this.profileType) : super([]) {
    loadLoans();
  }

  void loadLoans() {
    final box = Hive.box(kLoanBox);
    final key = 'loans_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      final list = List<dynamic>.from(cached);
      state = list.map((e) => Loan.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      state = profileType == 'A' ? [] : [
        Loan(
          id: 'loan_01',
          title: 'Home Loan',
          accountNumber: 'XXXXX8901',
          outstandingBalance: 3245000.0,
          emiAmount: 28500.0,
          nextDueDate: '5th Jul',
          percentRepaid: 0.15,
        )
      ];
      saveLoans();
    }
  }

  void saveLoans() {
    final box = Hive.box(kLoanBox);
    box.put('loans_$profileType', state.map((e) => e.toJson()).toList());
  }

  void payEMI(String loanId, double amount) {
    state = state.map((l) {
      if (l.id == loanId) {
        final outstanding = (l.outstandingBalance - amount).clamp(0.0, double.infinity);
        final repaid = 1.0 - (outstanding / 3800000.0); // Assume original outstanding was ~38L
        return l.copyWith(
          outstandingBalance: outstanding,
          percentRepaid: repaid.clamp(0.0, 1.0),
        );
      }
      return l;
    }).toList();
    saveLoans();
  }

  void prepayLoan(String loanId, double amount) {
    state = state.map((l) {
      if (l.id == loanId) {
        final outstanding = (l.outstandingBalance - amount).clamp(0.0, double.infinity);
        final repaid = 1.0 - (outstanding / 3800000.0);
        return l.copyWith(
          outstandingBalance: outstanding,
          percentRepaid: repaid.clamp(0.0, 1.0),
        );
      }
      return l;
    }).toList();
    saveLoans();
  }

  void reset() {
    Hive.box(kLoanBox).delete('loans_$profileType');
    loadLoans();
  }
}

// Budget Provider
final budgetProvider = StateNotifierProvider<BudgetNotifier, Budget>((ref) {
  final profileType = ref.watch(profileTypeProvider);
  return BudgetNotifier(profileType);
});

class BudgetNotifier extends StateNotifier<Budget> {
  final String profileType;

  BudgetNotifier(this.profileType) : super(Budget(spent: 0, limit: 0, categoryLimits: {}, categorySpent: {})) {
    loadBudget();
  }

  void loadBudget() {
    final box = Hive.box(kBudgetBox);
    final key = 'budget_$profileType';
    final cached = box.get(key);
    if (cached != null) {
      state = Budget.fromJson(Map<String, dynamic>.from(cached));
    } else {
      state = Budget(
        spent: 32000.0,
        limit: 45000.0,
        categoryLimits: {
          'Rent & Utilities': 15000.0,
          'Food & Dining': 10000.0,
          'Shopping': 8000.0,
          'Others': 12000.0,
        },
        categorySpent: {
          'Rent & Utilities': 15000.0,
          'Food & Dining': 8500.0,
          'Shopping': 5000.0,
          'Others': 3500.0,
        },
      );
      saveBudget();
    }
  }

  void saveBudget() {
    final box = Hive.box(kBudgetBox);
    box.put('budget_$profileType', state.toJson());
  }

  void setBudgetLimit(double limit) {
    state = state.copyWith(limit: limit);
    saveBudget();
  }

  void setCategoryLimit(String category, double limit) {
    final updatedLimits = Map<String, double>.from(state.categoryLimits);
    updatedLimits[category] = limit;
    state = state.copyWith(categoryLimits: updatedLimits);
    saveBudget();
  }

  void addExpense(String category, double amount) {
    final updatedSpent = Map<String, double>.from(state.categorySpent);
    updatedSpent[category] = (updatedSpent[category] ?? 0.0) + amount;
    final totalSpent = state.spent + amount;
    state = state.copyWith(spent: totalSpent, categorySpent: updatedSpent);
    saveBudget();
  }

  void reset() {
    Hive.box(kBudgetBox).delete('budget_$profileType');
    loadBudget();
  }
}
