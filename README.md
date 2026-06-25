# YONO SBI 2.0 (AI-Agentic)

YONO SBI 2.0 is a next-generation mobile banking application built to simplify digital banking for millions of users through a conversational, voice-first AI copilot. Driven by **Google Gemini 2.5 Flash** for natural language understanding and a local **PatternEngine** for proactive financial insights, the app eliminates cluttered navigation and nested menus.

---

## 🚀 Key Innovation Pillars

### 1. Unified Architecture & Seamless Navigation
*   **Split Entry Gateway:** Separate simulation paths for new customers (Rohan, needing onboarding & identity checks) and existing customers (Sourabh, accessing a personalized assistant) via [customer_selection_screen.dart](file:///data/data/com.termux/files/home/sbiv2/lib/features/customer_selection/customer_selection_screen.dart).
*   **Dual-Language Voice UI:** Seamlessly switch between English and Devanagari Hindi at any point. The custom [AIAvatar](file:///data/data/com.termux/files/home/sbiv2/lib/features/agent/widgets/ai_avatar.dart) changes states dynamically (Idle, Listening, Thinking, Speaking) to match text-to-speech.
*   **Actionable Notification Center:** A central drawer built into [bottom_nav_shell.dart](file:///data/data/com.termux/files/home/sbiv2/lib/features/navigation/bottom_nav_shell.dart) gathers pending agent alerts into simple cards, enabling users to execute recommendations (e.g., "Resume SIP", "Open FD") with a single click.

### 2. Multi-Agent Orchestration & Core Intelligence
The AI subsystem uses a decoupled router, [AgentOrchestrator](file:///data/data/com.termux/files/home/sbiv2/lib/ai/agent/agent_orchestrator.dart), which analyzes user intent and delegates tasks to three specialized local agents:
*   **Advisor Agent:** Evaluates financial wellness, detects spending anomalies, and highlights wealth opportunities.
*   **Transaction Agent:** Translates conversational prompts into schema-conforming tool calls like payments, goal creation, and Fixed Deposit operations.
*   **Compliance Agent:** Intercepts and audits all operations against security regulations (e.g., blocking transfers > ₹10,000 if KYC is incomplete, or pausing UPI if velocity limits are exceeded).

---

## 🔒 Security & Privacy Pillars

YONO SBI 2.0 is built with security as a core architectural constraint:

1.  **Local Rule-Based Compliance Gatekeeping:** All database modifications and financial tool calls are routed through the [ComplianceAgent](file:///data/data/com.termux/files/home/sbiv2/lib/ai/agent/compliance_agent.dart). If a transaction breaches safety rules (such as velocity limits or KYC thresholds), it is short-circuited and blocked locally before it is sent to the network or AI services, protecting user funds from LLM hallucinations or prompt injection.
2.  **Privacy-Preserving Pattern Engine:** The [PatternEngine](file:///data/data/com.termux/files/home/sbiv2/lib/ai/engine/pattern_engine.dart) operates entirely on-device. Sensitive financial records are processed locally to generate metadata summaries, ensuring raw transactional databases are not exposed.
3.  **Offline-First Data Storage:** All user profiles, transaction records, streaks, goals, and chat histories are stored locally using **Hive boxes** in [state_providers.dart](file:///data/data/com.termux/files/home/sbiv2/lib/data/repositories/state_providers.dart). This architecture supports local encryption ciphers (AES-256) to prevent unauthorized file-system access, ensuring account balances and personal identification details are kept secure.
4.  **Secure API Key Management:** Gemini API keys are retrieved securely from user configurations or environmental parameters (`GEMINI_API_KEY`) and are never hardcoded or cached on external loggers.

---

## 🧠 AI Models Configuration

*   **REST Model:** **Gemini 2.5 Flash** (`gemini-2.5-flash`) is the standard model configured for structured content generation and tool calling.
*   **Live Model:** **Gemini 3.1 Flash Live** (`models/gemini-3.1-flash-live-preview`) handles low-latency bidirectional WebSocket audio streaming.
*   **Simulation Mode Fallback:** If internet access is unavailable or no API key is set, the app switches to an offline rule-driven simulator automatically. This guarantees sub-second response times and complete demo safety.

---

## 🛠️ Developer Debug & Validation Diagnostic Lab

The app includes two custom testing screens to validate functionality and connectivity under live pitch conditions:

### 1. Developer Simulation Page
The debug console at [debug_simulation_page.dart](file:///data/data/com.termux/files/home/sbiv2/lib/features/settings/debug_simulation_page.dart) provides one-click event triggers:
*   **Salary Credit:** Triggers TCS salary credit, increases balance, and fires a proactive salary allocation nudge.
*   **Missed SIP:** Deletes current month's SIP logs, spawning an agent alert to resume the SIP with a single click.
*   **Low Balance:** Instantly reduces account balance to trigger buffer warnings.
*   **Rapid Transactions:** Executes 3 fast UPI debits in succession, triggering the Compliance Agent's fraud prevention screen.

### 2. AI Testing Lab Screen
The diagnostic lab at [ai_testing_lab_screen.dart](file:///data/data/com.termux/files/home/sbiv2/lib/features/settings/ai_testing_lab_screen.dart) allows real-time network validation:
*   **DNS Test:** Checks resolution of `generativelanguage.googleapis.com`.
*   **Port 443 Reachability:** Assesses TCP handshake success with the Google API endpoint.
*   **API Key Validation:** Verifies the authorized key via HTTP GET request.
*   **WebSocket Handshake:** Simulates the bi-directional setup payload to guarantee WebSocket stability.

---

## 🏃 How to Build and Run

### Prerequisites
*   Flutter SDK (3.22+ recommended)
*   Dart SDK (3.4+ recommended)

### Setup & Run Steps
1.  **Clone the project** and navigate to the project root.
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run with an environmental API key (Optional):**
    ```bash
    flutter run --dart-define=GEMINI_API_KEY="your-gemini-api-key"
    ```
    *Or enter your API key directly on the Settings screen in the app.*
4.  **Run in Simulator / Device:** Launch the app, switch customer profiles on the home screen, and use the Developer Debug page to present proactive agent interactions.
