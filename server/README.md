# PARCO Fuel System API

The backend between the Flutter app and your databases:

```
Flutter app  --HTTP/JSON-->  this server  --> PostgreSQL  (every business record)
                                          \-> Redis       (sessions, caches, live pump readings)
```

The app never connects to PostgreSQL or Redis itself. That keeps the passwords off phones, and it's the only way that works in Chrome, because a browser can't open a database connection.

## Setup (once)

Run these from this `server/` folder.

1. **Settings:** copy `.env.example` to `.env` and fill in your PostgreSQL details. `.env` is git-ignored.
   For **Redis Cloud** (redis.io):
   1. Create a database; the free 30 MB plan is plenty.
   2. Open it, click **Connect**, and copy the `redis://default:PASSWORD@HOST:PORT` URL.
   3. Put it in `.env` as `REDIS_URL=...`.

   If you turned TLS on for that database, the URL starts with `rediss://`. A local Redis uses the `REDIS_HOST`/`REDIS_PORT` lines instead.
2. **Packages:** `dart pub get`
3. **Check the connections:** `dart run bin/check.dart`. It connects to both, lists the tables in the database, and reports any table or column the API needs that is missing. It changes nothing.
4. **Complete the tables:** `dart run bin/migrate.dart --seed`.
   - It works on the existing `fuelmanagementsystemdb` tables in `public`.
   - It adds the missing columns, plus the `purchase_orders` and `nozzle_readings` tables.
   - It drops the empty duplicates `profiles`, `staff` and `fuel_stock`; the API uses `users`, `employees` and `tanks`.
   - `--seed` also fills every table with consistent demo data: two stations, a year of sales and payments, daily deliveries, the stock ledger, 30 days of shifts with meter readings, tank dips, orders, maintenance tickets and the audit log. Sign in as `owner@parco.example` / `demo1234`.
   - Running it again only applies new migration files.
5. **Start the API:** `dart run bin/server.dart`. It listens on `http://localhost:8080`. Open `http://localhost:8080/health` in a browser; it shows `{"postgres":"ok","redis":"ok"}` when both are reachable.

From the Android emulator the server is at `http://10.0.2.2:8080`. From a real phone, use your PC's LAN IP address.

### Demo data
- `dart run bin/migrate.dart --remove-demo --seed` replaces the demo data, so its year of sales ends today again.
- `--remove-demo` on its own deletes it. That only touches the demo owner's rows.
- The database's `trg_prevent_sales_delete` trigger refuses to delete sales, because real sales are voided, not deleted. The removal script switches it off inside its own transaction only.

## What Redis holds

| Key | What it is | Lifetime |
|---|---|---|
| `session:<token>` | The signed-in owner's id for each login | 7 days; deleted on logout |
| `login-fail:<email>` | Failed sign-ins. After 5, that email is locked out | 15 minutes |
| `sales:<station>:<period>` | A cached sales report | 60 seconds |
| `nozzle-live:<id>` | A pump's latest reading (status, litres, flow rate) | 5 minutes |

If Redis is wiped, everyone has to sign in again and the caches rebuild. No business data is lost, because that all lives in PostgreSQL.

## Endpoints

Every route except `/health`, `/auth/signup` and `/auth/login` needs `Authorization: Bearer <token>`, using the token returned by signup or login. A station, tank or nozzle that isn't the signed-in owner's answers 404, exactly as if it didn't exist. Errors come back as `{"error": "<message safe to show the user>"}`.

| Method and path | Body / query | Returns |
|---|---|---|
| `GET /health` |  | Whether PostgreSQL and Redis answer |
| `POST /auth/signup` | `email, password, name?, stationName, stationCount` | `{token, owner}`. Creates the signup stations (the first active, the rest pending). |
| `POST /auth/login` | `email, password` | `{token, owner}` |
| `POST /auth/logout` |  | 204 |
| `GET /me` |  | The owner |
| `GET /stations` |  | The owner's stations, each with its tanks and nozzles |
| `POST /stations` | `name, location?, nozzleCounts{grade: n}, capacities{grade: litres}` | The new station |
| `PATCH /stations/<id>` | `name?` and/or `location?` | The updated station |
| `GET /stations/<id>/sales` | `?period=today\|weekly\|monthly\|yearly` | `[{label, petrolL, dieselL, octaneL}]`, oldest first |
| `GET /stations/<id>/tanks` |  | `[{id, fuelName, capacity, threshold, currentVolume, pendingLitres}]` |
| `PUT /tanks/<id>/threshold` | `litres` | The updated tank |
| `GET /stations/<id>/nozzles` |  | Nozzles, with live Redis readings laid over them |
| `PUT /nozzles/<id>/live` | `status, litres, flowRate` | 204. For the pump simulator or the hardware. |
| `GET /stations/<id>/purchase-orders` |  | Orders, newest first |
| `POST /stations/<id>/purchase-orders` | `tankId, litres, vehicle?` | The new order. Rejected if it doesn't fit the tank's room minus litres already on order. |
| `GET /stations/<id>/vehicle-logs` |  | Today's log entries |
| `GET /staff` |  | The owner's staff |
| `POST /staff` | `name, phone, role?, cnic?, email?` | The new staff member |

The fuel grades are `Petrol`, `Diesel` and `Hi-Octane`.

Every change made through the API (sign-up, a station added or edited, a threshold, a reorder, a new staff member) is also written to `audit_log`, in the same transaction as the change.

## Files

- `migrations/`: the schema changes. They're applied in name order, each file once. To change the schema, add a new numbered file; don't edit one that has already run.
- `seed/demo.sql` and `seed/remove_demo.sql`: the demo data.
- `lib/store.dart`: every SQL query.
- `lib/api.dart`: the routes and all use of Redis.
- `bin/`: `server.dart`, `migrate.dart` and `check.dart`.

The Flutter app's own test of this server is `flutter test test/live_api_test.dart --dart-define=LIVE_API=http://localhost:8080`, run from the project root with the server running and the demo data loaded.
