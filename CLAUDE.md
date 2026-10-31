# CLAUDE.md — Presence Member App

This file is the build guide for the member app and its backend. Screen layout
and visual rules are in sections 4 and 5. The backend is in section 8 and
matches `PRD.md`. If this file and `PRD.md` disagree on the API, data model, or
auth, `PRD.md` wins. The HTML prototype is reference only.

The Flutter screens already run on an in-memory store. Do not rebuild them.
The next build is the Node.js API. Do not wire `lib/` to the network until a
later task says so.

---

## 1. What we are building

A **member-only** product. The Flutter app is the client. The server is a
Node.js and TypeScript API with PostgreSQL. A member signs in with email and
password, accepts the Terms and Privacy Policy, checks in by scanning a gym
code, and reviews attendance, streaks, a weekly workout plan, and profile.

There is no OTP, no emailed code, and no `/signin/code` step in the target
flow. The code screen still in the Flutter tree is the old mock and must not
be copied into the server.

### In scope

| # | Surface | What |
|---|---------|------|
| 1 | `POST /auth/login`, logout, accept-terms | Email + password session. Terms acceptance once. |
| 2 | `/home` | Greeting, streak panel, this week, scan CTA, today's workout, month summary |
| 3 | `/history` | Month calendar, legend, visits / % / streak figures |
| 4 | `/scan` + `POST /attendance/check-in` | Camera scan; success, expired, duplicate, invalid |
| 5 | `/plan` | 7 day chips, editable day, exercises, mark completed |
| 6 | `/profile` + `GET/PATCH /me` | Membership figures, name and phone, legal links, sign out |
| 7 | `/privacy`, `/terms` | Legal pages in the app. The server stores acceptance timestamps only |
| 8 | `server/` | Schema, migrations, seed script, and the routes in section 8 |

### Out of scope

- Gym owner panel, staff, registration UI, "Create your gym", invitations.
- OTP, Resend, email delivery, Cloudflare Workers, D1, cron, inactivity alerts.
- Payments, analytics, notifications, QR display for the gym.
- PWA "Add to home screen" banner.
- Flutter persistence (`shared_preferences`, `hive`, `sqflite`, `isar`, files).
- Platform targets other than Android and iOS. Leave `linux/` alone.
- Connecting the Flutter client to this API until that task is asked for.

---

## 2. Hard rules

These are non-negotiable. Check them before every commit.

1. **The database lives in `server/`, not in Flutter.** Do not add
   `shared_preferences`, `hive`, `sqflite`, `isar`, `drift`, `firebase_*`, or
   `supabase_*` to `pubspec.yaml`. Do not add `http` until the client-connection
   task. Postgres access stays in the Node server.
2. **No owner code paths.** No `role` enum, no `isOwner`, no owner routes, no
   registration endpoint.
3. **Design system only.** Use only the colours, type sizes, spacing, radii and
   component patterns in section 4. If something is missing, add it to section 4
   first, then use it.
4. **No red, no green.** Errors and success are communicated with ink/teal,
   icons and words. Meaning must never be carried by colour alone.
5. **No cards, shadows, gradients or emoji.** Group content with hairlines and
   space. At most one dark "panel" per screen.
6. **Every tappable control is at least 44 px tall** (member primary actions 56).
7. **Figures are computed, never typed.** Streaks, visits, attendance % and
   "today" come from attendance rows and the gym timezone. No literal `'12'`
   streak strings in widgets or API responses.
8. **A member sees only their own rows.** The API takes the user id from the
   session, never from the request body or query.
9. **Workout completion never creates attendance.** Separate state, separate
   copy that says so.
10. Keep copy short. One line beats a paragraph. Unknown facts are written as
    `[PLACEHOLDER]` in the UI, not invented.

---

## 3. Stack and conventions

### Toolchain

- Flutter stable (project created with the current stable channel; see
  `.metadata`). Dart SDK `^3.13.5` as pinned in `pubspec.yaml`.
- Lints: `package:flutter_lints/flutter.yaml` (already in
  `analysis_options.yaml`). `flutter analyze` must report zero issues.

### Packages to add (and nothing else without updating this list)

| Package | Why |
|---------|-----|
| `go_router` | Declarative routing, shell route for the tab bar, redirect to `/signin` when signed out |
| `google_fonts` | Geist and Geist Mono (both are on Google Fonts) |
| `mobile_scanner` | Camera QR scanning on Android and iOS |
| `lucide_icons_flutter` | Lucide-style icons (1.75 stroke look). If unavailable, use `Icons.*_outlined` and note it here |
| `intl` | Date and time formatting ("Friday 30 October", "6:42 PM", "12 Jan 2026") |

Remove `cupertino_icons` only if it ends up unused.

### Architecture

- **State:** plain `ChangeNotifier` classes exposed with
  `ListenableBuilder` / `AnimatedBuilder` or passed down the tree. No `provider`,
  `riverpod`, `bloc`, code generation or `build_runner`.
- **Three notifiers, created once in `main()` and passed into the router:**
  - `SessionController` — today this is the in-memory stand-in. The target
    methods are `login(email, password)`, `acceptTerms()`, and `signOut()`
    with a bearer token. Do not keep `sendCode` / `verify` once the client
    calls the API. Do not add those OTP methods to the server.
  - `MemberStore` — the member, gym, membership, attendance set, workout plan,
    profile edits, `checkIn(DateTime at)`, streak and summary getters.
  - `MockClock` — `DateTime get now`; defaults to `DateTime.now()` but is
    injectable so tests and screenshots can freeze time.
- **Widgets:** `StatelessWidget` by default. `StatefulWidget` only for local UI
  state (text controllers, scan view state, selected day).
- **Routing:** `go_router` with a `ShellRoute` that wraps `/home`, `/history`,
  `/scan`, `/plan`, `/profile` in the member scaffold with the tab bar.
  `/signin*`, `/privacy`, `/terms` are outside the shell. A `redirect` sends
  signed-out users to `/signin` and signed-in users away from `/signin`.
- **Theme:** Material 3 `ThemeData` built in `lib/theme/` from the tokens in
  section 4. Never use `Theme.of(context).colorScheme.error` or `primary`
  implicitly; reference the named tokens.
- **Responsiveness:** phone first. Member content column is `max-width 480`
  centred, `padding 16`, `gap 28`. On widths ≥ 720 the Sign in screen becomes two
  panes (ink pane left, form right); every other screen stays a centred column.
- **Accessibility:** every icon-only button has a `tooltip` or `Semantics` label.
  Calendar cells expose "October 14, attended" style labels. Respect
  `MediaQuery.disableAnimations` for the scan line animation.

### Code style

- Files: `snake_case.dart`. One public widget per file unless tiny helpers.
- Feature folders own their widgets. Shared primitives live in `lib/widgets/`.
- Formatting via `dart format .`. Trailing commas on multi-line argument lists.
- No `print`. No `// TODO` without an owner and a reason.
- Prefer `const` constructors everywhere they are possible.

### Proposed `lib/` layout

```text
lib/
├── main.dart                     # creates MockClock, MemberStore, SessionController, runs PresenceApp
├── app/
│   ├── presence_app.dart         # MaterialApp.router + theme
│   └── router.dart               # GoRouter, ShellRoute, redirect
├── theme/
│   ├── tokens.dart               # PresenceColors, PresenceSpace, PresenceRadius, PresenceType
│   └── presence_theme.dart       # ThemeData from tokens
├── data/
│   ├── models/
│   │   ├── member.dart           # Member, Gym, Membership
│   │   ├── attendance_day.dart   # DayState enum + helpers
│   │   └── workout.dart          # WorkoutDay, Exercise
│   ├── mock/
│   │   ├── mock_clock.dart
│   │   └── seed.dart             # buildSeedMember(), buildSeedAttendance(clock), buildSeedPlan()
│   ├── member_store.dart         # ChangeNotifier
│   ├── session_controller.dart   # ChangeNotifier
│   └── attendance_math.dart      # pure functions: openDays, currentStreak, longestStreak, monthSummary
├── features/
│   ├── signin/
│   │   ├── signin_screen.dart
│   │   ├── code_screen.dart
│   │   └── widgets/ (brand_pane.dart, code_boxes.dart)
│   ├── home/home_screen.dart (+ widgets/streak_panel.dart, week_row.dart)
│   ├── history/history_screen.dart (+ widgets/month_grid.dart, figure_grid.dart)
│   ├── scan/scan_screen.dart (+ widgets/viewfinder.dart, result_view.dart)
│   ├── plan/plan_screen.dart (+ widgets/day_chips.dart, exercise_row.dart)
│   ├── profile/profile_screen.dart
│   └── legal/legal_screen.dart   # takes a title and sections; used for /privacy and /terms
└── widgets/
    ├── member_scaffold.dart      # column constraints + tab bar
    ├── member_tab_bar.dart
    ├── presence_button.dart      # primary / key / secondary / text variants and sizes
    ├── presence_text_field.dart  # label above, 52 high, 16px text
    ├── figure.dart               # label + big number with hairline or teal top border
    ├── hairline.dart
    └── status_dot.dart           # dot + word
```

---

## 4. Design system (extracted from the prototype's "Design system" board)

### 4.1 Principles

1. Group with hairlines and space, not cards. One panel at most per screen, and
   only when it earns attention.
2. Ink is the default. Teal marks the thing that is present, active or the
   single most important action.
3. Say only what matters. One short line beats a paragraph.
4. Numbers are large and quiet. Dates, times and counts use Geist Mono.
5. Every control is at least 44 px tall and works by keyboard. Meaning is never
   carried by colour alone.
6. Design for the phone width first, then let it widen.

### 4.2 Colour

| Token | Hex | Use |
|-------|-----|-----|
| `ink` | `#222831` | Text, dark surfaces, primary button fill |
| `graphite` | `#393E46` | Long text, primary button hover, avatars on dark |
| `teal` | `#00ADB5` | Present, active, key action, charts. **Fills only, never text on light** |
| `mist` | `#EEEEEE` | App background. Text on ink |
| `deepTeal` | `#00747A` | Teal when it must be text or a link on a light background; focus ring |
| `muted` | `#5A616B` | Secondary text and captions |
| `paper` | `#FFFFFF` | Inputs, the tab bar |
| `hairline` | ink @ 12 % → `rgba(34,40,49,0.12)` | Dividers and input borders |
| `inkSoft` | ink @ 14 % | "Missed" calendar fill |
| `tealWash` | teal @ 16 % | Active tab background, selected row |
| `mistOnInk75` | mist @ 75 % | Secondary text inside the dark panel |

Approved pairs (contrast): Ink on Mist 12.8, Ink on Paper 14.8, Muted on Paper
6.3, Muted on Mist 5.4, Deep teal on Paper 5.6, Ink on Teal 5.4, Teal on Ink
5.4, Mist on Ink 12.8. **Never** Paper on Teal (2.7, fails).

Status markers are always a dot plus a word:

| Dot | Meaning |
|-----|---------|
| teal fill | Present · Active |
| ink fill | Pending · Needs action |
| deep teal fill | Interested |
| paper with 2 px deep-teal ring | Expiring · Issue |
| muted fill | Suspended |
| paper with 2 px ink ring | Expired · Closed |

### 4.3 Type

Geist for text, Geist Mono for dates, times, counts and codes. Weights 400, 500,
600 only.

| Style | Size / line-height / weight / tracking | Example |
|-------|----------------------------------------|---------|
| Numeral | 72 / 0.9 / 500 / −0.04em | streak "12" |
| Display | 48 (32 on phones) / 1.05 / 600 / −0.03em | "Privacy Policy" |
| Figure | 38 / 1.0 / 500 / −0.035em | "88%", "22 visits" |
| Page title | 24 / 1.1 / 600 / −0.02em | "Attendance" |
| Result title | 28 / 1.1 / 600 / −0.025em | "You are checked in" |
| Section | 17 / 1.3 / 600 / −0.01em | "Today · Legs" |
| Body | 15–16 / 1.5 / 400 | explanatory sentences |
| Label | 13 / 1.4 / 500 | field labels |
| Caption | 12–13 / 1.5 / 400, muted | "Longest 21" |
| Mono | Geist Mono 13–14 / 500 | "4 × 8", "12 Jan 2026" |
| Tab label | 11 / 1 / 600 active, 400 inactive | "Home" |

Inputs use 16 px text so phones do not zoom.

### 4.4 Space, radius, layout

Spacing scale (px): `4` icon-to-label · `8` between chips · `12` control-to-control
· `16` between fields · `20` panel inner gaps · `24` panel padding · `28` member
column gap · `32` sheet padding · `40` between page sections · `48` columns.

Radius (px): `9` segment · `10` nav item · `12` input, default button · `14`
member button, tab item, day chip · `16` panel · `20` tab bar · `24` hero panel,
scan viewfinder · circle for day cells, avatars, result icons.

Layout: member column `max 480`, horizontal padding `16`, top padding `20`,
bottom padding `16`, vertical gap `28`. Touch target `≥ 44`.

### 4.5 Buttons

| Variant | Look | Use |
|---------|------|-----|
| Primary | ink fill, mist label, weight 500/600 | default for any action |
| Key action | teal fill, ink label, weight 600 | the single most important action on a screen (Scan, Verify). Never two per screen |
| Secondary | transparent, 1 px ink outline (or ink 28 % for lower weight), ink label | alternatives, Sign out, Not now |
| Text link | underlined, underline offset 4, ink or deep teal; hover deep teal | navigation and small actions |
| Destructive | none. Use Secondary then a confirm step that names the consequence | |

Sizes: `44` toolbars and icon buttons · `52` form buttons · `56` member main
action. Horizontal padding 18 when not full width.

States: hover graphite (primary) or +14 % white inset (key) · focus 2 px deep teal
ring, offset 2 · pressed scale 0.98 over 100 ms · disabled 40 % opacity.

### 4.6 Forms

Label above the field (13 / 500), 8 px gap. Input 52 high, padding 0 16, radius
12, 1 px hairline border, paper fill, 16 px ink text. Read-only: ink 5 % fill,
muted text, helper caption below. Error: 2 px ink border, an icon and one
sentence that says how to fix it. No red.

Code boxes: 6 cells, 56 high, radius 12, hairline border, Geist Mono 22 centred,
`inputmode numeric`, auto-advance, backspace moves back, paste fills all six.

Chips (day selector): min height 64, radius 14, selected ink fill mist text,
unselected transparent with ink 20 % border.

### 4.7 Data display

- **Figure:** caption label (13 muted) above a Figure number, with a 1 px hairline
  on top. The single figure that needs attention gets a 2 px teal top border and
  a deep teal number.
- **List row:** min height 52–56, hairline between rows, title 15, supporting
  value in Mono muted on the right. Hover/press: ink 4 % background in 150 ms.
- **Calendar day cell:** square, circle, Geist Mono 14 / 500.

| State | Style |
|-------|-------|
| Present | teal fill, ink text |
| Missed | ink 14 % fill, ink text |
| Gym closed | 1 px dashed ink 50 % border, muted text |
| Today | 2 px ink border (2 px mist border inside the dark panel), no fill |
| Upcoming | muted text only |
| Not joined / blank | invisible cell |

Inside the dark streak panel the same states use mist instead of ink for borders
and text.

### 4.8 Navigation (member tab bar)

Paper background, radius 20, padding 8, five equal columns, gap 4. Items min
height 56, radius 14, icon 20 px above an 11 px label, gap 4. Active: teal 16 %
fill, ink text, weight 600. Inactive: muted. The centre **Scan** item is always
an ink fill with mist text and weight 600 regardless of route. Icons: Home
(house), History (calendar), Scan (scan-line), Plan (dumbbell), Profile (user),
1.75 stroke, rounded caps, Lucide style. Always paired with a label.

The tab bar is pinned to the bottom of the member column with
`margin-top: auto`; it scrolls with short content and stays visible on tall
content by placing it outside the scroll view.

### 4.9 Motion

| Name | Spec | Use |
|------|------|-----|
| Press | 100 ms ease-out | scale 0.98 on buttons |
| Hover | 150 ms ease-out | background and colour on buttons, rows, tabs |
| Scan sweep | 2.2 s ease-in-out, alternate, infinite | teal line across the viewfinder only |
| Reduced motion | off | when `disableAnimations` is set, no transitions or loops |

Never animate layout, never bounce, never auto-play anything except the scan
sweep.

### 4.10 Do / Don't

Do: group with a hairline and space · ink default button, teal for one key action
· status as dot plus word · label above field · consistent sample data on every
screen · `[PLACEHOLDER]` for unknown facts · add tokens here before using them.

Don't: stack cards · add shadows, gradients or emoji · teal text on light or
white text on teal · two teal buttons on one screen · red or green · invented
colours, radii or sizes · copy the user does not need.

---

## 5. Screen specifications

All copy below is final unless marked `[PLACEHOLDER]`. Layout values reference
section 4.

### 5.1 Sign in — `/signin`

**Phone (< 720 wide):** single scrolling column. Top block is an ink pane
(`padding 32`, min height 240): brand row (logo + "Presence" 18 / 600), the
decorative dot grid, then the headline. Below it on mist: the form.

**Wide (≥ 720):** two panes side by side, each `flex 1`. Left ink pane
`padding 48`, content spaced top / middle / bottom. Right pane `padding 32 48`,
form centred, `max-width 380`.

**Brand pane contents**

- Logo: 28 px — outer circle r 12 stroked teal 2 px, inner circle r 5 teal fill.
  Wordmark "Presence" 18 / 600, tracking −0.01em, mist.
- Decorative grid: 14 columns × 6 rows of circles, gap 8, max width 520. Each
  cell is teal at a random alpha 0.35–1.0 with probability `1 − column × 0.058`,
  otherwise mist at 9 %. Seed the PRNG (any fixed seed) so it is stable.
- Headline: "See who is drifting before they leave." 40 / 1.1 / 500, tracking
  −0.025em, max width 420 (28 px on phones).

**Form (email and password)**

The shipped app still shows "Send code" and `/signin/code`. That is the old
mock. The target screen, used when the client calls the API, is:

- Title "Sign in" (32 / 600 on wide, Page title 24 on phones).
- Sub "Check in and keep your streak." Body 15 muted.
- Field "Email", `type email`, `autocomplete email`, placeholder
  `you@example.com`.
- Field "Password", `type password`, `autocomplete current-password`.
- Primary button 52 "Sign in".
- Validation: trim email; require `@` and a `.` after it. Password at least 8
  characters. Error state per 4.6. Wrong credentials use the server message
  "Email or password is incorrect." Do not say which field failed.
- On submit: `POST /auth/login`. If `termsAccepted` is false, show the Terms
  and Privacy Policy and require acceptance (`POST /auth/accept-terms`) before
  Home. If true, go to `/home`.
- Footer caption centred: "By continuing you agree to the Terms and Privacy
  Policy." with "Terms" → `/terms` and "Privacy Policy" → `/privacy` as
  underlined ink links.
- Do not build a 6-digit code step. Remove `/signin/code` when the client is
  connected. No email is sent.

### 5.2 Home — `/home`

Member column, gap 28, inside the shell with the tab bar (Home active).

1. **Header** row, space-between. Left: `Good {morning|afternoon|evening},
   {firstName}` as Page title 24, then gym name 14 muted. Greeting by local
   hour: < 12 morning, < 17 afternoon, else evening. Right: 44 px circle avatar,
   ink fill, mist initials 14 / 600.
2. **Streak panel** — the one dark panel: ink fill, radius 24, padding 24,
   gap 24.
   - Top row: flame icon 36 px teal (1.75 stroke) + Numeral `currentStreak`;
     right-aligned column "day streak" (15 / 500) over "Longest {longest}"
     (13, mist 75 %). Use "day streak" for all counts (no pluralisation games).
   - "This week" row: 7 columns Monday–Sunday of the current week, gap 6. Each
     column: weekday letter (12, mist 75 %) above a 40 px circle with the day
     number in Mono 13 / 500. States per 4.7 using the dark-panel variants.
     Semantics label "Monday 26, attended" / ", today" / ", upcoming" /
     ", gym closed" / ", missed".
   - Key action 56, radius 14: scan icon 20 + "Scan to check in" → `/scan`.
     If already checked in today, label becomes "Checked in today" and the button
     is a Secondary (mist outline) that still opens `/scan`.
3. **Today's workout** section. Heading row: Section "Today · {workoutName}" and
   text link "Edit plan" (13 deep teal) → `/plan`. Then exercise rows (52 min
   height, hairline top): name 15 left, sets Mono 13 muted right. If the day is
   Rest or has no exercises: single muted row "Rest day. Nothing planned."
4. **Month summary** section, hairline top, padding-top 20, wrap row
   space-between. Left column: caption month name, Figure "{visits} visits",
   caption "{pct}% of {openDaysSoFar} open days so far". Right: text link 14 /
   500 ink "View calendar" → `/history`.

### 5.3 Attendance — `/history`

Tab bar: History active.

1. **Header** row: Page title "Attendance"; right cluster: prev month icon
   button 44 (Secondary outline ink 20 %), month label "{Month} {yyyy}" 15 / 500
   with `min-width 116` centred, next month icon button 44. Prev is disabled
   before the membership start month; next is disabled on the current month.
   Disabled buttons use hairline border and ink 35 % icon.
2. **Calendar**: weekday row M T W T F S S (12 muted centred), then a 7-column
   grid, gap 6, with leading blank cells so day 1 lands on its weekday (weeks
   start Monday). Cells per 4.7. Legend row below (12 muted, wrap, gap 8/20):
   Present (teal dot), Missed (ink 14 % dot), Gym closed (dashed ring).
3. **Figures** 2 × 2 grid, gap 20 24:
   - Visits — hairline top.
   - Attendance — hairline top, "{pct}%".
   - Current streak — 2 px teal top border, deep teal number.
   - Longest streak — hairline top.
   Visits and Attendance are for the displayed month; streaks are overall.
4. **Explanation** Body 13 muted: "Attendance is visits divided by the
   {openDays} days your gym has been open {so far this month | that month}.
   Closed days do not count."

### 5.4 Scan attendance — `/scan`

Tab bar: Scan item is always ink; no tab is "active" here (keep the Scan item's
permanent ink fill). Header: 44 px back icon button (`margin-left −8`) →
`/home`, Page title "Scan attendance". Main area is `flex 1`, content centred
vertically, gap 28. Four exclusive states:

**A. Permission** (initial, and whenever permission is not granted)

- 88 px ink circle with teal camera icon 40.
- "Allow camera access" (22 / 600). Body 15 muted: "The camera is used only
  while you scan. Nothing is recorded or stored."
- Primary 56 "Allow camera" → requests permission via `mobile_scanner`.
- If permanently denied: title "Camera is off for Presence", body "Turn it on in
  Settings to scan the gym code.", Primary "Open settings"
  (`openAppSettings` equivalent) and Secondary "Back to home". Never record
  attendance without a scan.

**B. Scanning**

- Square viewfinder, radius 24, ink background, `MobileScanner` preview inside,
  four corner brackets (teal, 2 px) inset 14 %, and a 2 px teal scan line at
  90 % opacity sweeping top-to-bottom per 4.9.
- Body 15 muted centred: "Point at the code on the gym screen."
- Mock validation on first decoded value, then stop the camera:
  - already checked in today → state D (duplicate);
  - payload contains `expired` (case-insensitive) → state C (expired) — this is
    the test hook;
  - any other non-empty payload → `store.checkIn(clock.now)` → state E.
- In debug builds only (`kDebugMode`), show two small text links under the
  caption: "Preview: success" and "Preview: expired code" that jump to the
  result states without the camera.

**C. Expired**

- 104 px circle, 3 px ink border, ink alert icon 44.
- Result title "That code has expired". Body "Scan the code that is on the gym
  screen right now."
- Primary 56 "Scan again" → state B.

**D. Duplicate**

- Same circle as C with a check icon.
- Result title "Already checked in". Body "Your visit for {today, 'EEEE d MMMM'}
  is already recorded."
- Primary 56 "Done" → `/home`.

**E. Success** (`role=status`)

- 104 px teal circle, ink check icon 48.
- Result title "You are checked in". Body 15 muted "{EEEE d MMMM} · {h:mm a}".
- Row: flame icon 20 + "{currentStreak}-day streak" (15 / 500).
- Primary 56 "Done" → `/home`.

Camera lifecycle: start on entering B, stop on result, dispose on leaving the
route. Handle `AppLifecycleState` pause/resume.

### 5.5 Workout planner — `/plan`

Tab bar: Plan active.

1. **Header** column: Page title "Workout planner", caption 14 muted "Your week.
   Only you can see it."
2. **Day chips**: 7 chips Monday–Sunday, gap 6, per 4.6. Each shows the weekday
   letter (12) and a 6 px dot: teal if that day is marked completed; ink (mist
   when selected) if it is today and not completed; transparent otherwise.
   Semantics: "{Weekday}, {workoutName}[, today]". Today is selected on entry.
3. **Day editor**, gap 20:
   - Caption "{Weekday}[ · Today]".
   - Workout name as a borderless `TextField`: 32 / 600 tracking −0.025em,
     hairline bottom border only, padding-bottom 10. Editing updates the store
     immediately. Hidden label "Workout name".
   - Exercise list: rows min 56, hairline top, name 15, right cluster of sets
     Mono 13 muted + 44 px remove icon button (X) with tooltip
     "Remove {name}". Empty state paragraph (padding 20 0, hairline top, 14
     muted): "No exercises. Add one below, or keep it as a rest day."
   - Add row (`Form`, hairline top, padding-top 16, gap 8): text field
     "Exercise" (flex), Mono text field placeholder "3 × 10" width 92, 52 px ink
     icon button "+" (tooltip "Add exercise"). Submit on the + or keyboard done.
     Blank name is ignored; blank sets default to "3 × 10". Clear both after add.
   - Completion toggle 52, radius 12, 15 / 600: unselected "Mark as completed"
     with 1 px ink outline; selected "Completed" with teal fill, ink text and
     teal border. Caption below: "This is for your own tracking. It does not
     check you in at the gym."
4. Reordering days is not required in this slice (the week is fixed Mon–Sun).
   Renaming a day to "Rest" is how a rest day is expressed.

### 5.6 Profile — `/profile`

Tab bar: Profile active.

1. **Header** row, gap 16: 64 px ink avatar with initials 20 / 600; column with
   Page title full name and 14 muted gym name.
2. **Membership figures** — `auto-fit, min 130` grid (3 across on 390 wide),
   gap 20 24:
   - Membership — 2 px teal top, value "Active" 20 / 600 deep teal.
   - Started — hairline top, Mono 15 "12 Jan 2026".
   - Ends — hairline top, Mono 15 "14 Mar 2027".
   Status is derived: Active if `now` is within start..end, else Expired (paper
   dot with ink ring). Do not model suspension.
3. **Form**, gap 18: Name (text), Phone (`tel`), Email (read-only per 4.6 with
   helper "Email is set by your gym. Ask them to change it."). Primary 56 "Save
   changes"; after a successful save the label reads "Saved" until a field
   changes again. Saving writes to `MemberStore` (memory only). Name may not be
   blank; phone is free text.
4. **Legal rows**: "Privacy Policy" → `/privacy`, "Terms of Service" → `/terms`.
   Rows min 56, hairline top (and bottom on the last), 15 text, chevron-right
   icon 20 muted at the right.
5. **Sign out**: Secondary 52, 1 px ink outline, "Sign out" →
   `POST /auth/logout`, drop the bearer token, then `/signin`. Logout does not
   delete attendance or the workout plan. The in-memory `MemberStore.reset()`
   on sign out applies only while the app is still on mock data.

### 5.7 Legal — `/privacy`, `/terms`

Outside the shell (no tab bar). Column max 1040, padding 32 (16 on phones).
44 px back icon button + Display title ("Privacy Policy" / "Terms of Service").
Caption "Last updated [PLACEHOLDER]". Then 4–6 sections, each: Section heading
and one or two Body paragraphs of `[PLACEHOLDER]` text that state what the
section will cover (e.g. "What we collect — [PLACEHOLDER: name, phone, email,
attendance dates]"). Do not write legal prose.

---

## 6. Mock data contract

All seed data lives in `lib/data/mock/seed.dart` and is built from `MockClock`
so the app looks right on **any** date. Never hardcode a calendar date in a
widget.

### Member, gym, membership

```dart
Member(
  id: 'm_001',
  name: 'Priya Sharma',          // initials derived: "PS"
  email: 'priya.sharma@example.com',
  phone: '+91 98101 20034',
)
Gym(name: 'Iron Works Fitness', closedWeekdays: {DateTime.sunday})
Membership(start: DateTime(2026, 1, 12), end: DateTime(2027, 3, 14))
```

If `clock.now` is after the membership end, the UI shows Expired; do not shift
the dates.

### Attendance seed

Attendance is a `Set<DateTime>` of date-only values (midnight, local). Generate
it by walking **open days** (membership start → yesterday, skipping closed
weekdays) backwards from yesterday and assigning presence in this pattern so the
headline figures match the prototype:

1. The 12 most recent open days: present (current streak 12).
2. Next 1 open day: missed.
3. Next 21 open days: present (longest streak 21).
4. Next 1 open day: missed.
5. Then repeat "present, present, present, present, missed" all the way back to
   `membership.start`, so every month the History screen can reach has
   realistic data (the prev button stops at the membership start month).

Today is **not** checked in at launch, so the Home key action reads "Scan to
check in" and a successful scan visibly increments the streak to 13.

### Workout plan seed (Monday → Sunday)

| Day | Name | Completed | Exercises |
|-----|------|-----------|-----------|
| Mon | Chest | true | Bench press 4 × 8 · Incline dumbbell press 3 × 10 · Cable fly 3 × 12 |
| Tue | Back | true | Pull-up 4 × 6 · Barbell row 4 × 8 |
| Wed | Shoulders | true | Overhead press 4 × 8 · Lateral raise 3 × 15 |
| Thu | Arms | true | Barbell curl 3 × 10 · Triceps pushdown 3 × 12 |
| Fri | Legs | false | Back squat 4 × 8 · Leg press 3 × 12 · Romanian deadlift 3 × 10 |
| Sat | Cardio | false | Incline walk 30 min |
| Sun | Rest | false | — |

`completed` seeds as `true` only for days earlier in the current week than
today; compute it at seed time rather than copying the column above literally.
Use the multiplication sign `×` (U+00D7) in sets strings.

The same records are inserted by `server/seed.ts` (section 8.4). Today is not
checked in, so a successful scan increments the streak from 12 to 13.

---

## 7. Business rules

The Flutter helpers in `lib/data/attendance_math.dart` are the reference. The
API must compute the same results. Gym-local "today" uses the gym timezone
(`Asia/Kolkata` for the seed gym).

1. **Open day:** a date is open if its weekday is not in `gym.closedWeekdays`
   and it is on/after `membership.start` and on/before `membership.end`.
2. **One check-in per local day.** `checkIn` is a no-op if today is already in
   the set; the Scan screen shows the Duplicate state.
3. **Future dates are never absent.** Days after today render as Upcoming.
   Today renders as Today (not Missed) until the day is over.
4. **Closed days neither count nor break.** Streaks are counted over consecutive
   open days; a closed day in between does not break a streak. Days before the
   membership start are Not joined (blank).
5. **Current streak:** count consecutive open days with attendance walking back
   from today if today is attended, otherwise from the most recent open day
   before today. A missed open day ends the count.
6. **Longest streak:** the maximum run of consecutive attended open days across
   the whole attendance set.
7. **Monthly summary:** `visits` = attended days in the month;
   `openDays` = open days in the month up to and including today (for the
   current month) or the whole month (for past months);
   `pct = openDays == 0 ? 0 : round(visits / openDays × 100)`.
8. **Workout completion is separate state.** It never calls `checkIn` and the
   copy says so.
9. **Only the signed-in member's data exists.** No lists of members, no gym-wide
   figures.
10. **A failed or cancelled scan never shows success.** The Success screen
    appears only after `POST /attendance/check-in` returns `checked_in`. A
    payload that contains `expired` (any case), a past `expires_at`, an unknown
    code, or a second check-in today does not insert a row.

---

## 8. Backend

Build this under `server/`. Do not put it in `lib/`. Stack: Node.js,
TypeScript, Express, PostgreSQL via `pg`, SQL migrations, bcrypt or argon2.
Config is `DATABASE_URL`, `PORT`, and `SEED_PASSWORD`.

```text
server/
├── src/
│   ├── index.ts
│   ├── auth/
│   ├── attendance/
│   ├── workouts/
│   └── db/
├── migrations/
├── seed.ts
└── package.json
```

JSON errors: `{ "error": "machine_code", "message": "One sentence." }`.
Protected routes read `Authorization: Bearer <token>`. The user id comes from
the session only.

### 8.1 Auth

- Password minimum 8 characters. Store a hash only. Never log the password,
  the session token, or a check-in code.
- `POST /auth/login` with `{ "email", "password" }`. Trim and lower-case the
  email. Unknown email and wrong password both return `401` and
  `Email or password is incorrect.` Rate-limit per IP and per email.
- Success `200`: `{ "token", "expiresAt", "termsAccepted" }`. The token is at
  least 32 random bytes. Store only its hash. Lifetime is 30 days.
- `POST /auth/accept-terms` sets `terms_accepted_at` and `privacy_accepted_at`
  once. Requires a session. Returns `204`. The legal copy stays in the Flutter
  pages; the server does not serve it.
- Until both timestamps are set, only login, logout, accept-terms, and
  `GET /me` succeed. Other member routes return `403` `terms_required`.
- `POST /auth/logout` revokes the presented session and returns `204`,
  including when the token is already revoked. Expired or revoked tokens get
  `401` on protected routes.
- No OTP route, no email send, no register route.

### 8.2 Tables

Timestamps are `timestamptz` (UTC). Calendar values are `date`. Weekdays are
`1` Monday through `7` Sunday.

- `gyms` — name, IANA `timezone`, `closed_weekdays smallint[]`.
- `users` — `gym_id`, name, lower-case unique email, phone, `password_hash`,
  `terms_accepted_at`, `privacy_accepted_at`.
- `memberships` — `user_id` unique, `gym_id`, `start_date`, `end_date`. Status
  is derived: Active when gym-local today is inside the range, else Expired.
  No suspension column.
- `sessions` — `user_id`, unique `token_hash`, `expires_at`, `revoked_at`.
- `attendance` — `user_id`, `gym_id`, `attendance_date`, `checked_in_at`.
  Unique on `(user_id, gym_id, attendance_date)`.
- `check_in_codes` — `gym_id`, `code_hash`, `expires_at`. Plaintext is shown
  once by the script that inserts the row.
- `workout_days` — `user_id`, `weekday`, `name`, `completed`. Unique on
  `(user_id, weekday)`.
- `workout_exercises` — `workout_day_id`, `position`, `name`, `sets`.

### 8.3 Routes

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/auth/login` | Email and password |
| POST | `/auth/accept-terms` | Record terms and privacy acceptance |
| POST | `/auth/logout` | Revoke this session |
| GET | `/me` | Profile, gym, membership, `termsAccepted`, initials |
| PATCH | `/me` | `name` and `phone`. Blank name is `400`. Email is ignored |
| GET | `/attendance/summary` | Streaks, `checkedInToday`, Monday-first `week`, current `month` |
| GET | `/attendance/calendar?year&month` | Day states plus month figures. Streaks are overall |
| POST | `/attendance/check-in` | Body `{ "code" }` |
| GET | `/workouts` | Seven days with exercises |
| PUT | `/workouts/:weekday` | Replace one day, `weekday` `1`–`7` |

`GET /me` returns `id`, `name`, `email`, `phone`, `initials`, `gym`,
`membership` (`startDate`, `endDate`, `status`), `termsAccepted`.

Summary includes `currentStreak`, `longestStreak`, `checkedInToday`, `week`
(each day: `date`, `state`, `weekdayLetter`), and `month` (`name`, `visits`,
`openDays`, `pct`).

Calendar days use `present`, `today`, `upcoming`, `closed`, `missed`,
`not_joined`, plus a label such as `October 14, attended`. `404` when the
month is before the membership start month or after the current month.

Check-in `200` body: `{ "result", "attendanceDate", "checkedInAt", "currentStreak" }`.
`result` is `checked_in`, `expired`, `duplicate`, or `invalid`. Only
`checked_in` inserts a row, and only after the insert commits. A code whose
plaintext contains `expired`, or whose `expires_at` has passed, is `expired`.
A code that is not this gym's current code is `invalid`.

`PUT /workouts/:weekday` body: `{ "name", "completed", "exercises": [{ "name", "sets" }] }`.
Drop blank exercise names. Blank `sets` becomes `3 × 10`. The list replaces
that day's exercises. This route must not write `attendance`.

### 8.4 Seed

`npm run seed` is idempotent on the development database.

- Gym Iron Works Fitness, `Asia/Kolkata`, closed Sunday (`7`).
- User Priya Sharma, `priya.sharma@example.com`, `+91 98101 20034`. Password
  from `SEED_PASSWORD` (at least 8 characters). Print the email. Do not print
  the password.
- Membership `2026-01-12` through `2027-03-14`.
- Attendance pattern in section 6, through yesterday in the gym timezone.
  Today has no row.
- Workout plan in section 6. `completed` is true only for weekdays earlier
  than today.
- One development check-in code, valid for 24 hours, plaintext printed once.
  Say in the output that it is a development code. A real gym code lifetime
  is 60 seconds.
- Leave both acceptance timestamps null.

### 8.5 Security

Generic login errors, hashed passwords, hashed session tokens, hashed
check-in codes, login rate limit, parameterised SQL, every member query
filtered by the session user, HTTPS when deployed, no OTP secrets in logs.

---

## 9. Agent workflow

### Commands

```bash
flutter pub get
flutter analyze          # must be clean
dart format .            # run before finishing
flutter test             # existing widget and math tests must keep passing
cd server && npm test    # API tests for the backend
```

Platform setup the camera needs (do this when adding `mobile_scanner`):

- iOS `ios/Runner/Info.plist`: `NSCameraUsageDescription` = "Presence uses the
  camera only while you scan the gym's attendance code."
- Android: `mobile_scanner` declares the permission; set `minSdkVersion` to the
  value its README requires if the default is lower.

### Build order

The Flutter app through the legal pages is already built. Do not redo it.
Build the server in this order:

1. `server/` project, migrations for the tables in section 8.2.
2. Password hashing, sessions, login, logout, accept-terms, and the terms gate.
3. `GET /me` and `PATCH /me`.
4. Attendance summary, calendar, and check-in, using section 7.
5. Workout read and replace. Completion must not write attendance.
6. `npm run seed` from section 8.4.
7. API tests listed below.

Leave `lib/` on the in-memory store until a later task connects it.

### Tests to write (minimum)

Backend:

- Login rejects a wrong password and an unknown email with the same `401`.
- No route accepts a 6-digit code.
- Attendance and workout routes return `403` `terms_required` before
  accept-terms, then succeed.
- Logout revokes the token; the next call with it returns `401`.
- A valid seed code inserts one row for today and moves the current streak
  from 12 to 13. A second check-in returns `duplicate`.
- A code containing `expired`, and a code past `expires_at`, insert nothing.
- Marking a workout day completed does not change attendance.
- `PATCH /me` cannot change email. A member cannot read another member's rows.

Existing Flutter tests stay: `attendance_math_test.dart`,
`member_store_test.dart`, `signin_flow_test.dart`, `tab_bar_test.dart`.
Update `signin_flow_test.dart` only when the client drops the OTP screen.

### When to stop and ask

Stop and ask the user instead of guessing when:

- A package in section 3 cannot be resolved for the pinned Dart SDK and the
  alternative changes the UI noticeably.
- Camera scanning cannot be exercised in the available environment (say so; do
  not fake a success path outside the debug preview links).
- The task would add an owner, staff, registration, or OTP flow.
- The task would point Flutter at the API. That connection is a separate ask.

Everything else (exact pixel tweaks, icon choice within Lucide, copy
punctuation) is your call; follow section 4.

---

## 10. Definition of done

Flutter (already in the tree; do not regress it):

- [ ] `flutter analyze` and `flutter test` pass; `dart format .` makes no
      changes.
- [ ] Screens follow sections 4 and 5. No red/green, no shadows, no cards,
      controls at least 44 px, one teal button per screen.
- [ ] `lib/` has no owner, staff, registration, or persistence code.

Backend:

- [ ] `server/` implements section 8 against PostgreSQL. No Cloudflare, D1,
      Resend, or OTP.
- [ ] Seeded member logs in with email and password. Wrong password fails
      with the generic message.
- [ ] Terms acceptance is required before attendance and workout routes.
- [ ] Logout revokes the session.
- [ ] Check-in, calendar, streaks, profile save, and the workout plan match
      section 7 and section 12 of `PRD.md`.
- [ ] Sign out does not delete attendance. Workout completion does not create
      it.
