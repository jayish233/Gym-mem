# Presence — Member App

Flutter member app for the Presence gym attendance and retention platform. This
build is a front-end-only vertical slice: every member screen is wired up over
an in-memory mock store with a fake OTP sign-in. There is no backend, database,
or local persistence; restarting the app resets to seed data.

Full product requirements live in `PRD.md`, the visual prototype is in
`Presence — Gym Retention Platform.html`, and the implementation spec is in
`CLAUDE.md`.

## Screens

| Route | Screen |
|-------|--------|
| `/signin`, `/signin/code` | Email sign-in and 6-digit OTP verification (any valid email + any 6 digits) |
| `/home` | Greeting, streak panel, current week, scan CTA, today's workout, monthly summary |
| `/history` | Monthly attendance calendar, legend, visits / attendance % / streak figures |
| `/scan` | Camera QR check-in (permission, viewfinder, success, expired, duplicate) with debug preview links |
| `/plan` | Weekly workout planner: Mon–Sun day chips, editable day title, exercise list, completion toggle |
| `/profile` | Membership dates and status, editable name and phone, legal links, sign out |
| `/privacy`, `/terms` | Static legal pages with placeholder sections |

## Stack

- Flutter (Dart `^3.13.5`, Material 3 with a custom token theme)
- `go_router` for routing, shell tab bar, and auth redirect
- `google_fonts` (Geist and Geist Mono)
- `mobile_scanner` for camera QR scanning on Android and iOS
- `lucide_icons_flutter` for icons
- `intl` for date/time formatting
- Plain `ChangeNotifier` state (`SessionController`, `MemberStore`, `MockClock`)

## Project layout

```text
lib/
├── main.dart
├── app/            # MaterialApp.router and GoRouter configuration
├── theme/          # Design tokens (Ink, Graphite, Teal, Mist, …) and ThemeData
├── data/           # Models, MockClock, seed data, attendance math, stores
├── features/       # signin, home, history, scan, plan, profile, legal
└── widgets/        # Buttons, text field, figure, hairline, day cell, tab bar, scaffold
test/               # Unit and widget tests for math, store, sign-in, tabs, and routes
```

## Running

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

In debug builds, the Scan screen exposes **Preview: success** and **Preview:
expired code** links so the check-in flow can be exercised without a camera. On
a device, any QR payload Containing `expired` triggers the expired state; any
other payload records today's check-in once.
