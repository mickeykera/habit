# HabitTracker

An editorial-design habit tracking app for iOS and Android — free to sideload, zero paid developer account required. Built with SwiftUI + SwiftData (iOS), Kotlin + Jetpack Compose + Room (Android), and an optional Supabase backend for privacy-first friend competition.

## Features

- **Build & Quit habits** with daily/weekly schedules and streak tracking
- **Interactive calendar** with monthly success rate visualization
- **Friend leaderboard** — only anonymized completion stats are shared; habit names never leave your device
- **Weekly report matrix** — ruled-ledger table of habits × days
- **Local notifications** for daily reminders
- **Export/Import** data as JSON or CSV

## Sideloading (Free, No Developer Accounts)

GitHub Actions builds both platforms on every push to `main`:

### 🍏 iOS Sideloading (`.ipa`)
1. Go to **Actions** → latest workflow run → **Artifacts**
2. Download `HabitTracker-iOS-IPA` (`HabitTracker.ipa`)
3. Install using one of:
   - [**SideStore**](https://sidestore.io) — on-device, no computer needed
   - [**AltStore**](https://altstore.io) — requires a computer for initial setup
   - [**Sideloadly**](https://sideloadly.io) — cross-platform GUI tool

### 🤖 Android Sideloading (`.apk`)
1. Go to **Actions** → latest workflow run → **Artifacts**
2. Download `HabitTracker-Android-APK` (`HabitTracker.apk`)
3. Transfer or open on any Android device and tap **Install** (enable "Install unknown apps" if prompted).

---

## Quick Start

### iOS (Xcode)
```bash
# 1. Generate Xcode project
xcodegen generate

# 2. Open and run
open HabitTracker.xcodeproj
```

### Android (Android Studio / Gradle)
```bash
cd android
./gradlew assembleDebug
```

---

## Friends Sync (Optional)

The friends feature uses a free Supabase project for privacy-first competition. **Habit names are never uploaded** — only anonymized daily counts (completed, scheduled, rate, streak).

### Setup
1. Create a free project at [supabase.com](https://supabase.com)
2. Open the SQL Editor and run [`supabase/schema.sql`](supabase/schema.sql)
3. Enable **Anonymous Sign-ins**: Dashboard → Authentication → Providers → Anonymous
4. Copy your **Project URL** and **anon/public key** from Settings → API
5. Paste both into the app's **Settings** tab → Connect to Supabase

---

## Architecture

```
├── Sources/                # Native iOS App (SwiftUI + SwiftData)
│   ├── App/                # App entry point, TabView
│   ├── Theme/              # Design tokens (colors, typography)
│   ├── Models/             # SwiftData models (Habit, HabitLog, HabitStore)
│   ├── Services/           # SupabaseSyncService
│   └── Views/              # 5 tabs (Today, Calendar, Friends, Report, Settings)
├── android/                # Native Android App (Kotlin + Jetpack Compose)
│   ├── app/src/main/java/  # Compose screens, Room DB, sync service
│   └── build.gradle.kts    # Android Gradle configuration
├── supabase/
│   └── schema.sql          # Shared PostgreSQL schema & RLS policies
└── .github/workflows/
    └── build-ipa.yml       # Dual CI workflow: macOS (IPA) & Ubuntu (APK)
```

| Layer | iOS Technology | Android Technology |
|---|---|---|
| UI & State | SwiftUI + `@Observable` | Jetpack Compose + State |
| Persistence | SwiftData (local only) | Room Database (local only) |
| Cloud Sync | Supabase Swift | Supabase REST |
| Sideloading Artifact | `.ipa` (unsigned) | `.apk` (debug signed) |

## Design System

- **Editorial ruled-grid aesthetic** with hairline dividers and inset cards
- **Cobalt Blue** `#1E40AF` accent — reserved for primary actions and completion states
- **Warm Paper** `#FBFAF4` background with `#F2F1EC` card surfaces
- High contrast WCAG AA compliance across both platforms

## License

MIT
