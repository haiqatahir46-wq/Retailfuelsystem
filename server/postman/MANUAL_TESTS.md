# Manual API tests in Postman

34 tests you type in by hand, one request at a time. Every status code and error message below was checked against your server on 3 November 2026.

The numbers in the examples (litres, ids, tokens, PO numbers) **will be different for you**: the demo data has random daily sales, and ids change every time it is reloaded. What must match is the **status code**, the **error messages** and the **shape** of the reply.

---

## Part A: get ready (once, about 5 minutes)

### A1. Start the server

In VS Code, open a terminal (**Terminal → New Terminal**) and run:

```
cd server
dart run bin/server.dart
```

Wait for `PARCO Fuel System API on http://localhost:8080`, and **leave this terminal open** while you test.

### A2. Load fresh demo data (recommended)

In a **second** terminal:

```
cd server
dart run bin/migrate.dart --remove-demo --seed
```

It should end with `Demo data ready. Sign in as owner@parco.example / demo1234.` This makes today's sales current and removes rows left by earlier tests.

### A3. Make an environment in Postman

An environment holds values you'd otherwise paste into every request: the server address, your login token and a few ids.

1. In Postman's left sidebar, click **Environments**, then **+** (Create new environment).
2. Name it **PARCO Manual**.
3. Add these five rows in the **Variable** column. Only `baseUrl` gets a value now:

   | Variable | Current value |
   |---|---|
   | `baseUrl` | `http://localhost:8080` |
   | `token` | *(leave empty)* |
   | `stationId` | *(leave empty)* |
   | `tankId` | *(leave empty)* |
   | `nozzleId` | *(leave empty)* |

4. Press **Ctrl+S** to save.
5. At the **top right** of Postman, open the environment dropdown and choose **PARCO Manual**.

### A4. How to send each request

Do this for every test:

1. Click **+** at the top to open a new request tab.
2. Choose the **method** in the dropdown left of the address box (GET, POST, PUT or PATCH).
3. Type the **URL** exactly as written, e.g. `{{baseUrl}}/health`. With the environment selected, `{{baseUrl}}` turns orange.
4. Open the **Authorization** tab:
   - For **Auth: none**, set Auth Type to **No Auth**.
   - For **Auth: token**, set Auth Type to **Bearer Token** and type `{{token}}` in the Token box.
5. **Body**, only when the test gives one: open the **Body** tab, choose **raw**, pick **JSON** in the blue dropdown on the right, and paste the body.
6. Click **Send**.
7. Compare the **status** (top right of the reply, e.g. `200 OK`) and the **JSON** below it with the test.

**How to save a value into a variable:**
1. In the reply, select the value without its quotes, e.g. the long token.
2. Right-click it, choose **Set: PARCO Manual**, then pick the variable (e.g. `token`).

Or go to **Environments → PARCO Manual**, paste the value into the **Current value** column, and press Ctrl+S.

---

## Part B: the tests

### 1. Server health

**Test 1: Health check**
- `GET {{baseUrl}}/health`, **Auth:** none
- **Expect:** `200 OK`
  ```json
  {"postgres":"ok","redis":"ok"}
  ```
- ✔ Both say `"ok"`. That means the server reached your PostgreSQL database and Redis Cloud.

### 2. Logging in

**Test 2: Wrong password is refused**
- `POST {{baseUrl}}/auth/login`, **Auth:** none
- **Body:**
  ```json
  {"email": "owner@parco.example", "password": "wrong-password"}
  ```
- **Expect:** `401 Unauthorized`
  ```json
  {"error":"Wrong email or password."}
  ```

**Test 3: Log in with the demo account**
- `POST {{baseUrl}}/auth/login`, **Auth:** none
- **Body:**
  ```json
  {"email": "owner@parco.example", "password": "demo1234"}
  ```
- **Expect:** `200 OK`
  ```json
  {"token":"f56c74d61826a21e5e95a6fea9979ba57fa9cbc140f1798e047356c46b141211",
   "owner":{"id":"14","name":"Demo Owner","email":"owner@parco.example"}}
  ```
- ✔ `token` is 64 letters/digits. ✔ The owner's email is `owner@parco.example`.
- ➜ **Save the token** (without quotes) into the `token` variable. Every test marked *Auth: token* uses it.

**Test 4: Who am I**
- `GET {{baseUrl}}/me`, **Auth:** token
- **Expect:** `200 OK`
  ```json
  {"id":"14","name":"Demo Owner","email":"owner@parco.example"}
  ```

**Test 5: No token means no access**
- `GET {{baseUrl}}/stations`, **Auth:** **none** (on purpose)
- **Expect:** `401 Unauthorized`
  ```json
  {"error":"Please sign in."}
  ```

### 3. Stations

**Test 6: List my stations**
- `GET {{baseUrl}}/stations`, **Auth:** token
- **Expect:** `200 OK`, a list of two stations, shortened here:
  ```json
  [{"id":"24","name":"Amir Filling, Pattoki","location":"Pattoki, Punjab","status":"active",
    "tanks":[{"id":"45","stationId":"24","fuelName":"Petrol","capacity":25000.0,"threshold":18000.0,
              "currentVolume":6927.52,"pendingLitres":2000.0}, …],
    "nozzles":[{"id":"133","pumpNumber":1,"nozzleNumber":1,"fuelName":"Petrol","litres":3302.73,
                "flowRate":0.0,"lastUpdated":"2026-11-03T20:06:07.380332Z","status":"dispensing"}, …]},
   {"id":"25","name":"Demo Station 2", …}]
  ```
- ✔ Two stations: **Amir Filling, Pattoki** and **Demo Station 2**. Each has `tanks` (Petrol, Diesel, Hi-Octane) and `nozzles`.
- ➜ **Save three ids from the first station:**
  - `stationId`: the station's `"id"` (e.g. `24`);
  - `tankId`: the first tank's `"id"`, the Petrol tank (e.g. `45`);
  - `nozzleId`: the first nozzle's `"id"` (e.g. `133`).

**Test 7: A station that isn't mine is hidden**
- `GET {{baseUrl}}/stations/999999/tanks`, **Auth:** token
- **Expect:** `404 Not Found`
  ```json
  {"error":"Station not found."}
  ```
- ✔ Another owner's station gets exactly the same reply, so nobody can see someone else's data.

### 4. Sales

**Test 8: Today**
- `GET {{baseUrl}}/stations/{{stationId}}/sales?period=today`, **Auth:** token
- **Expect:** `200 OK`, one row:
  ```json
  [{"label":"Today","petrolL":19613.51,"dieselL":9118.7,"octaneL":2996.96}]
  ```
- ✔ Note today's `petrolL`; Test 9 checks it.

**Test 9: Weekly**
- `GET {{baseUrl}}/stations/{{stationId}}/sales?period=weekly`, **Auth:** token
- **Expect:** `200 OK`, seven rows, `Day 1` to `Day 7`:
  ```json
  [{"label":"Day 1","petrolL":16875.38,"dieselL":9489.59,"octaneL":2800.03}, …,
   {"label":"Day 7","petrolL":19613.51,"dieselL":9118.7,"octaneL":2996.96}]
  ```
- ✔ **Day 7 is today**: its numbers equal Test 8's.

**Test 10: Monthly**
- `GET {{baseUrl}}/stations/{{stationId}}/sales?period=monthly`, **Auth:** token
- **Expect:** `200 OK`, four rows, `Week 1` to `Week 4`.
- ✔ `Week 4` is the last 7 days: its `petrolL` equals the seven Day rows of Test 9 added up.

**Test 11: Yearly**
- `GET {{baseUrl}}/stations/{{stationId}}/sales?period=yearly`, **Auth:** token
- **Expect:** `200 OK`, twelve rows, `Month 1` to `Month 12`.

**Test 12: Unknown period**
- `GET {{baseUrl}}/stations/{{stationId}}/sales?period=daily`, **Auth:** token
- **Expect:** `422 Unprocessable Entity`
  ```json
  {"error":"Unknown period \"daily\". Use one of: today, weekly, monthly, yearly."}
  ```

### 5. Tanks

**Test 13: List tanks**
- `GET {{baseUrl}}/stations/{{stationId}}/tanks`, **Auth:** token
- **Expect:** `200 OK`
  ```json
  [{"id":"45","stationId":"24","fuelName":"Petrol","capacity":25000.0,"threshold":18000.0,"currentVolume":6927.52,"pendingLitres":2000.0},
   {"id":"46","stationId":"24","fuelName":"Diesel","capacity":25000.0,"threshold":18000.0,"currentVolume":15878.23,"pendingLitres":0.0},
   {"id":"47","stationId":"24","fuelName":"Hi-Octane","capacity":25000.0,"threshold":18000.0,"currentVolume":21722.28,"pendingLitres":0.0}]
  ```
- ✔ Every `currentVolume` is between 0 and `capacity`. ✔ Petrol has `2000.0` litres already on order.

**Test 14: Threshold bigger than the tank is refused**
- `PUT {{baseUrl}}/tanks/{{tankId}}/threshold`, **Auth:** token
- **Body:**
  ```json
  {"litres": 30000}
  ```
- **Expect:** `422 Unprocessable Entity`
  ```json
  {"error":"Can't be more than the tank holds (25,000 L)."}
  ```

**Test 15: Set the threshold**
- `PUT {{baseUrl}}/tanks/{{tankId}}/threshold`, **Auth:** token
- **Body:**
  ```json
  {"litres": 18000}
  ```
- **Expect:** `200 OK`, the tank with its new threshold:
  ```json
  {"id":"45","stationId":"24","fuelName":"Petrol","capacity":25000.0,"threshold":18000.0,"currentVolume":6927.52,"pendingLitres":2000.0}
  ```
- ✔ `"threshold":18000.0`. 18,000 L is the demo's own value, so this changes nothing. Try `5000` too, then run Test 13 to see it saved.

### 6. Nozzles and live pump readings (Redis)

**Test 16: List nozzles**
- `GET {{baseUrl}}/stations/{{stationId}}/nozzles`, **Auth:** token
- **Expect:** `200 OK`, a list of 12 nozzles for Amir Filling:
  ```json
  [{"id":"133","pumpNumber":1,"nozzleNumber":1,"fuelName":"Petrol","litres":3302.73,"flowRate":0.0,
    "lastUpdated":"2026-11-03T20:06:07.380332Z","status":"dispensing"}, …]
  ```
- ✔ Every `status` is `dispensing`, `idle` or `fault`.

**Test 17: Send a live pump reading**
- `PUT {{baseUrl}}/nozzles/{{nozzleId}}/live`, **Auth:** token
- **Body:**
  ```json
  {"status": "dispensing", "litres": 42.5, "flowRate": 38}
  ```
- **Expect:** `204 No Content`, with an empty body. That's correct.

**Test 18: The reading shows on the nozzle**
- Send **Test 16** again.
- **Expect:** `200 OK`, and the first nozzle now reads:
  ```json
  {"id":"133","pumpNumber":1,"nozzleNumber":1,"fuelName":"Petrol","litres":42.5,"flowRate":38.0,
   "lastUpdated":"2026-11-03T20:07:49.090370Z","status":"dispensing"}
  ```
- ✔ `"litres":42.5` and `"flowRate":38.0`. This came from **Redis**. After 5 minutes it expires and the nozzle shows its stored values again.

### 7. Purchase orders (reorders)

**Test 19: List orders**
- `GET {{baseUrl}}/stations/{{stationId}}/purchase-orders`, **Auth:** token
- **Expect:** `200 OK`, newest first:
  ```json
  [{"poNumber":"PO-2026-0054","date":"2026-11-03T18:06:07.380332Z","fuelName":"Petrol","tankId":"45",
    "litres":2000.0,"vehicle":"carriage","status":"pending"},
   {"poNumber":"PO-2026-0056", …,"status":"delivered"}, …]
  ```

**Test 20: An order too big for the tank is refused**
- `POST {{baseUrl}}/stations/{{stationId}}/purchase-orders`, **Auth:** token
- **Body:** use your own `tankId` value. The `{{tankId}}` variable also works inside the body:
  ```json
  {"tankId": "{{tankId}}", "litres": 1000000}
  ```
- **Expect:** `422 Unprocessable Entity`
  ```json
  {"error":"Only 16,072 L of space left (2,000 L already on order)."}
  ```
- ✔ The room the server allows is the space left in the tank minus what's already on order. Your figure will differ.

**Test 21: Place a small order**
- `POST {{baseUrl}}/stations/{{stationId}}/purchase-orders`, **Auth:** token
- **Body:**
  ```json
  {"tankId": "{{tankId}}", "litres": 100}
  ```
- **Expect:** `201 Created`
  ```json
  {"poNumber":"PO-2026-0061","date":"2026-11-03T20:07:51.211614Z","fuelName":"Petrol","tankId":"45",
   "litres":100.0,"vehicle":"carriage","status":"pending"}
  ```
- ✔ A new `PO-<year>-<number>` with status `pending`.

**Test 22: The new order is first in the list**
- Send **Test 19** again.
- ✔ The first order is the one from Test 21 (same `poNumber`). ✔ Run **Test 13** too: Petrol's `pendingLitres` went up by 100.

### 8. Vehicle log

**Test 23: Today's vehicle log**
- `GET {{baseUrl}}/stations/{{stationId}}/vehicle-logs`, **Auth:** token
- **Expect:** `200 OK`
  ```json
  [{"id":"66","vehicle":"carriage","fuelType":"Hi-Octane","litres":null,"status":"pending",
    "loggedAt":"2026-11-03T20:06:07.380332Z","nozzleId":"143","plateNumber":"LEA-1222"},
   {"id":"64","vehicle":"carriage","fuelType":"Diesel","litres":1500.0,"status":"completed", …}, …]
  ```
- ✔ `completed` entries have litres; `pending` ones have `null`.

### 9. Staff

**Test 24: List staff**
- `GET {{baseUrl}}/staff`, **Auth:** token
- **Expect:** `200 OK`
  ```json
  [{"id":"27","name":"Bilal Ahmed","role":"Manager","phone":"0300-1234567","status":"active"},
   {"id":"28","name":"Usman Tariq","role":"Attendant","phone":"0301-2345678","status":"active"},
   {"id":"29","name":"Imran Shah","role":"Cashier","phone":"0302-3456789","status":"on_leave"}]
  ```

**Test 25: Add a staff member**
- `POST {{baseUrl}}/staff`, **Auth:** token
- **Body:**
  ```json
  {"name": "Ali Raza", "phone": "0303-4567890", "cnic": "35202-7654321-9"}
  ```
- **Expect:** `201 Created`
  ```json
  {"id":"30","name":"Ali Raza","role":"Attendant","phone":"0303-4567890","status":"active"}
  ```
- ✔ Run **Test 24** again: Ali Raza is now in the list.

**Test 26: The same CNIC twice is refused**
- Send **Test 25** again, without changing anything.
- **Expect:** `409 Conflict`
  ```json
  {"error":"A staff member with this CNIC is already registered."}
  ```

### 10. Adding and editing a station

**Test 27: Nozzles without a tank are refused**
- `POST {{baseUrl}}/stations`, **Auth:** token
- **Body:**
  ```json
  {"name": "My Test Station", "nozzleCounts": {"Petrol": 2}, "capacities": {}}
  ```
- **Expect:** `422 Unprocessable Entity`
  ```json
  {"error":"Give Petrol a tank capacity, since it has nozzles."}
  ```

**Test 28: Add a station**
- `POST {{baseUrl}}/stations`, **Auth:** token
- **Body:**
  ```json
  {
    "name": "My Test Station",
    "location": "Lahore",
    "nozzleCounts": {"Petrol": 2, "Diesel": 1},
    "capacities": {"Petrol": 20000, "Diesel": 15000}
  }
  ```
- **Expect:** `201 Created`
  ```json
  {"id":"26","name":"My Test Station","location":"Lahore","status":"active",
   "tanks":[{"id":"51","fuelName":"Petrol","capacity":20000.0,"threshold":5000.0,"currentVolume":0.0, …},
            {"id":"52","fuelName":"Diesel","capacity":15000.0,"threshold":3750.0,"currentVolume":0.0, …}],
   "nozzles":[{"pumpNumber":1,"nozzleNumber":1,"fuelName":"Petrol","status":"idle", …},
              {"pumpNumber":1,"nozzleNumber":2,"fuelName":"Petrol","status":"idle", …},
              {"pumpNumber":2,"nozzleNumber":1,"fuelName":"Diesel","status":"idle", …}]}
  ```
- ✔ 2 tanks, each with a threshold of a quarter of its capacity, and starting empty (`0.0`). ✔ 3 idle nozzles.
- ➜ Note this new station's `"id"` (e.g. `26`) for Test 29.

**Test 29: Change the station's location**
- `PATCH {{baseUrl}}/stations/26`, **Auth:** token. Put your id from Test 28 instead of `26`.
- **Body:**
  ```json
  {"location": "Main GT Road, Lahore"}
  ```
- **Expect:** `200 OK`
- ✔ `"location":"Main GT Road, Lahore"`. ✔ `"name"` is still `"My Test Station"`.

### 11. Signing up

**Test 30: Create a new account**
- `POST {{baseUrl}}/auth/signup`, **Auth:** none
- **Body:**
  ```json
  {"email": "postman-test1@example.com", "password": "test1234", "stationName": "My New Station", "stationCount": 2}
  ```
- **Expect:** `201 Created`
  ```json
  {"token":"b505995e…12ba","owner":{"id":"15","name":"postman-test1","email":"postman-test1@example.com"}}
  ```
- Use an email starting with `postman-` and ending in `@example.com`. The reset command (Part C) deletes those accounts.

**Test 31: The same email twice is refused**
- Send **Test 30** again.
- **Expect:** `409 Conflict`
  ```json
  {"error":"An account with this email already exists."}
  ```

### 12. Security: wrong-password lockout (Redis)

**Test 32: Five wrong passwords lock the email**
- `POST {{baseUrl}}/auth/login`, **Auth:** none
- **Body:**
  ```json
  {"email": "lockout-test@example.com", "password": "wrong"}
  ```
- Click **Send six times**:
  - sends 1 to 5: `401 Unauthorized`, `{"error":"Wrong email or password."}`
  - send 6: `429 Too Many Requests`
    ```json
    {"error":"Too many wrong passwords. Try again in 15 minutes."}
    ```
- ✔ The lock lasts 15 minutes. To repeat this test sooner, change the email.

### 13. Logging out

**Test 33: Log out**
- `POST {{baseUrl}}/auth/logout`, **Auth:** token
- **Expect:** `204 No Content`, with an empty body.

**Test 34: The old token stops working**
- Send **Test 4** again.
- **Expect:** `401 Unauthorized`
  ```json
  {"error":"Your session has expired. Please sign in again."}
  ```
- ✔ To keep testing, run **Test 3** again and save the new token.

---

## Part C: afterwards

These tests add a 100 L order, the staff member *Ali Raza*, *My Test Station* and the account `postman-test1@example.com`. To reset everything to fresh demo data, run this from the `server` folder:

```
dart run bin/migrate.dart --remove-demo --seed
```

Your own Gmail account is not touched. Reloading changes the ids, so repeat Test 3 and Test 6 to save new values.

## Results checklist

| # | Test | Expected | ✔ |
|---|---|---|---|
| 1 | Health | 200 | |
| 2 | Wrong password | 401 | |
| 3 | Login | 200 | |
| 4 | Who am I | 200 | |
| 5 | No token | 401 | |
| 6 | List stations | 200 | |
| 7 | Not my station | 404 | |
| 8 | Sales today | 200 | |
| 9 | Sales weekly | 200 | |
| 10 | Sales monthly | 200 | |
| 11 | Sales yearly | 200 | |
| 12 | Unknown period | 422 | |
| 13 | List tanks | 200 | |
| 14 | Threshold too big | 422 | |
| 15 | Set threshold | 200 | |
| 16 | List nozzles | 200 | |
| 17 | Live reading | 204 | |
| 18 | Reading shows | 200 | |
| 19 | List orders | 200 | |
| 20 | Order too big | 422 | |
| 21 | Place order | 201 | |
| 22 | Order listed first | 200 | |
| 23 | Vehicle log | 200 | |
| 24 | List staff | 200 | |
| 25 | Add staff | 201 | |
| 26 | Same CNIC | 409 | |
| 27 | Station without tank | 422 | |
| 28 | Add station | 201 | |
| 29 | Edit location | 200 | |
| 30 | Sign up | 201 | |
| 31 | Same email | 409 | |
| 32 | Lockout (6th try) | 429 | |
| 33 | Log out | 204 | |
| 34 | Old token | 401 | |

## If something doesn't match

| You see | Why | Fix |
|---|---|---|
| *Could not send request* / `ECONNREFUSED` | The server isn't running | Part A1; check the terminal is still open |
| `{{baseUrl}}` shows red, or the URL looks wrong | No environment selected | Pick **PARCO Manual** at the top right (A3) |
| `401` *Please sign in.* | No token sent | Authorization tab: **Bearer Token**, `{{token}}`; check the `token` variable isn't empty |
| `401` *Your session has expired…* | You logged out, or the token is old | Run Test 3 again and save the new token |
| `404` *Station not found.* on a test that should work | `stationId` is old (ids change when demo data is reloaded) | Run Test 6 again and save new ids |
| `409` on Test 25 or Test 30 the first time | You ran it before | Change the CNIC digits or the email number, or reset (Part C) |
| `429` on the first try of Test 32 | That email is still locked (15 minutes) | Use another email, e.g. `lockout-test2@example.com` |
| `400` *The request body is not valid JSON.* | The body was sent as form-data, or has a typo (a missing quote or comma) | Body tab: **raw**, then **JSON**; paste the body exactly as shown |
| `422` *"litres" must be a number.* or *"phone" is required.* | A field name is misspelled in the body (e.g. `liters` instead of `litres`) | Paste the body exactly as shown; field names are case-sensitive |
| Today's sales are all `0` | The demo data is from an earlier day | Reload it (A2) |
