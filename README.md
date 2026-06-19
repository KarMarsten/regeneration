# Regeneration 🌸

**Menopause & Weight Tracker** — a Flutter iOS app built for women, with love.

## Features

- **Daily Symptom Tracker** — severity 1–5 sliders for hot flashes, nausea, sleeplessness, exhaustion, and bloating; binary cycle toggle; appetite change (increase/decrease/normal)
- **Weight Log** — track in lbs or kg with a line chart; switch units anytime
- **Events Timeline** — log medications started/stopped (with name), stressful moments (with description), cycle start/end dates, temperature readings
- **Auto Temperature** — saves your local temperature (via zip code) every time you log symptoms
- **Doctor Report** — generates a printable PDF with symptom trends, weight data, key events timeline, and auto-generated observations
- **6 Color Themes** — Dusty Blue (default), Purple Dark, Sage Green, Blush Pink, Sunshine Yellow, Peach Orange
- **Tardis App Icon** — because healing is its own kind of time travel

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
2. Export it as a **1024×1024 PNG** and save to `assets/tardis_icon.png`
3. Run:

```bash
flutter pub run flutter_launcher_icons
```

This auto-generates all required iOS icon sizes.

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
├── main.dart                    # App entry + navigation shell
├── models/
│   ├── symptom_entry.dart       # Daily symptom data model
│   ├── weight_entry.dart        # Weight log model
│   └── event_entry.dart         # Events model (meds, stress, cycle, temp)
├── providers/
│   └── settings_provider.dart   # Theme, units, name, zip (SharedPreferences)
├── services/
│   ├── database_service.dart    # SQLite CRUD (sqflite)
│   ├── weather_service.dart     # Temperature fetch via wttr.in
│   └── report_service.dart      # PDF generation
├── theme/
│   └── app_theme.dart           # 6 color themes (Material 3)
├── widgets/
│   ├── tardis_painter.dart      # Custom TARDIS widget (CustomPainter)
│   ├── severity_slider.dart     # Symptom severity slider (0–5)
│   └── weight_chart_widget.dart # fl_chart line chart for weight
└── screens/
    ├── today_screen.dart        # Daily symptom entry
    ├── weight_screen.dart       # Weight log + chart
    ├── events_screen.dart       # Events timeline
    ├── report_screen.dart       # PDF report generation
    └── settings_screen.dart     # Theme, units, profile
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
- **Key events timeline** — medications started/stopped with names, stress events, cycle dates, temperature readings with zip codes
- **Auto-generated observations** — trend analysis, correlations (sleep + exhaustion), medication notes, appetite patterns

To generate: tap **Report** → select date range → **Generate & Print PDF**

---

## Privacy

All data is stored locally on the device using SQLite. Nothing is uploaded, synced, or shared with any server. The only network call is an optional temperature fetch from `wttr.in` (anonymous, no account required).

---

## Sharing with Others

This is a standard Flutter project. To share it:
1. Zip the entire `regeneration/` folder
2. The recipient runs `flutter pub get` then `flutter run`

For a polished shared release, consider building to TestFlight or using a service like [Codemagic](https://codemagic.io) for CI/CD distribution.
