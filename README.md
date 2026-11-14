# PARCO Fuel System

A Retail Fuel Management System (RFMS) for fuel station owners, built as a final-year project. The app covers sales, tank stock and reorders, nozzles and live pump readings, vehicle logs and staff, for one or more stations.

## How it fits together

| Part | Built with | Where |
|---|---|---|
| App (frontend) | Flutter, Dart | This repository |
| Backend (API) | Python, FastAPI | Its own repository: **PARCO backend** (see below) |
| Database | PostgreSQL (`fuelmanagementsystemdb`) | Set up by the backend's migrations |
| Fast store | Redis Cloud | Sessions, the wrong-password lockout, cached reports, live pump readings |
| Station device | A microcontroller at each gas station | Signs in with its station's own ID and password and sends pump readings |

The app never talks to the databases directly. It only talks to the backend over HTTP.

**Backend repository:** PARCO backend, in its own GitHub repository (link to be added here). Its README covers setup and every endpoint. Its `AUDIT_REPORT.md` explains every calculation and the independent audit that checks them.

## Status

| Area | Status |
|---|---|
| App screens | Built: Dashboard, Nozzles, Tanks, Stock, Logs, staff, station setup, threshold and reorders |
| Live data | Built: everything the app shows comes from the database through the backend |
| Backend | Built in Python; the original Dart backend in `server/` is kept for reference |
| Live pump readings | Built: a station's device can send readings, which reach the screen within 60 seconds |
| Saving pump history as sales | Next: waits for the microcontroller's API |
| Roles, shifts, price setup, reports | Planned (see `RFMS_Trello_Milestones.txt`) |

**Quality:** 244 app tests and 118 backend tests pass. `flutter analyze` reports no issues. A 57-check independent audit of the backend passes; its one warning is about old demo data. The audit was itself tested: it catches all 21 deliberately planted bugs.

## Running it

1. **Start the backend.** In the backend repository, double-click `start_server.bat`, or follow its README. It serves the API on `http://localhost:8080`.
2. **Run the app:**

   ```bash
   flutter pub get        # install dependencies
   flutter run            # pick a device; Windows desktop or web work for quick checks
   ```

3. **Sign in** with the demo account `owner@parco.example` / `demo1234`. To load the demo data, run `migrate --seed` in the backend.

Other commands:

```bash
flutter run --dart-define=DEMO_DATA=true                          # built-in demo data, no backend needed
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080   # a backend on another PC (e.g. from a phone)
flutter run --dart-define=PLACES_API_KEY=your-key                 # station location search (Google Places)
flutter analyze                                                   # expected: "No issues found!"
flutter test                                                      # all tests
flutter test test/live_api_test.dart --dart-define=LIVE_API=http://localhost:8080   # against the running backend
```

The Places key setup is described in `lib/services/google_places_service.dart`; the key is never stored in source. Notes on the app's architecture are in `CLAUDE.md`.

## Repository layout

| Path | What it is |
|---|---|
| `lib/screens/` | The screens: they show data and report taps |
| `lib/navigation/` | The flows: they read data from the session and move between screens |
| `lib/state/app_session.dart` | The session store: the signed-in owner and each station's data |
| `lib/services/api_client.dart` | Talks to the backend and turns its JSON into the app's models |
| `lib/models/`, `lib/data/` | The data models, and the built-in demo data used by the tests |
| `test/` | The app's 244 tests |
| `server/` | The first backend, written in Dart, kept for reference |
| `*_preview.html`, `navbar-preview/` | Design mock-ups of each screen |
