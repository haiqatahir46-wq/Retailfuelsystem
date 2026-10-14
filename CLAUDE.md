# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

PARCO Fuel System, a Retail Fuel Management System (RFMS) Flutter app for fuel station owners. It is a final-year project (FYP). The app is **front-end only**: no backend exists yet, and all data comes from hardcoded demo data. The planned roadmap is in `RFMS_Trello_Milestones.txt`. It calls for a Supabase backend, Manager/Operator roles, three fuel grades (Petrol, Diesel, Hi-Octane), shifts, deliveries and a stock ledger.

Dependencies are minimal: `fl_chart` (dashboard/sales charts) and `http` (Google Places only). There is no state-management package.

## Commands

```bash
flutter pub get
flutter run                      # pick a device; Windows desktop/web work for quick UI checks
flutter analyze                  # expected: "No issues found!"
flutter test                     # all tests
flutter test test/data_test.dart              # single file
flutter test --plain-name "<test name>"       # single test by name
flutter run --dart-define=PLACES_API_KEY=...  # enables station location search (see Google Places below)
```

Tests: `models_test.dart` (tank health/percent, formatters and their rounding/large-number edges, `PeriodSales`, `pricePerLitre`, `Station.fromSignup`/`fromSetup`, `Owner.fromSignup`), `data_test.dart` (the per-station lookups and `buildTanks`), `demo_data_test.dart` (invariants every demo station's data must keep: the periods nest, every grade is in `kFuelGrades`, pending orders fit their tank, logs and nozzles stay within today's sales), `app_session_test.dart` (the session store, including reorder limits, PO numbers, `newId` and `nextPoNumber`), `navigation_test.dart` (login and signup through to the tabs, tab state, back button, drawer (including an item activated mid-close), SnackBars cleared on logout/station switch, Profile's tab bar, double-tap guards, Threshold/Reorder), `places_service_test.dart` (the Places service against `MockClient`, including each error message and the timeout), `location_search_test.dart` (the search screen with a fake service: stale replies, double taps, error text, and Select Station's edit-location path), `validators_test.dart` (the form validators), `forms_test.dart` (the validation of Login, Signup, Threshold, Create Reorder, Add Station, Staff, Account Details and Logs), `tabs_test.dart` (the Dashboard low-stock alert and 7-day trend, and the Nozzles figures), `charts_test.dart` (axis labels and ranges, labels kept whole at 135% text), `layout_test.dart` (no overflow on the main tabs at 360/320dp wide and 130% text, nor on Threshold, Create Reorder and Help Center at 320dp), `semantics_test.dart` (screen-reader labels and selected states, 48dp tap targets) and `app_smoke_test.dart` (splash -> login). `MyApp` starts at `SplashFlow`, which schedules a 3s `Timer`, so a widget test that pumps `MyApp` must pump past it before it ends. To test a flow without signing in through the UI, wrap it in `AppSessionScope(session: AppSession()..signInDemo(email: ...), child: MaterialApp(...))`.

## Repository layout gotchas

- `Retailfuelsystem/` is a **separate, nested Flutter project** with its own `.git`. It is committed here as a gitlink and excluded in `analysis_options.yaml`. It is not part of this app, so don't edit it or import from it.
- The root `*_preview.html` files and `navbar-preview/` are static HTML design mockups, one per screen. They use the same palette as `AppColors`, and you can treat them as the visual spec when you change a screen.
- `assets/images/` is declared in `pubspec.yaml`. `assets/images/station.webp` is shown by the shared `StationPhoto` widget, which every photo banner uses by default.

## Architecture

### Screens vs. flows

The UI is split into two layers. Keep them that way:

- **`lib/screens/`** holds presentational widgets. They take data plus callbacks (`onBack`, `onSave`, `onNavTap`, ...) and do not call `Navigator` themselves. The one exception is `location_search_screen.dart` (it takes an optional `GooglePlacesService`, which `SelectStationFlow` passes through, so tests can use a fake).
- **`lib/navigation/*_flow.dart`** holds wrappers that build a screen, read what it shows from the session (`AppSessionScope.of(context)`) and wire its callbacks to session methods and `Navigator` calls. A pushed route's builder that reads the session rebuilds when it changes, so a list edited on a pushed form (staff, stations) or a threshold set on Threshold shows up everywhere at once. Flows check `isTopRoute(context)` (`route_guard.dart`) before pushing, so a double tap opens one screen.

Route chain: `main.dart` → `SplashFlow` (auto-advances after 3s) → `LoginFlow` → `MainTabsFlow`. The signup path is `LoginFlow` → `SignupFlow` → `StationsAddedFlow` → `MainTabsFlow`. Logout uses `logOut(context)` everywhere; it and a switch to another station clear any SnackBar still showing. `AppDrawer` items close the drawer through the `Scaffold`, never `Navigator.pop` (mid-close, a pop would remove the root route).

### Session store

`lib/state/app_session.dart`: `AppSession` (a `ChangeNotifier`) holds the signed-in owner, their stations and the current one, staff, threshold overrides and the purchase orders placed this session. It lives for one app run only (nothing is saved) and is the one place a Supabase backend will plug in. `MyApp` owns it and puts `AppSessionScope` (an `InheritedNotifier`) **above** `MaterialApp`, because pushed routes are not descendants of `MainTabsFlow`. Use `AppSessionScope.of` in build methods and `.read` in callbacks. Login calls `signInDemo` (any login is the demo account; what was typed becomes the owner's email only if it is a valid email, `isValidEmail` in `validators.dart`), Create Account calls `signUp` (fresh station ids from `newId`, `lib/state/ids.dart`, so a new owner never sees demo data), and every logout goes through `logOut` in `login_flow.dart` (`signOut`, then `pushAndRemoveUntil(LoginFlow)`). Never build an id from a list length. `placeReorder` numbers an order with `nextPoNumber` (`PO-<year>-<seq>`, continuing after the highest number the owner has) and rejects one bigger than the tank's room: its space left minus the litres already on order (`TankStock.roomToOrder` with `pendingLitresFor`). Create Reorder gets the same `pendingLitres`, so the form allows exactly what the session accepts.

### Main tabs

`MainTabsFlow` shows the session's current station. It holds `_tabIndex` and keeps the five tabs (Dashboard, Nozzles, Tanks, Stock and Logs, each a full `Scaffold`) in an `IndexedStack`, so a tab keeps its state while hidden. Each tab's key includes the station id, so switching station starts the tabs afresh. A `PopScope` sends system back on any tab but Dashboard to Dashboard. The Tanks tab is the private `_TanksTab` in the same file. Each tab screen includes its own `AppBottomNavBar` with its fixed index (`AppTab` in `app_bottom_nav_bar.dart`) and reports taps through `onNavTap`. Drill-downs (Threshold, Create Reorder, Help Center, Settings, Select Station, Profile) are pushed on top of the active tab; Threshold and Create Reorder stay open after Confirm/Submit and show a SnackBar. Every tab's `Scaffold` shows the app's SnackBars, so the hidden tabs are wrapped in `HeroMode(enabled: false)`; otherwise route transitions find several SnackBar heroes with one tag.

`ProfileFlow` (opened from the Dashboard/Nozzles avatar or the drawer) is pushed but has its own bottom nav, showing the tab it came from. A tab tap there calls `Navigator.pop(tabIndex)`, and `MainTabsFlow._openProfile` switches to the returned tab. Don't push a second `MainTabsFlow`.

Switching station in `SelectStationFlow` calls `AppSession.selectStation`, which every tab follows.

### Data and domain rules

- `lib/models/` holds plain immutable classes that store values, not display text (dates are `DateTime`, litres are `double`). `Station` is the one station model (name, location, status, its `TankConfig`s and `Nozzle`s). `lib/data/demo_*.dart` holds the demo data (including `demoOwner` and `demoStations`) and the lookup functions a real backend will replace: `salesFor`, `tanksForStation`, `purchaseOrdersFor`, `logsFor` and `nozzlesFor`. `buildTanks` (in `demo_tanks.dart`) is the pure tank-level calculation behind `tanksForStation` and `AppSession.tanksFor`. Screens get their tanks, orders, nozzles and logs from the session's lookups (`tanksFor`, `purchaseOrdersFor`, `nozzlesFor`, `logsFor`), passed in by the flows; sales are read with `salesFor`.
- **Per-station scoping:** all sales, stock, order, log and nozzle data is keyed by `stationId`. Every lookup returns an empty list for unknown ids (the session's, for any station the owner doesn't have) and never falls back to another station's data (screens show an `EmptyState` message instead). Keep that guarantee when adding data sources.
- **Derived values are never stored.** Each of these is computed from its source:
  - Revenue is litres × the price constants in `lib/models/sales.dart` (`pricePerLitre(fuelName)` for one grade).
  - Anything that reads "today" combines that period's rows with `PeriodSales.sum`, so the Dashboard, the tank levels and the reports add up the same rows.
  - Every sales period list runs **oldest → newest**, and the periods nest: today is the last weekly row, the last monthly row ("Week 4") is the sum of the weekly rows and the last yearly row ("Month 12") the sum of the monthly rows. `demo_sales.dart` derives those newest rows instead of typing them, and `demo_data_test.dart` checks them.
  - The Dashboard's 7-day trend is the weekly sales rows' `totalRevenue`, so its last point is "Revenue Today" and its badge is the change from the first day to today; its "active / total" count is the dispensing nozzles from the session's `nozzlesFor`.
  - A purchase order belongs to a tank by `tankId` (`fuelName` is for display). Its pending litres count against that tank's room.
  - Demo nozzles keep minute offsets, and `nozzlesFor` turns them into `lastUpdated` times from `DateTime.now()` on every read (the session never caches them), so "x min ago" doesn't drift while the app runs.
  - Tank health (healthy/low/critical) comes from `currentVolume` vs `threshold` in `TankStock`.
  - Tank `currentVolume` is capacity minus today's sales for that station (`buildTanks`). Stock, the Tanks tab, Threshold, Create Reorder and the Dashboard's low-stock alert all read `AppSession.tanksFor`, so their numbers agree and a threshold set this session shows on all of them. Tanks are identified by `TankStock.id`, not fuel name.
- `TODO:` comments mark every place where a backend, auth or a missing screen is needed (password reset, edit profile, edit staff, edit station). Check them before assuming something is unfinished by accident.

### Shared UI

- Use `AppColors` (`lib/theme/app_colors.dart`, the PARCO/TotalEnergies palette, including each grade's color via `AppColors.fuel(name)`) instead of literal colors, `AppDecorations.card` / `AppDecorations.cardShadow` for card styling, and the `TankHealthStyle` extension (`health.color`, `health.label`) for tank badges.
- Format numbers with `formatThousands` and dates with `formatDate` (both in `lib/models/sales.dart`).
- Reuse the shared widgets in `lib/widgets/`: `AppTopBar`, `AppDrawer`, `AppBottomNavBar` (tab definitions in `kAppNavItems`), `AppTextField`, `WaveClipper` (the curved header on Splash, Login, Dashboard and others), `StationPhoto`, `EmptyState`, the tank card pieces in `tank_widgets.dart` and the Dashboard report pieces in `sales_report_widgets.dart`.
- Forms wrap their fields in a `Form` and check them on submit with the shared validators in `lib/utils/validators.dart` (`AppTextField` is a `TextFormField`). Read typed numbers with `parseNumber` / `parseWholeNumber`, which accept "20,000" and Arabic-Indic/Urdu digits (`normaliseDigits`; phone and CNIC checks use it too). Number errors are distinct: "Enter a number…", "Can't be negative", "Too large (max X)". Name a limit in a message with `formatLimit` (rounded down, so the figure it names always passes). Upper bounds for typed amounts are constants on the models: `Station.maxCapacityLitres`, `VehicleLogEntry.maxLitres`, `Station.maxSignupStations` and `Station.maxNozzlesPerGrade`; Threshold and Reorder amounts are at least 1 L.

### Google Places

`lib/services/google_places_service.dart` calls Places API (New). The key comes from `--dart-define=PLACES_API_KEY=...` (`kPlacesApiKey`); it is never stored in source. Every failure (no key, web build, timeout, any network or TLS exception, HTTP error, malformed response) is a `PlacesException` whose `message` is a fixed sentence that is safe to show the user: 400/401/403 (key or API setup), 429 (quota) and 5xx each have their own. Google's own error text can include the Cloud project number and console URLs, so it never goes in `message`; it is kept in `debugMessage` and printed only in debug builds. On web, location search always throws, because Google's Places web service can't be called from a browser; a backend proxy is the long-term fix. The setup steps are in that file's header comment.
