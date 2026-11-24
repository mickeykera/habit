# HabitTracker

An editorial-design iOS habit tracking app — free to sideload, no paid Apple Developer account required. Built with SwiftUI, SwiftData, and an optional Supabase backend for privacy-first friend competition.

## Features

- **Build & Quit habits** with daily/weekly schedules and streak tracking
- **Interactive calendar** with monthly success rate visualization
- **Friend leaderboard** — only anonymized completion stats are shared; habit names never leave your device
- **Weekly report matrix** — ruled-ledger table of habits × days
- **Local notifications** for daily reminders
- **Export/Import** data as JSON or CSV

## Quick Start

### Prerequisites

- **Xcode 16+** (Swift 6, iOS 18 SDK)
- **XcodeGen** — `brew install xcodegen`
- **Host Grotesk** font (optional but recommended)

### Setup

```bash
# 1. Clone
git clone https://github.com/your-username/HabitTracker.git
cd HabitTracker

# 2. Add fonts (optional)
# Download Host Grotesk from Google Fonts:
# https://fonts.google.com/specimen/Host+Grotesk
# Place these files in Resources/Fonts/:
#   HostGrotesk-Regular.ttf
#   HostGrotesk-Medium.ttf
#   HostGrotesk-SemiBold.ttf
#   HostGrotesk-Bold.ttf

# 3. Generate Xcode project
xcodegen generate

# 4. Open and run
open HabitTracker.xcodeproj
```

Resolve Swift packages when prompted, then build and run on a simulator or device.

> **Note:** The app uses a system font fallback if Host Grotesk `.ttf` files are not present — it will build and run either way.

## Sideloading (Free, No Developer Account)

GitHub Actions automatically builds an unsigned IPA on every push to `main`.

1. Go to **Actions** → latest workflow run → **Artifacts**
2. Download `HabitTracker.ipa`
3. Install using one of:
   - [**SideStore**](https://sidestore.io) — on-device, no computer needed
   - [**AltStore**](https://altstore.io) — requires a computer for initial setup
   - [**Sideloadly**](https://sideloadly.io) — cross-platform GUI tool

## Friends Sync (Optional)

The friends feature uses a free Supabase project for privacy-first competition. **Habit names are never uploaded** — only anonymized daily counts (completed, scheduled, rate, streak).

### Setup

1. Create a free project at [supabase.com](https://supabase.com)
2. Open the SQL Editor and run [`supabase/schema.sql`](supabase/schema.sql)
3. Enable **Anonymous Sign-ins**: Dashboard → Authentication → Providers → Anonymous
4. Copy your **Project URL** and **anon/public key** from Settings → API
5. Paste both into the app's **Settings** tab → Connect to Supabase

## Architecture

```
Sources/
├── App/              # App entry point, TabView
├── Theme/            # Design tokens (colors, typography, components)
├── Models/           # SwiftData models (Habit, HabitLog, HabitStore)
├── Services/         # SupabaseSyncService
└── Views/
    ├── Today/        # Habit list, week strip, add/edit sheet
    ├── Calendar/     # Monthly grid, success rate
    ├── Friends/      # Leaderboard, friend codes
    ├── Report/       # Weekly matrix table
    ├── Settings/     # Preferences, export, Supabase config
    └── Components/   # Shared UI (CompletionCircle)
```

| Layer | Technology |
|-------|-----------|
| UI & State | SwiftUI + `@Observable` |
| Persistence | SwiftData (local only) |
| Cloud Sync | Supabase (optional, free tier) |
| Notifications | `UNUserNotificationCenter` (local) |
| Project Gen | XcodeGen |
| CI/CD | GitHub Actions → unsigned IPA |

## Design System

- **Editorial ruled-grid aesthetic** with hairline dividers and inset cards
- **Host Grotesk** typeface (Medium, Regular, SemiBold, Bold)
- **Cobalt Blue** `#1E40AF` accent — reserved for primary actions and completion states
- **Warm Paper** `#FBFAF4` background with `#F2F1EC` card surfaces
- WCAG AA contrast compliance across all text states

## Privacy

- Habit titles, notes, and types are **strictly local** (SwiftData on-device)
- Supabase receives **only**: `user_id`, `date`, `completed_count`, `scheduled_count`, `completion_rate`, `active_streak`
- PostgreSQL Row Level Security ensures users can only see their own data and connected friends' aggregates
- Friend connections use a 6-character shareable code — no email or phone required

## License

MIT
