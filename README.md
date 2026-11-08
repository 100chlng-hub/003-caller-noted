# Caller-Noted

[![100Challenges Project #003](https://img.shields.io/badge/100Challenges-%23003-blue?style=for-the-badge&logo=target)](https://100chlng-hub.github.io)

> **Part of the 100Challenges Initiative** — Building and shipping 100 real-world software projects.  
> 🌐 **Hub**: [100chlng-hub.github.io](https://100chlng-hub.github.io)

Smart post-call calendar scheduling assistant designed for professionals, field technicians, contractors, and artisans. It transforms agreed telephone appointments into calendar events in seconds through a 5-second voice memo processed by Google Gemini AI.

---

## ⚡ Problem & Operational Flow

Professionals often close phone calls agreeing on inspection dates, interventions, or client meetings while on the move, leading to forgotten dates or manual calendar entry friction.

```
[Phone Call Ends] 
       │
       ▼
[Smart Heads-up Notification] ──▶ "🎙️ Create Event with Voice"
       │
       ▼
[5-Second Voice Memo] ──▶ "Site inspection tomorrow at 3:30 PM with Mario for boiler repair at 10 Roma St."
       │
       ▼
[Gemini AI Extraction] ──▶ Structured JSON: Title, Start/End Time, Location, Contact, Intervention Notes
       │
       ▼
[1-Tap Confirmation] ──▶ Synced to Native Device Calendar (Google Calendar, iCloud, Outlook)
                     ──▶ (Optional) Saves unknown caller to Phone Address Book
```

---

## 🚀 Key Features

- **Post-Call Telephony Hook (Android):** Listens to phone call state transitions via `CallStateReceiver` and triggers an actionable notification only when a call finishes (with configurable duration filter, e.g. ignoring calls < 10 seconds).
- **2-Phase Voice Memo Flow (GDPR & OS Security Compliant):** Solves modern mobile OS call recording restrictions by allowing the professional to record a rapid 5-second post-call voice memo.
- **Gemini Flash Intelligence:** Employs Google's Gemini Flash model to resolve relative Italian dates (e.g., *"giovedì prossimo alle quattro"*), extract addresses, categorize intervention types, and output strict schema-validated JSON.
- **Native Device Calendar Sync:** Reads and writes to the user's existing device calendars (`device_calendar`) without requiring separate third-party OAuth flows.
- **Smart Contact Matching & Creation:** Resolves caller ID from existing phone contacts (`flutter_contacts`) and offers one-tap contact creation for new clients.
- **Offline / Built-in Fallback:** Includes a local fallback rule parser if the Gemini API key is not configured or network is unavailable.
- **Built-in Flow Simulator:** Includes a one-click simulation button on the Home screen to test the complete post-call notification and voice capture lifecycle without needing live cellular calls.

---

## 🛠️ Architecture & Tech Stack

- **Framework:** Flutter (Dart)
- **AI Processing:** Google Gemini Flash (`google_generative_ai`)
- **Speech-to-Text:** Native system speech engine (`speech_to_text`)
- **Calendar & Contacts:** `device_calendar`, `flutter_contacts`
- **Native Android Listener:** Kotlin `CallStateReceiver` listening to `android.intent.action.PHONE_STATE`
- **Notifications:** `flutter_local_notifications`
- **Local Storage:** `shared_preferences`

```
003-caller-noted/
├── lib/
│   ├── main.dart                          # App initialization & routing
│   ├── models/
│   │   ├── calendar_event_draft.dart      # Structured event representation
│   │   ├── call_session.dart              # Call log metadata model
│   │   └── user_settings.dart             # Configuration & preference state
│   ├── services/
│   │   ├── calendar_service.dart          # Native device calendar provider
│   │   ├── contacts_service.dart          # Address book lookup & contact creation
│   │   ├── speech_service.dart            # Native voice capture & STT
│   │   ├── gemini_service.dart            # AI semantic date & entity parser
│   │   ├── notification_service.dart      # Actionable post-call notifications
│   │   └── settings_service.dart          # Local persistent settings
│   └── screens/
│       ├── onboarding_screen.dart         # Permissions setup & calendar selection
│       ├── home_screen.dart               # Dashboard, recent calls, flow simulator
│       ├── quick_event_modal.dart         # Voice capture sheet & event review
│       └── settings_screen.dart           # Calendar picker, API key & call filters
├── android/                               # Native Android manifest & CallStateReceiver.kt
└── ios/                                   # Native iOS Info.plist with permission declarations
```

---

## 📦 Getting Started

### Prerequisites
- **Flutter SDK** (>= 3.0.0):
  ```bash
  brew install --cask flutter
  ```
- **Android Studio / Xcode** for device or simulator testing.

### Installation
```bash
git clone https://github.com/100chlng-hub/003-caller-noted.git
cd 003-caller-noted
flutter pub get
```

### Running the App
```bash
flutter run
```

### Quick Testing
Open the app and tap **"Simula Fine Telefonata (Test Flow)"** on the Home screen to trigger the post-call notification and voice scheduling dialog immediately.

---

## 📄 License
MIT License. See [LICENSE](LICENSE) for details.
