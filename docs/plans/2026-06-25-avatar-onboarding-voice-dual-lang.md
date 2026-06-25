# Onboarding & AI Voice Dual Language Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement a single avatar-based interactive onboarding flow with Hindi/English support, dual-mode speech/text input (including hands-free auto-listening), smart proactive suggestions when confused, and a modern clean UI.

**Architecture:**
1. **Dynamic Language & Hands-Free Providers:** Add `appLanguageProvider` ('en'/'hi') and `handsFreeVoiceProvider` (bool) in `state_providers.dart` to support speech recognition / text-to-speech locale switching and auto-microphone triggering.
2. **Interactive AIAvatar Widget:** Design a highly polished custom animated AI Avatar widget reacting to thinking, speaking, listening, and idle states with custom face animations.
3. **Dual Language Onboarding & Chat prompts:** Enhance the coordinator and simulated fallback system to support clear Devanagari Hindi text and Hindi voice input/output.
4. **Smart Proactive Suggestion & Help System:** Add context-aware help shortcut buttons on onboarding and chat pages for confused users.

**Tech Stack:** Flutter, Riverpod, Hive, Speech-to-Text, Flutter-TTS

---

### Task 1: Add Language & Hands-Free States

**Files:**
- Modify: `lib/data/repositories/state_providers.dart`
- Modify: `lib/ai/voice/voice_service.dart`

**Step 1: Define Providers**
In `lib/data/repositories/state_providers.dart`:
- Add `appLanguageProvider` StateNotifier (persisted in `kSystemBox` Hive box under key `'app_language'`, defaulting to `'en'`).
- Add `handsFreeVoiceProvider` StateProvider (boolean, defaulting to `false`).

**Step 2: Update VoiceService for Language and Hands-Free Auto-Listen**
In `lib/ai/voice/voice_service.dart`:
- In `startListening()`: read language from `appLanguageProvider`. Set `localeId` to `'hi_IN'` if language is `'hi'`, else `'en_IN'`.
- In `speak()`: read language from `appLanguageProvider`. Set TTS language via `await _tts.setLanguage(lang == 'hi' ? 'hi-IN' : 'en-IN')` before speaking.
- In `_onTtsDone()`: if `handsFreeVoiceProvider` is active, wait 600ms and automatically call `startListening()`.

---

### Task 2: Create Custom Animated AIAvatar Widget

**Files:**
- Create: `lib/features/agent/widgets/ai_avatar.dart`
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Modify: `lib/features/ai_chat/ai_chat_screen.dart`

**Step 1: Create AIAvatar Widget**
- Build an interactive robot face avatar using `TweenAnimationBuilder` and custom containers:
  - Outer glow rings that rotate/pulse based on state.
  - Face card with digital glowing LED eyes:
    - **Thinking (Yellow/Cyan):** Rotating progress circle or spinning line eyes.
    - **Speaking (Green):** Moving mouth soundwave lines or smiling eye arcs.
    - **Listening (Blue):** Pulsing circle eyes with mic icon.
    - **Idle (Cyan):** Breathing scale animation (floating up and down).

**Step 2: Integrate AIAvatar Widget**
- Replace the static icons in `onboarding_screen.dart` and `ai_chat_screen.dart` with the new interactive `AIAvatar` widget.

---

### Task 3: Dual Language (Hindi & English) System & Fallback Support

**Files:**
- Modify: `lib/ai/engine/ai_coordinator.dart`

**Step 1: Update System Prompt for Hindi**
In `lib/ai/engine/ai_coordinator.dart`:
- Read `appLanguageProvider`. If the language is `'hi'`, modify the system instructions for both onboarding and banking agents to generate replies strictly in Devanagari Hindi.

**Step 2: Add Hindi Translations to Simulation Mode Fallback**
- Update onboarding chat simulated responses to translate prompts into Devanagari Hindi if the selected language is `'hi'`.
  - Name step: "कृपया अपना पूरा नाम दर्ज करें।"
  - Mobile step: "अपना 10 अंकों का मोबाइल नंबर दर्ज करें।"
  - PAN step: "कृपया 10 अंकों का पैन कार्ड नंबर डालें।"
  - Aadhaar step: "कृपया 12 अंकों का आधार नंबर डालें।"
  - Address step: "कृपया अपना स्थायी पता दर्ज करें।"
  - Video KYC step: "वीडियो केवाईसी शुरू करने के लिए नीचे दिए गए बटन पर टैप करें।"
  - UPI step: "कृपया अपनी पसंदीदा UPI आईडी (VPA) दर्ज करें।"
- Translate banking simulated responses as well.

---

### Task 4: Smart Onboarding Help Suggestions & UI Controls

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Modify: `lib/features/ai_chat/ai_chat_screen.dart`

**Step 1: Language and Hands-Free Switchers**
- Render language selection buttons (English / हिंदी) and Hands-Free toggle button at the top of the onboarding screen and chat screens.

**Step 2: Proactive Suggestions & Autofill Buttons**
- Under the dialogue block or input box, check the active step and render a context-aware help chip:
  - Name step: "Confused? Tap to view sample name."
  - PAN step: "Suggest mock PAN" / "What is PAN?"
  - Aadhaar step: "Suggest mock Aadhaar"
  - Video KYC step: "Confused? Tap to verify directly."
- Tapping a suggestion fills the input field or triggers the mock verification, ensuring the user is never stuck.
