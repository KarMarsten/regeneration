# Regeneration 🌸

**Tracker** — a Flutter iOS app built for women, with love.

---

## Features

- **First-Run Setup Wizard** — name, zip code, weight unit, and color theme; guided 6-step onboarding
- **Daily Check-In** — symptom severity sliders (hot flashes, nausea, sleeplessness, exhaustion, bloating), cycle toggle, appetite change, free-text notes
- **Weight Log** — track in lbs or kg with a line chart; switch units anytime
- **Events Timeline** — log medications started/stopped, stressful moments, cycle start/end dates, and more
- **Private Journal** — diary-style entries by date with selectable fonts; check-in notes flow in automatically
- **Auto Temperature** — fetches daily high/low for your zip code (via wttr.in) every time you save a check-in
- **Doctor Report** — generates a printable PDF with symptom trends, weight data, key events timeline, and auto-generated observations
- **6 Color Themes** — Dusty Blue (default), Purple Dark, Sage Green, Blush Pink, Sunshine Yellow, Peach Orange
- **Private by Design** — all data stays on your device; no accounts, no uploads
- **TARDIS App Icon** — because healing is its own kind of time travel

---

## Navigation

The app uses a 5-tab bottom navigation bar:

| Tab | Screen |
|-----|---------|
| Today | Daily symptom + weight + event check-in |
| Weight | Weight history chart and log |
| Events | Full events timeline |
| Journal | Private diary entries |
| Report | PDF report generation |

The **⚙ Settings** and **ℹ About** icons live in the top-right corner of the Today screen.

---

## Setup

### Prerequisites

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (3.x or later)
2. Install Xcode (for iOS)
3. Have an Apple Developer account (free works for personal use / TestFlight)

### Install dependencies

```bash
cd regeneration
flutter pub get
```

### Generate app icon

The app icon is a custom-drawn TARDIS. To generate all required iOS icon sizes:

1. Open `assets/tardis_icon.svg` in any SVG tool (Figma, Inkscape, etc.)
2. Export as a **1024×1024 PNG** → save to `assets/tardis_icon.png`
3. Run:

```bash
flutter pub run flutter_launcher_icons
```

### Run on iOS Simulator

```bash
flutter run -d iPhone  # or use `flutter devices` to list available simulators
```

### Build for device / TestFlight

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode, set your signing team, and archive.

---

## Project Structure

```
lib/
├── main.dart                    # App entry + 5-tab navigation shell
├── models/
│   ├── symptom_entry.dart       # Daily symptom data model
│   ├── weight_entry.dart        # Weight log model
│   ├── event_entry.dart         # Events model (meds, stress, cycle, temp high/low)
│   └── journal_entry.dart       # Journal entry model
├── providers/
│   └── settings_provider.dart   # Theme, units, name, zip, journal font (SharedPreferences)
├── services/
│   ├── database_service.dart    # SQLite CRUD + broadcast stream for cross-tab refresh
│   ├── weather_service.dart     # Daily high/low + current temp via wttr.in
│   └── report_service.dart      # PDF generation
├── theme/
│   └── app_theme.dart           # 6 color themes (Material 3)
├── widgets/
│   ├── tardis_painter.dart      # Custom TARDIS widget (CustomPainter)
│   ├── severity_slider.dart     # Symptom severity slider (0–5)
│   └── weight_chart_widget.dart # fl_chart line chart for weight
└── screens/
    ├── onboarding_screen.dart   # First-run setup wizard (6 pages)
    ├── today_screen.dart        # Daily symptom entry + AppBar ⚙ ℹ icons
    ├── weight_screen.dart       # Weight log + chart
    ├── events_screen.dart       # Events timeline
    ├── journal_screen.dart      # Diary-style journal with event & note merge
    ├── report_screen.dart       # PDF report generation
    ├── settings_screen.dart     # Theme, units, profile, journal font
    └── about_screen.dart        # App info, privacy policy, TARDIS lore
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `sqflite` | Local SQLite database |
| `shared_preferences` | Theme & settings persistence |
| `fl_chart` | Weight trend chart |
| `pdf` + `printing` | PDF report generation & print |
| `http` | Weather API (wttr.in, no key needed) |
| `provider` | State management |
| `intl` | Date formatting |

---

## Doctor Report

The PDF report includes:
- **Weight log** with start/end/change/min/max/avg stats
- **Symptom summary table** with average severity and trend bars (color-coded mild → extreme)
- **Key events timeline** — medications started/stopped with names, stress events, cycle dates, temperature readings
- **Auto-generated observations** — trend analysis, correlations (sleep + exhaustion), medication notes, appetite patterns

To generate: tap **Report** → select date range → **Generate & Print PDF**

---

## Privacy

All data is stored locally on the device using SQLite. Nothing is uploaded, synced, or shared with any server. The only network call is an optional weather fetch from `wttr.in` (anonymous, no account required).

---

## Sharing with Others

This is a standard Flutter project. To share it:
1. Zip the entire `regeneration/` folder
2. The recipient runs `flutter pub get` then `flutter run`

For a polished shared release, consider building to TestFlight or using [Codemagic](https://codemagic.io) for CI/CD distribution.
