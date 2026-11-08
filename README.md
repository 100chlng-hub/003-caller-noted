# 📞 Caller-Noted (Call2Cal)

> **Assistente intelligente post-chiamata per professionisti, artigiani e tecnici.**  
> Trasforma automaticamente una telefonata concordata in un appuntamento a calendario con una dettatura vocale di 5 secondi elaborata da AI (Google Gemini).

---

## 🚀 Flusso Operativo

```
[Fine Telefonata] 
       │
       ▼
[Notifica Intelligente] ──▶ "🎙️ Crea con Voce"
       │
       ▼
[Dettatura 5 secondi] ──▶ "Sopralluogo domani alle 15:30 con Mario per caldaia in via Roma 10"
       │
       ▼
[Gemini AI Parsing] ──▶ Estrazione automatica: Titolo, Data/Ora, Indirizzo, Contatto, Note
       │
       ▼
[1-Tap Conferma] ──▶ Salvato direttamente nel Calendario Nativo (Google/iCloud/Outlook)
                   ──▶ (Opzionale) Nuovo contatto salvato in Rubrica
```

---

## 🛠️ Tecnologie & Architettura

- **Framework:** Flutter 3.x (Dart)
- **AI Engine:** Google Gemini Flash (`google_generative_ai`) con response schema JSON strutturato e prompt in lingua italiana.
- **Calendario:** Integrazione con i calendari nativi del sistema (`device_calendar`) senza dover effettuare nuovi login cloud.
- **Rubrica:** Lettura contatti e salvataggio automatico tramite `flutter_contacts`.
- **Riconoscimento Vocale:** Speech-to-Text nativo del dispositivo (`speech_to_text`).
- **Background Listener (Android):** `BroadcastReceiver` su `android.intent.action.PHONE_STATE` (`CallStateReceiver.kt`) con filtro su durata chiamata (>= 10s).
- **Notifiche:** Notifiche banner Heads-up ad alta priorità (`flutter_local_notifications`).

---

## 📂 Struttura del Progetto

```
003-caller-noted/
├── lib/
│   ├── main.dart                          # Entrypoint & routing
│   ├── models/
│   │   ├── calendar_event_draft.dart      # Modello evento estratto da AI
│   │   ├── call_session.dart              # Modello sessione chiamata
│   │   └── user_settings.dart             # Impostazioni e preferenze utente
│   ├── services/
│   │   ├── calendar_service.dart          # Gestione eventi calendario nativo
│   │   ├── contacts_service.dart          # Ricerca e creazione contatti
│   │   ├── speech_service.dart            # Motore dettatura vocale
│   │   ├── gemini_service.dart            # Parsing semantico con Gemini API
│   │   ├── notification_service.dart      # Notifiche post-chiamata
│   │   └── settings_service.dart          # Persistenza preferenze (SharedPreferences)
│   └── screens/
│       ├── onboarding_screen.dart         # Wizard permessi & selezione calendario iniziale
│       ├── home_screen.dart               # Dashboard, storico chiamate e simulatore
│       ├── quick_event_modal.dart         # Modale vocale 5s + form rapido di conferma
│       └── settings_screen.dart           # Configurazione calendario, API key e filtri
├── android/                               # Configurazione Android & CallStateReceiver nativo
└── ios/                                   # Configurazione iOS & Info.plist con permessi
```

---

## 📲 Come Eseguire l'Applicativo

### 1. Prerequisiti
- **Flutter SDK**: installabile su Mac tramite `brew install --cask flutter` oppure dal sito ufficiale Flutter.
- **Android Studio** (per test su emulatore/dispositivo Android) o **Xcode** (per iOS).

### 2. Installazione dipendenze
```bash
flutter pub get
```

### 3. Avvio
```bash
flutter run
```

### 4. Test Rapido (Senza necessità di telefonate reali)
Nella schermata Home dell'applicazione è presente il pulsante:
👉 **"Simula Fine Telefonata (Test Flow)"**  
Questo attiva immediatamente la notifica heads-up e apre il modale vocale, permettendo di testare l'intero flusso di dettatura, parsing Gemini e salvataggio a calendario.
