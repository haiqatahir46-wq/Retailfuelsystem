# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

PARCO Fuel System, a Retail Fuel Management System (RFMS) Flutter app for fuel station owners. It is a final-year project (FYP). The app is **front-end only**: no backend exists yet, and all data comes from hardcoded demo data. The planned roadmap is in `RFMS_Trello_Milestones.txt`. It calls for a Supabase backend, Manager/Operator roles, three fuel grades (Petrol, Diesel, Hi-Octane), shifts, deliveries and a stock ledger.

Dependencies are minimal: `fl_chart` (dashboard/sales charts) and `http` (Google Places only). There is no state-management package.

## Commands

```bash
flutter pub get
flutter run                      # pick a device; Windows desktop/web work for quick UI checks
flutter analyze                  # baseline is ~41 info-level deprecations (withOpacity, etc.), no errors/warnings
flutter test                     # all tests
flutter test test/widget_test.dart            # single file
flutter test --plain-name "<test name>"       # single test by name
```

`test/widget_test.dart` is still the default Flutter counter template, and it fails against this app. `MyApp` now starts at `SplashFlow`, which also schedules a 3s `Timer`. A rewritten test must pump past that timer, or tear the widget down, before it ends.

## Repository layout gotchas

- `Retailfuelsystem/` is a **separate, nested Flutter project** with its own `.git`. It is committed here as a gitlink and excluded in `analysis_options.yaml`. It is not part of this app, so don't edit it or import from it.
- The root `*_preview.html` files and `navbar-preview/` are static HTML design mockups, one per screen. They use the same palette as `AppColors`, and you can treat them as the visual spec when you change a screen.
- `assets/images/station.webp` exists, but `pubspec.yaml` has **no `assets:` section** yet. You must add one before using `Image.asset` (see the comment on `_StationPlaceholder` in `lib/screens/dashboard_screen.dart`).

## Architecture

### Screens vs. flows

The UI is split into two layers. Keep them that way:

- **`lib/screens/`** holds presentational widgets. They take data plus callbacks (`onBack`, `onSave`, `onNavTap`, ...) and do not call `Navigator` themselves. The one exception is `location_search_screen.dart`.
- **`lib/navigation/*_flow.dart`** holds wrappers that build a screen, wire its callbacks to `Navigator` calls, and own any mutable list the screen shows. For example, `StaffFlow` owns the staff list and `StationsAddedFlow`/`SelectStationFlow` own station lists. Flows are `StatefulWidget`s whenever a pushed child route adds to a list: a pushed route captures its widget tree once, so the owning state must live in the flow that stays on screen.

Route chain: `main.dart` → `SplashFlow` (auto-advances after 3s) → `LoginFlow` → `MainTabsFlow`. The signup path is `LoginFlow` → `SignupFlow` → `StationsAddedFlow` → `MainTabsFlow`. Logout uses `pushAndRemoveUntil(LoginFlow)` everywhere.

### Main tabs

`MainTabsFlow` holds `_tabIndex` and rebuilds a **different full `Scaffold`** per tab: Dashboard, Nozzles, Tanks, Stock and Logs. The Tanks tab is the private `_TanksTab` in the same file. Each tab screen includes its own `AppBottomNavBar` and reports taps through `onNavTap`. Drill-downs (Threshold, Create Reorder, Help Center, Settings, Select Station, Profile) are pushed on top of the active tab.

`ProfileFlow` is pushed but has its own bottom nav. A tab tap there calls `Navigator.pop(tabIndex)`, and `MainTabsFlow._openProfile` switches to the returned tab. Don't push a second `MainTabsFlow`.

There is no app-wide "current station" state. Switching station in `SelectStationFlow` only updates that flow's local state. The signed-in station id is the hardcoded placeholder `'station-1'` (set in `LoginFlow` and `StationsAddedFlow`).

### Data and domain rules

- `lib/models/` holds plain immutable classes. `lib/data/demo_*.dart` holds the const demo data and the lookup functions (`salesFor`, `tanksForStation`) that a real backend will replace.
- **Per-station scoping:** all sales and stock data is keyed by `stationId`. `salesFor()` returns an empty list for unknown ids and never falls back to another station's data. Keep that guarantee when adding data sources.
- **Derived values are never stored.** Each of these is computed from its source:
  - Revenue is litres × the price constants in `lib/models/sales.dart`.
  - Tank health (healthy/low/critical) comes from `currentVolume` vs `threshold` in `TankStock`.
  - Tank `currentVolume` is capacity minus today's sales for that station (`tanksForStation`). Dashboard, Stock and the Tanks tab all read from this same function so their numbers agree.
- `TODO:` comments mark every place where a backend, auth or a missing screen is needed (password reset, edit profile, edit staff, edit station). Check them before assuming something is unfinished by accident.

### Shared UI

- Use `AppColors` (`lib/theme/app_colors.dart`, the PARCO/TotalEnergies palette) instead of literal colors.
- Reuse the shared widgets in `lib/widgets/`: `AppTopBar`, `AppDrawer`, `AppBottomNavBar` (tab definitions in `kAppNavItems`), `AppTextField` and `WaveClipper` (the curved header on Splash, Login, Dashboard and others).

### Google Places

`lib/services/google_places_service.dart` reads the API key from the source constant `kGooglePlacesApiKey`. While that constant still holds its placeholder value, `autocomplete()` throws a `StateError`. Station location search won't work until a real key is set, and the setup steps are in that file's header comment.
