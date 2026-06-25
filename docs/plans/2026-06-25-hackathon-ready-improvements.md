# Hackathon Ready Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform the YONO SBI 2.0 app from an MVP into a premium, hackathon-ready demo by introducing persistent chat history, a gamified daily quiz and levels hub, interactive onboarding step recovery, and a centralized notification panel.

**Architecture:**
1. **Persistent Onboarding & Chat History:** Integrate Hive storage boxes for ChatMessage logs (`onboarding_chat` and `banking_chat`). Automatically load historical logs, and cache incomplete onboarding profiles to restore steps.
2. **Interactive Gamification & Daily Quiz:** Implement quiz state inside the engagement notifier, rendering a modern bento quiz card and tier progression rings.
3. **Notification Hub Overlay:** Construct a notification bell in the bottom nav shell that gathers all unresolved agent recommendations into a central action tray.

**Tech Stack:** Flutter, Riverpod, Hive, Google Fonts, HugeIcons

---

### Task 1: Persistent Onboarding & Chat History

**Files:**
- Modify: `lib/data/repositories/state_providers.dart`
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Modify: `lib/features/ai_chat/ai_chat_screen.dart`

**Step 1: Define Hive Boxes and Chat Serialization**
In `lib/data/repositories/state_providers.dart`:
- Add Hive box constants:
  ```dart
  const String kOnboardingChatBox = 'onboarding_chat_box';
  const String kBankingChatBox = 'banking_chat_box';
  ```
- Open these boxes in `initHive()`.
- Add serialization methods to `ChatMessage` (toJson / fromJson) to support local storage.
- Update `ChatMessagesNotifier` to initialize by reading from its respective Hive box, falling back to the default message only if the box is empty. Save messages to Hive on `addMessage` and `updateMessageStatus`.
- Implement `clearChat()` method in `ChatMessagesNotifier` to wipe history.

**Step 2: Auto-Resume Onboarding Step Recovery**
In `lib/features/onboarding/onboarding_screen.dart`:
- Read onboarding step state directly from `userProfileProvider` (which is already persisted in Hive).
- In `initState`, if `profile.name` is not empty, display a resume dialog or notification banner greeting Rohan back and asking if they want to continue onboarding from the active step (e.g., PAN or Aadhaar).

---

### Task 2: Gamification Daily Quiz & Level Progression

**Files:**
- Modify: `lib/data/models/models.dart`
- Modify: `lib/data/repositories/state_providers.dart`
- Modify: `lib/features/engagement/engagement_screen.dart`

**Step 1: Model & Provider Updates**
- Update `EngagementState` to include `lastQuizTakenDate` (String or int timestamp) and `quizStreak` (int).
- In `EngagementNotifier`, add:
  ```dart
  void takeQuiz(bool isCorrect) {
    state = state.copyWith(
      sbiCoins: state.sbiCoins + (isCorrect ? 50 : 10),
      // update dates and achievements...
    );
    saveEngagement();
  }
  ```

**Step 2: Add Daily Financial Quiz Card**
In `lib/features/engagement/engagement_screen.dart`:
- Render a visually premium "Daily Financial Quiz" bento card.
- Question: "Which of the following describes the power of compounding interest?"
  - A) Earning interest only on original principal
  - B) Earning interest on principal + accumulated interest (Correct)
  - C) Paying off debt early
- Allow the user to select an option. Give an animated checkmark, add 50 SBI Coins if correct, and disable the card until the next day (persisted in Hive).

**Step 3: Level Progression Breakdown**
- Display a visually gorgeous visual circular progress bar indicating levels (Bronze, Silver, Gold, Platinum) with custom icons and milestone rewards (e.g., "50 coins to Silver Saver").
- Add a breakdown showing how the current Financial Health Score is computed (e.g., "KYC completed: +30", "Active SIP: +40", "UPI setup: +30").

---

### Task 3: Notification Hub & Alert Badge

**Files:**
- Modify: `lib/features/navigation/bottom_nav_shell.dart`

**Step 1: Add Notification Bell & Badge**
In `lib/features/navigation/bottom_nav_shell.dart` top App Bar actions:
- Insert a bell icon button with a badge showing the count of uncompleted/active recommendations from `recommendationsProvider`.
- Set badge color to `AppTheme.accentOrange`.

**Step 2: Notification Action Tray**
- Clicking the bell opens a styled Modal Bottom Sheet ("Notifications Center").
- Displays all unresolved/pending "Agent Noticed Feed" cards inside the bottom sheet.
- Each alert displays the recommendation title, description, and direct primary action button (e.g., "Resume SIP", "Open FD") that triggers the respective tool call, allowing instant feature access from any page.

---

### Task 4: UI Celebrations & Shortcuts

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Modify: `lib/features/ai_chat/ai_chat_screen.dart`

**Step 1: Celebratory Dialogs**
- When Rohan finishes Aadhaar verification or Video KYC, display an elegant celebratory fullscreen modal/dialog stating "Verification Successful!" with an overlay showing +50 Coins.

**Step 2: Chat Shortcut Chips**
- On `ai_chat_screen.dart`, add shortcut action chips at the top of the input area (e.g. "Prepay Home Loan", "Check Health Score", "Resume SIP") that automatically submit the text query and trigger the agent's response.
