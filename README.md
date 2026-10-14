# PARCO Fuel System

A Retail Fuel Management System (RFMS) app for fuel station owners, built with Flutter as a final-year project. It covers sales, tank stock and reorders, nozzles, vehicle logs and staff, for one or more stations.

## Status

The app is **front-end only**. There is no backend yet: signing in opens a demo account, every figure comes from hardcoded demo data in `lib/data/`, and nothing is saved between runs. A Supabase backend, Manager/Operator roles, shifts, deliveries and a stock ledger are planned. See `RFMS_Trello_Milestones.txt` for the roadmap.

## Commands

```bash
flutter pub get        # install dependencies
flutter run            # run on a device; Windows desktop or web work for quick UI checks
flutter analyze        # expected: "No issues found!"
flutter test           # run all tests
```

Station location search uses Google Places API (New) and needs a key passed in at build time (it is never stored in source):

```bash
flutter run --dart-define=PLACES_API_KEY=your-key
```

The key setup steps are in `lib/services/google_places_service.dart`. Contributor notes on the architecture are in `CLAUDE.md`.
