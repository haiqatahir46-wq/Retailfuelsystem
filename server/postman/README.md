# Testing the API with Postman

There are two ways to test:
- **By hand**, one request at a time: follow [MANUAL_TESTS.md](MANUAL_TESTS.md). It has 34 tests, each with the URL, the body, the expected status and an example reply.
- **Automatically**, all at once: import the collection below and run it.

These two files test every endpoint of the backend:

- `PARCO_Fuel_System_API.postman_collection.json`: 43 requests in 12 folders, with 100 automatic checks.
- `PARCO_Local.postman_environment.json`: the server address and the demo login.

Each request has a **Tests** tab that checks the reply: the status code, the fields, the figures, the error message. Some requests also save values for the ones after them, such as the login token and a station, tank and nozzle id.

## Before you start

1. **Start the server** from the `server` folder with `dart run bin/server.dart`, and leave it running.
2. **Load the demo data**, if it isn't loaded yet: `dart run bin/migrate.dart --seed`.

## In Postman

1. **Import:** click **Import** at the top left and drag both `.json` files from this folder in. You'll see the **PARCO Fuel System API** collection and the **PARCO Local** environment.
2. **Pick the environment:** in the top-right environment dropdown, choose **PARCO Local**.
3. **Run everything:**
   1. Hover over the collection, click **⋯**, then **Run collection**.
   2. Keep the order as it is.
   3. Click **Run PARCO Fuel System API**.
   4. Every check should be green, 100 passed. A red line names the request, the check and what came back instead.
4. **Or try one request at a time:**
   1. Open **2. Sign in → Login (demo owner)** and click **Send**. This saves the token.
   2. Open any other request and click **Send**.
   3. The reply is at the bottom: the **Body** tab shows the JSON, and **Test Results** shows the checks.
   4. Requests after *Login* need it to have run first, and some also need *List my stations*, which saves the ids.

## What the folders test

| Folder | Checks |
|---|---|
| 1. Health | The server is up and reaches PostgreSQL and Redis. |
| 2. Sign in | A wrong password, missing fields, the token, and requests without a token. |
| 3. Stations | Your stations, another owner's (hidden), adding a station, editing its location. |
| 4. Sales | Today, weekly, monthly and yearly sales, and that the periods add up. |
| 5. Tanks | Levels make sense; a threshold can't exceed the tank or be 0. |
| 6. Nozzles | Statuses, and a live pump reading going through Redis. |
| 7. Purchase orders | An order too big for the tank is refused; a valid one gets a PO number. |
| 8. Vehicle log | Today's entries. |
| 9. Staff | Adding staff; the same CNIC twice is refused. |
| 10. Sign up | A new account, a duplicate email, a bad email, a short password. |
| 11. Security | Another owner's station is hidden; 5 wrong passwords lock an email (Redis). |
| 12. Log out | The token stops working. |

## Afterwards

A run adds a 100 L order, a staff member called *Postman Tester*, a *Postman Test Station* and a `postman-…@example.com` account.

To reset all of it, run this from the `server` folder: `dart run bin/migrate.dart --remove-demo --seed`.

To run the same tests from a terminal instead of Postman, from the project root:

```
npx newman run server/postman/PARCO_Fuel_System_API.postman_collection.json -e server/postman/PARCO_Local.postman_environment.json
```
