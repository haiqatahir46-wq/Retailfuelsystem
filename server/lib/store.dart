import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'http_utils.dart';

/// The grades every station sells, in display order. They match the rows
/// migrations/001 puts in fuel_products and the app's kFuelGrades.
const kFuelGrades = ['Petrol', 'Diesel', 'Hi-Octane'];

// The same limits the app's forms enforce (lib/models/station.dart), so the
// API accepts exactly what the app lets an owner type.
const maxSignupStations = 20;
const maxNozzlesPerGrade = 40;
const maxCapacityLitres = 1000000.0;

/// A new tank's reorder threshold as a fraction of its capacity, until the
/// owner sets one (Station.defaultThresholdFraction in the app).
const defaultThresholdFraction = 0.25;

const salesPeriods = ['today', 'weekly', 'monthly', 'yearly'];

/// The database's `timestamp` columns hold station-local time (every
/// connection uses the configured time zone). This turns one into an
/// absolute time, so it reaches the app as a correct UTC ISO-8601 string.
const _absolute = "AT TIME ZONE current_setting('TimeZone')";

/// Sorts fuel_products rows into [kFuelGrades] order.
const _gradeOrder = "array_position(ARRAY['Petrol', 'Diesel', 'Hi-Octane']::text[], fp.name::text)";

/// Each sales period's buckets, oldest -> newest, in station-local
/// `timestamp`s like sales.sale_time (so the sale_time index is usable):
/// today is one bucket; weekly is the last 7 days ending today; monthly the
/// last 4 seven-day weeks ending today (so its last bucket covers exactly
/// the weekly rows); yearly the last 12 calendar months ending with this
/// one. Labels match the app's ('Day 1', 'Week 4', 'Month 12').
const _salesBuckets = {
  'today': '''
    SELECT 1::bigint AS n, 'Today'::text AS label,
           date_trunc('day', localtimestamp) AS start_at,
           date_trunc('day', localtimestamp) + interval '1 day' AS end_at''',
  'weekly': '''
    SELECT n, 'Day ' || n AS label, start_at, start_at + interval '1 day' AS end_at
    FROM (SELECT row_number() OVER (ORDER BY b) AS n, b AS start_at
          FROM generate_series(date_trunc('day', localtimestamp) - interval '6 days',
                               date_trunc('day', localtimestamp), interval '1 day') AS b) AS days''',
  'monthly': '''
    SELECT n, 'Week ' || n AS label, start_at, start_at + interval '7 days' AS end_at
    FROM (SELECT row_number() OVER (ORDER BY b) AS n, b AS start_at
          FROM generate_series(date_trunc('day', localtimestamp) - interval '27 days',
                               date_trunc('day', localtimestamp) - interval '6 days', interval '7 days') AS b) AS weeks''',
  'yearly': '''
    SELECT n, 'Month ' || n AS label, start_at, start_at + interval '1 month' AS end_at
    FROM (SELECT row_number() OVER (ORDER BY b) AS n, b AS start_at
          FROM generate_series(date_trunc('month', localtimestamp) - interval '11 months',
                               date_trunc('month', localtimestamp), interval '1 month') AS b) AS months''',
};

/// Each tank with its grade and the litres already on order. Current volume
/// is the stored tanks.current_volume (what deliveries, sales and readings
/// keep up to date), and pending litres count against the room to reorder.
const _tankSelect = '''
  SELECT t.tank_id, t.station_id, fp.name AS fuel_name,
         t.capacity_liters::float8 AS capacity,
         t.low_stock_threshold::float8 AS threshold,
         t.current_volume::float8 AS current_volume,
         COALESCE(pending.liters, 0)::float8 AS pending_liters
  FROM tanks t
  JOIN fuel_products fp ON fp.product_id = t.product_id
  LEFT JOIN LATERAL (
    SELECT SUM(po.liters_ordered) AS liters FROM purchase_orders po
    WHERE po.tank_id = t.tank_id AND po.status = 'pending'
  ) AS pending ON true''';

/// All of the API's SQL, on the fuelmanagementsystemdb tables. Every method
/// that reads or changes a station's data takes the signed-in owner's id
/// and checks the station is theirs, so one owner can never read or change
/// another owner's stations, even with a guessed id. Results are JSON-ready
/// maps shaped like the app's models (ids as strings, times as ISO-8601 UTC).
class Store {
  Store(this._db);

  final Pool _db;

  Future<void> ping() => _db.execute('SELECT 1');

  // ---- Owners -------------------------------------------------------------

  /// Creates the owner and their signup stations in one transaction: the
  /// first is active under [stationName], the rest are pending "Station N"
  /// (the app's Station.fromSignup). Returns null when the email is taken.
  /// The password is hashed by PostgreSQL (pgcrypto bcrypt), never stored.
  Future<Map<String, Object?>?> signUp({
    required String name,
    required String email,
    required String password,
    required String stationName,
    required int stationCount,
  }) {
    return _db.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named('''
          INSERT INTO users (username, password_hash, role, full_name, email)
          VALUES (lower(@email), crypt(@password, gen_salt('bf')), 'owner', @name, @email)
          ON CONFLICT DO NOTHING
          RETURNING user_id, full_name, email'''),
        parameters: {'name': name, 'email': email, 'password': password},
      );
      if (rows.isEmpty) return null;
      final owner = rows.first.toColumnMap();
      final count = stationCount.clamp(1, maxSignupStations);
      for (var i = 1; i <= count; i++) {
        await tx.execute(
          Sql.named('INSERT INTO stations (owner_id, name, status) VALUES (@owner, @name, @status)'),
          parameters: {
            'owner': owner['user_id'],
            'name': i == 1 ? stationName : 'Station $i',
            'status': i == 1 ? 'active' : 'pending',
          },
        );
      }
      final ownerId = owner['user_id'] as int;
      await _audit(tx, userId: ownerId, action: 'INSERT', table: 'users', recordId: ownerId,
          newValue: {'email': email, 'role': 'owner', 'stations': count});
      return _ownerJson(owner);
    });
  }

  /// The active account whose email (or username) and password match, with
  /// its role, or null. A password_hash that isn't a bcrypt hash (e.g. typed
  /// into the table by hand) never matches, rather than making crypt() fail.
  Future<Map<String, Object?>?> verifyLogin(String login, String password) async {
    final rows = await _db.execute(
      Sql.named('''
        SELECT user_id, full_name, email, role FROM users
        WHERE (lower(email) = lower(@login) OR lower(username) = lower(@login))
          AND is_active
          AND CASE WHEN password_hash LIKE '\$2_\$%'
                   THEN password_hash = crypt(@password, password_hash)
                   ELSE false END
        ORDER BY user_id
        LIMIT 1'''),
      parameters: {'login': login, 'password': password},
    );
    if (rows.isEmpty) return null;
    final user = rows.first.toColumnMap();
    return {..._ownerJson(user), 'role': user['role']};
  }

  Future<Map<String, Object?>?> owner(int ownerId) async {
    final rows = await _db.execute(
      Sql.named('SELECT user_id, full_name, email FROM users WHERE user_id = @id AND is_active'),
      parameters: {'id': ownerId},
    );
    return rows.isEmpty ? null : _ownerJson(rows.first.toColumnMap());
  }

  // ---- Stations -----------------------------------------------------------

  Future<bool> ownsStation(int ownerId, int stationId) async {
    final rows = await _db.execute(
      Sql.named('SELECT 1 FROM stations WHERE id = @station AND owner_id = @owner'),
      parameters: {'station': stationId, 'owner': ownerId},
    );
    return rows.isNotEmpty;
  }

  /// The owner's stations, oldest first, each with its tanks and nozzles.
  Future<List<Map<String, Object?>>> stations(int ownerId) async {
    final rows = await _db.execute(
      Sql.named('SELECT id, name, address, status FROM stations WHERE owner_id = @owner ORDER BY id'),
      parameters: {'owner': ownerId},
    );
    return [for (final row in rows) await _stationJson(row.toColumnMap())];
  }

  Future<Map<String, Object?>?> station(int ownerId, int stationId) async {
    final rows = await _db.execute(
      Sql.named('SELECT id, name, address, status FROM stations WHERE id = @station AND owner_id = @owner'),
      parameters: {'station': stationId, 'owner': ownerId},
    );
    return rows.isEmpty ? null : _stationJson(rows.first.toColumnMap());
  }

  /// A station set up through Add Station, in one transaction. Each grade
  /// with a capacity above 0 gets a tank at the default threshold, starting
  /// empty until a delivery or tank reading is recorded. Each grade's nozzle
  /// count becomes that many idle nozzles on that grade's tank, two per pump
  /// and one grade per pump (the app's Station.fromSetup layout). The caller
  /// ensures every grade with nozzles has a capacity, since a nozzle must
  /// draw from a tank.
  Future<Map<String, Object?>> createStation({
    required int ownerId,
    required String name,
    required String location,
    required Map<String, int> nozzleCounts,
    required Map<String, double> capacities,
  }) async {
    final stationId = await _db.runTx((tx) async {
      final totalNozzles = nozzleCounts.values.fold<int>(0, (sum, count) => sum + count);
      final inserted = await tx.execute(
        Sql.named('''
          INSERT INTO stations (owner_id, name, address, no_of_nozzles)
          VALUES (@owner, @name, @address, @nozzles) RETURNING id'''),
        parameters: {'owner': ownerId, 'name': name, 'address': location, 'nozzles': totalNozzles},
      );
      final stationId = inserted.first[0] as int;
      await _audit(tx, userId: ownerId, action: 'INSERT', table: 'stations', recordId: stationId,
          newValue: {'name': name, 'address': location, 'nozzles': totalNozzles, 'capacities': capacities});
      final grades = await tx.execute('''
        SELECT fp.product_id, fp.name FROM fuel_products fp
        WHERE fp.name IN ('Petrol', 'Diesel', 'Hi-Octane') ORDER BY $_gradeOrder''');
      var pumpNumber = 0;
      int? pumpId;
      for (final grade in grades) {
        final productId = grade[0] as int;
        final gradeName = grade[1] as String;
        final capacity = capacities[gradeName] ?? 0;
        if (capacity <= 0) continue;
        final tank = await tx.execute(
          Sql.named('''
            INSERT INTO tanks (station_id, product_id, capacity_liters, low_stock_threshold, current_volume)
            VALUES (@station, @product, @capacity, @threshold, 0) RETURNING tank_id'''),
          parameters: {
            'station': stationId,
            'product': productId,
            'capacity': capacity,
            'threshold': capacity * defaultThresholdFraction,
          },
        );
        final tankId = tank.first[0] as int;
        final count = nozzleCounts[gradeName] ?? 0;
        for (var i = 0; i < count; i++) {
          if (i.isEven) {
            pumpNumber++;
            final pump = await tx.execute(
              Sql.named('INSERT INTO pumps (station_id, pump_number) VALUES (@station, @number) RETURNING pump_id'),
              parameters: {'station': stationId, 'number': pumpNumber},
            );
            pumpId = pump.first[0] as int;
          }
          await tx.execute(
            Sql.named('INSERT INTO nozzles (pump_id, tank_id, nozzle_number) VALUES (@pump, @tank, @number)'),
            parameters: {'pump': pumpId, 'tank': tankId, 'number': i.isEven ? 1 : 2},
          );
        }
      }
      return stationId;
    });
    return (await station(ownerId, stationId))!;
  }

  /// Renames a station and/or changes its location (the address column).
  /// Editing the location never touches the name. Returns null when the
  /// station isn't the owner's.
  Future<Map<String, Object?>?> updateStation({
    required int ownerId,
    required int stationId,
    String? name,
    String? location,
  }) async {
    final updated = await _db.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named('''
          UPDATE stations
          SET name = COALESCE(@name, name), address = COALESCE(@address, address)
          WHERE id = @station AND owner_id = @owner
          RETURNING id'''),
        parameters: {'name': name, 'address': location, 'station': stationId, 'owner': ownerId},
      );
      if (rows.isEmpty) return false;
      await _audit(tx, userId: ownerId, action: 'UPDATE', table: 'stations', recordId: stationId, newValue: {
        if (name != null) 'name': name,
        if (location != null) 'address': location,
      });
      return true;
    });
    return updated ? station(ownerId, stationId) : null;
  }

  // ---- Sales --------------------------------------------------------------

  /// Litres sold per grade in each of [period]'s buckets, oldest first
  /// (voided sales left out). A bucket with no sales is a row of zeros, so a
  /// chart always gets every day/week/month. Revenue isn't sent: the app
  /// derives it from litres.
  Future<List<Map<String, Object?>>> sales(int stationId, String period) async {
    final buckets = _salesBuckets[period];
    if (buckets == null) throw ApiError(422, 'Unknown period "$period". Use one of: ${salesPeriods.join(', ')}.');
    final rows = await _db.execute(
      Sql.named('''
        WITH buckets AS ($buckets)
        SELECT b.label,
               COALESCE(SUM(s.liters) FILTER (WHERE fp.name = 'Petrol'), 0)::float8 AS petrol,
               COALESCE(SUM(s.liters) FILTER (WHERE fp.name = 'Diesel'), 0)::float8 AS diesel,
               COALESCE(SUM(s.liters) FILTER (WHERE fp.name = 'Hi-Octane'), 0)::float8 AS octane
        FROM buckets b
        LEFT JOIN sales s
               ON s.station_id = @station AND s.status = 'completed'
              AND s.sale_time >= b.start_at AND s.sale_time < b.end_at
        LEFT JOIN nozzles n ON n.nozzle_id = s.nozzle_id
        LEFT JOIN tanks t ON t.tank_id = n.tank_id
        LEFT JOIN fuel_products fp ON fp.product_id = t.product_id
        GROUP BY b.n, b.label
        ORDER BY b.n'''),
      parameters: {'station': stationId},
    );
    return [
      for (final row in rows) {'label': row[0], 'petrolL': row[1], 'dieselL': row[2], 'octaneL': row[3]},
    ];
  }

  // ---- Tanks --------------------------------------------------------------

  Future<List<Map<String, Object?>>> tanks(int stationId) async {
    final rows = await _db.execute(
      Sql.named('$_tankSelect WHERE t.station_id = @station ORDER BY $_gradeOrder, t.tank_id'),
      parameters: {'station': stationId},
    );
    return [for (final row in rows) _tankJson(row.toColumnMap())];
  }

  /// One tank, only if it belongs to one of the owner's stations.
  Future<Map<String, Object?>?> ownedTank(int ownerId, int tankId) async {
    final rows = await _db.execute(
      Sql.named('''
        $_tankSelect
        JOIN stations st ON st.id = t.station_id
        WHERE t.tank_id = @tank AND st.owner_id = @owner'''),
      parameters: {'tank': tankId, 'owner': ownerId},
    );
    return rows.isEmpty ? null : _tankJson(rows.first.toColumnMap());
  }

  /// Sets a tank's reorder threshold, noting the old and new values in the
  /// audit log. The caller has already checked the tank is the owner's and
  /// the value fits its capacity; the table's CHECK constraint guards the
  /// capacity rule again.
  Future<void> setThreshold({
    required int ownerId,
    required int tankId,
    required double litres,
    required double previous,
  }) {
    return _db.runTx((tx) async {
      await tx.execute(
        Sql.named('UPDATE tanks SET low_stock_threshold = @liters WHERE tank_id = @tank'),
        parameters: {'liters': litres, 'tank': tankId},
      );
      await _audit(tx, userId: ownerId, action: 'UPDATE', table: 'tanks', recordId: tankId,
          oldValue: {'low_stock_threshold': previous}, newValue: {'low_stock_threshold': litres});
    });
  }

  // ---- Nozzles ------------------------------------------------------------

  /// The station's nozzles as stored, with each one's latest completed
  /// sale. Live readings from Redis are laid over these by the API.
  Future<List<Map<String, Object?>>> nozzles(int stationId) async {
    final rows = await _db.execute(
      Sql.named('''
        SELECT n.nozzle_id, p.pump_number, n.nozzle_number, fp.name AS fuel_name, n.status,
               (n.status_updated_at $_absolute) AS status_at,
               COALESCE(last_sale.liters, 0)::float8 AS liters,
               (last_sale.sale_time $_absolute) AS sold_at
        FROM nozzles n
        JOIN pumps p ON p.pump_id = n.pump_id
        JOIN tanks t ON t.tank_id = n.tank_id
        JOIN fuel_products fp ON fp.product_id = t.product_id
        LEFT JOIN LATERAL (
          SELECT s.liters, s.sale_time FROM sales s
          WHERE s.nozzle_id = n.nozzle_id AND s.status = 'completed'
          ORDER BY s.sale_time DESC LIMIT 1
        ) AS last_sale ON true
        WHERE p.station_id = @station
        ORDER BY p.pump_number, n.nozzle_number'''),
      parameters: {'station': stationId},
    );
    return [
      for (final row in rows)
        () {
          final m = row.toColumnMap();
          final statusAt = m['status_at'] as DateTime;
          final soldAt = m['sold_at'] as DateTime?;
          final lastUpdated = soldAt != null && soldAt.isAfter(statusAt) ? soldAt : statusAt;
          return <String, Object?>{
            'id': '${m['nozzle_id']}',
            'pumpNumber': m['pump_number'],
            'nozzleNumber': m['nozzle_number'],
            'fuelName': m['fuel_name'],
            'litres': m['liters'],
            'flowRate': 0.0,
            'lastUpdated': _iso(lastUpdated),
            'status': m['status'],
          };
        }(),
    ];
  }

  Future<bool> ownsNozzle(int ownerId, int nozzleId) async {
    final rows = await _db.execute(
      Sql.named('''
        SELECT 1 FROM nozzles n
        JOIN pumps p ON p.pump_id = n.pump_id
        JOIN stations st ON st.id = p.station_id
        WHERE n.nozzle_id = @nozzle AND st.owner_id = @owner'''),
      parameters: {'nozzle': nozzleId, 'owner': ownerId},
    );
    return rows.isNotEmpty;
  }

  /// Records a status change (not every reading: those stay in Redis).
  Future<void> setNozzleStatus(int nozzleId, String status) => _db.execute(
        Sql.named('''
          UPDATE nozzles SET status = @status, status_updated_at = localtimestamp
          WHERE nozzle_id = @nozzle AND status <> @status'''),
        parameters: {'status': status, 'nozzle': nozzleId},
      );

  // ---- Purchase orders ----------------------------------------------------

  /// The station's purchase orders, newest first (cancelled ones hidden).
  Future<List<Map<String, Object?>>> purchaseOrders(int stationId) async {
    final rows = await _db.execute(
      Sql.named('''
        SELECT po.po_number, (po.ordered_at $_absolute) AS ordered_at, fp.name AS fuel_name,
               po.tank_id, po.liters_ordered::float8 AS liters, po.vehicle, po.status
        FROM purchase_orders po
        JOIN tanks t ON t.tank_id = po.tank_id
        JOIN fuel_products fp ON fp.product_id = t.product_id
        WHERE po.station_id = @station AND po.status <> 'cancelled'
        ORDER BY po.ordered_at DESC, po.purchase_order_id DESC'''),
      parameters: {'station': stationId},
    );
    return [for (final row in rows) _orderJson(row.toColumnMap())];
  }

  /// Places a reorder for one of the station's tanks. The tank row is
  /// locked first, so two orders placed at once can't both fit into the same
  /// room. Rejects an order bigger than the tank's room: its space left
  /// minus litres already on order (the same rule and messages as the app's
  /// Create Reorder). The PO number comes from the table's default:
  /// `PO-<year>-<sequence>`.
  Future<Map<String, Object?>> placeOrder({
    required int ownerId,
    required int stationId,
    required int tankId,
    required double litres,
    required String vehicle,
  }) {
    return _db.runTx((tx) async {
      final locked = await tx.execute(
        Sql.named('''
          SELECT t.tank_id FROM tanks t
          JOIN stations st ON st.id = t.station_id
          WHERE t.tank_id = @tank AND t.station_id = @station AND st.owner_id = @owner
          FOR UPDATE OF t'''),
        parameters: {'tank': tankId, 'station': stationId, 'owner': ownerId},
      );
      if (locked.isEmpty) throw const ApiError(404, 'Tank not found.');

      final tank = (await tx.execute(
        Sql.named('$_tankSelect WHERE t.tank_id = @tank'),
        parameters: {'tank': tankId},
      ))
          .first
          .toColumnMap();
      final space = (tank['capacity'] as double) - (tank['current_volume'] as double);
      final pending = tank['pending_liters'] as double;
      final room = space - pending;
      if (space < 1) throw const ApiError(422, 'Tank is full.');
      if (room < 1) throw const ApiError(422, 'Already fully on order.');
      if (litres > room) {
        final onOrder = pending > 0 ? ' (${formatThousands(pending)} L already on order)' : '';
        throw ApiError(422, 'Only ${formatThousands(room)} L of space left$onOrder.');
      }

      final inserted = await tx.execute(
        Sql.named('''
          INSERT INTO purchase_orders (station_id, tank_id, liters_ordered, vehicle, ordered_by)
          VALUES (@station, @tank, @liters, @vehicle, @owner)
          RETURNING purchase_order_id, po_number, (ordered_at $_absolute) AS ordered_at, tank_id,
                    liters_ordered::float8 AS liters, vehicle, status'''),
        parameters: {'station': stationId, 'tank': tankId, 'liters': litres, 'vehicle': vehicle, 'owner': ownerId},
      );
      final order = inserted.first.toColumnMap();
      await _audit(tx, userId: ownerId, action: 'INSERT', table: 'purchase_orders',
          recordId: order['purchase_order_id'] as int,
          newValue: {'po_number': order['po_number'], 'tank_id': tankId, 'liters_ordered': litres, 'status': 'pending'});
      return _orderJson({...order, 'fuel_name': tank['fuel_name']});
    });
  }

  // ---- Vehicle log (vehicle_transactions) ---------------------------------

  /// Today's vehicle log entries, newest first.
  Future<List<Map<String, Object?>>> vehicleLogs(int stationId) async {
    final rows = await _db.execute(
      Sql.named('''
        SELECT vt.id, vt.vehicle_type, vt.fuel_type, vt.liters::float8 AS liters, vt.status,
               (vt.created_at $_absolute) AS logged_at, vt.nozzle_id, vt.plate_number
        FROM vehicle_transactions vt
        WHERE vt.station_id = @station AND vt.created_at >= date_trunc('day', localtimestamp)
        ORDER BY vt.created_at DESC, vt.id DESC'''),
      parameters: {'station': stationId},
    );
    return [
      for (final row in rows)
        () {
          final m = row.toColumnMap();
          final loggedAt = m['logged_at'] as DateTime?;
          return <String, Object?>{
            'id': '${m['id']}',
            'vehicle': m['vehicle_type'],
            'fuelType': m['fuel_type'],
            'litres': m['liters'],
            'status': m['status'],
            'loggedAt': loggedAt == null ? null : _iso(loggedAt),
            'nozzleId': m['nozzle_id'] == null ? null : '${m['nozzle_id']}',
            'plateNumber': m['plate_number'],
          };
        }(),
    ];
  }

  // ---- Staff (employees) ----------------------------------------------------

  /// The owner's current staff (terminated people hidden), oldest first.
  Future<List<Map<String, Object?>>> staff(int ownerId) async {
    final rows = await _db.execute(
      Sql.named('''
        SELECT employee_id, full_name, position, phone, status FROM employees
        WHERE owner_id = @owner AND status <> 'terminated' ORDER BY employee_id'''),
      parameters: {'owner': ownerId},
    );
    return [for (final row in rows) _staffJson(row.toColumnMap())];
  }

  /// Adds a staff member, or returns null when another employee already
  /// has that CNIC (employees.cnic is unique).
  Future<Map<String, Object?>?> addStaff({
    required int ownerId,
    required String name,
    required String role,
    required String phone,
    String? cnic,
    String? email,
  }) {
    return _db.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named('''
          INSERT INTO employees (owner_id, full_name, position, phone, cnic, email)
          VALUES (@owner, @name, @position, @phone, @cnic, @email)
          ON CONFLICT (cnic) DO NOTHING
          RETURNING employee_id, full_name, position, phone, status'''),
        parameters: {'owner': ownerId, 'name': name, 'position': role, 'phone': phone, 'cnic': cnic, 'email': email},
      );
      if (rows.isEmpty) return null;
      final member = rows.first.toColumnMap();
      await _audit(tx, userId: ownerId, action: 'INSERT', table: 'employees',
          recordId: member['employee_id'] as int, newValue: {'full_name': name, 'position': role});
      return _staffJson(member);
    });
  }

  // ---- Audit log ------------------------------------------------------------

  /// Records who changed what in audit_log, in the same transaction as the
  /// change itself, so the log never shows a change that didn't happen.
  static Future<void> _audit(
    Session db, {
    required int userId,
    required String action,
    required String table,
    required int recordId,
    Map<String, Object?>? oldValue,
    Map<String, Object?>? newValue,
  }) async {
    await db.execute(
      Sql.named('''
        INSERT INTO audit_log (user_id, action, table_name, record_id, old_value, new_value, action_time)
        VALUES (@user, @action, @table, @record, CAST(@old AS jsonb), CAST(@new AS jsonb), localtimestamp)'''),
      parameters: {
        'user': userId,
        'action': action,
        'table': table,
        'record': recordId,
        'old': oldValue == null ? null : jsonEncode(oldValue),
        'new': newValue == null ? null : jsonEncode(newValue),
      },
    );
  }

  // ---- JSON shapes ----------------------------------------------------------

  Future<Map<String, Object?>> _stationJson(Map<String, dynamic> s) async {
    final id = s['id'] as int;
    return {
      'id': '$id',
      'name': s['name'],
      'location': s['address'] ?? '',
      'status': s['status'],
      'tanks': await tanks(id),
      'nozzles': await nozzles(id),
    };
  }

  static Map<String, Object?> _ownerJson(Map<String, dynamic> m) =>
      {'id': '${m['user_id']}', 'name': m['full_name'], 'email': m['email']};

  static Map<String, Object?> _tankJson(Map<String, dynamic> m) => {
        'id': '${m['tank_id']}',
        'stationId': '${m['station_id']}',
        'fuelName': m['fuel_name'],
        'capacity': m['capacity'],
        'threshold': m['threshold'],
        'currentVolume': m['current_volume'],
        'pendingLitres': m['pending_liters'],
      };

  static Map<String, Object?> _orderJson(Map<String, dynamic> m) => {
        'poNumber': m['po_number'],
        'date': _iso(m['ordered_at'] as DateTime),
        'fuelName': m['fuel_name'],
        'tankId': '${m['tank_id']}',
        'litres': m['liters'],
        'vehicle': m['vehicle'],
        'status': m['status'],
      };

  static Map<String, Object?> _staffJson(Map<String, dynamic> m) => {
        'id': '${m['employee_id']}',
        'name': m['full_name'],
        'role': m['position'],
        'phone': m['phone'] ?? '',
        'status': m['status'],
      };

  static String _iso(DateTime time) => time.toUtc().toIso8601String();
}
