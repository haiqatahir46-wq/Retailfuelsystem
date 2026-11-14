import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'cache.dart';
import 'http_utils.dart';
import 'store.dart';

/// The HTTP API. PostgreSQL (through [Store]) holds every business record;
/// Redis (through [Cache]) holds what is fast and short-lived:
///
/// - `session:<token>`: the signed-in owner's id for each login, expiring
///   after [sessionTtl]. Logout deletes it.
/// - `login-fail:<email>`: failed sign-ins; after [maxLoginFailures] the
///   email is locked out for [loginLockout].
/// - `sales:<station>:<period>`: a sales report, cached for [salesCacheTtl]
///   because the sums scan a year of rows and every tab reads them.
/// - `nozzle-live:<id>`: a pump's latest reading (status, litres, flow
///   rate), written by `PUT /nozzles/<id>/live` and laid over the stored
///   nozzle for [liveNozzleTtl]; a pump that stops reporting falls back to
///   its last stored status.
class Api {
  Api(this._store, this._cache);

  final Store _store;
  final Cache _cache;

  static const sessionTtl = Duration(days: 7);
  static const salesCacheTtl = Duration(seconds: 60);
  static const liveNozzleTtl = Duration(minutes: 5);
  static const maxLoginFailures = 5;
  static const loginLockout = Duration(minutes: 15);

  Handler get handler {
    final signedIn = Router()
      ..post('/auth/logout', _logout)
      ..get('/me', _me)
      ..get('/stations', _stations)
      ..post('/stations', _createStation)
      ..patch('/stations/<id>', _updateStation)
      ..get('/stations/<id>/sales', _sales)
      ..get('/stations/<id>/tanks', _tanks)
      ..put('/tanks/<id>/threshold', _setThreshold)
      ..get('/stations/<id>/nozzles', _nozzles)
      ..put('/nozzles/<id>/live', _setNozzleLive)
      ..get('/stations/<id>/purchase-orders', _purchaseOrders)
      ..post('/stations/<id>/purchase-orders', _placeOrder)
      ..get('/stations/<id>/vehicle-logs', _vehicleLogs)
      ..get('/staff', _staff)
      ..post('/staff', _addStaff);

    // Anything that isn't one of the open routes below needs a session.
    final requiresSignIn = const Pipeline().addMiddleware(_requireSession).addHandler(signedIn.call);
    final open = Router(notFoundHandler: requiresSignIn)
      ..get('/health', _health)
      ..post('/auth/signup', _signUp)
      ..post('/auth/login', _login);
    return open.call;
  }

  // ---- Sessions -------------------------------------------------------------

  static String _sessionKey(String token) => 'session:$token';

  /// Reads the bearer token, looks it up in Redis and passes the owner's id
  /// on to the route in the request context.
  Middleware get _requireSession => (inner) => (request) async {
        final header = request.headers['authorization'] ?? '';
        const prefix = 'Bearer ';
        final token = header.startsWith(prefix) ? header.substring(prefix.length).trim() : '';
        if (token.isEmpty) throw const ApiError(401, 'Please sign in.');
        final ownerId = int.tryParse(await _cache.get(_sessionKey(token)) ?? '');
        if (ownerId == null) throw const ApiError(401, 'Your session has expired. Please sign in again.');
        return inner(request.change(context: {'ownerId': ownerId, 'token': token}));
      };

  static int _ownerId(Request request) => request.context['ownerId']! as int;

  /// 64 hex characters from a secure random source: unguessable, and it
  /// carries no information about the owner.
  static String _newToken() {
    final random = Random.secure();
    return [for (var i = 0; i < 32; i++) random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  }

  Future<Map<String, Object?>> _startSession(Map<String, Object?> owner) async {
    final token = _newToken();
    await _cache.setFor(_sessionKey(token), '${owner['id']}', sessionTtl);
    return {'token': token, 'owner': owner};
  }

  /// 404, not 403, for a station that isn't the owner's: whether some other
  /// owner's station exists with that id is none of their business.
  Future<int> _ownedStation(Request request, String rawId) async {
    final stationId = parseId(rawId);
    if (!await _store.ownsStation(_ownerId(request), stationId)) {
      throw const ApiError(404, 'Station not found.');
    }
    return stationId;
  }

  // ---- Open routes ----------------------------------------------------------

  /// Whether both stores answer. 503 when either doesn't, so a monitor can
  /// tell; the reply says which without exposing connection details.
  Future<Response> _health(Request request) async {
    Future<String> check(Future<void> Function() probe) async {
      try {
        await probe();
        return 'ok';
      } catch (_) {
        return 'unreachable';
      }
    }

    final postgres = await check(_store.ping);
    final redis = await check(_cache.ping);
    final healthy = postgres == 'ok' && redis == 'ok';
    return jsonResponse({'postgres': postgres, 'redis': redis}, status: healthy ? 200 : 503);
  }

  Future<Response> _signUp(Request request) async {
    final body = await readJson(request);
    final email = requireString(body, 'email', maxLength: 254);
    if (!isValidEmail(email)) throw const ApiError(422, 'Enter a valid email address.');
    final password = requireString(body, 'password', maxLength: 200, trim: false);
    if (password.length < 6) throw const ApiError(422, 'Password must be at least 6 characters.');
    final typedName = optionalString(body, 'name', maxLength: 100) ?? '';
    final emailName = email.split('@').first;
    final owner = await _store.signUp(
      name: typedName.isEmpty ? emailName.substring(0, min(emailName.length, 100)) : typedName,
      email: email,
      password: password,
      stationName: requireString(body, 'stationName', maxLength: 100),
      stationCount: requireInt(body, 'stationCount', min: 1, max: maxSignupStations),
    );
    if (owner == null) throw const ApiError(409, 'An account with this email already exists.');
    return jsonResponse(await _startSession(owner), status: 201);
  }

  Future<Response> _login(Request request) async {
    final body = await readJson(request);
    final email = requireString(body, 'email', maxLength: 254);
    final password = requireString(body, 'password', maxLength: 200, trim: false);
    final failuresKey = 'login-fail:${email.toLowerCase()}';
    final failures = int.tryParse(await _cache.get(failuresKey) ?? '') ?? 0;
    if (failures >= maxLoginFailures) {
      throw ApiError(429, 'Too many wrong passwords. Try again in ${loginLockout.inMinutes} minutes.');
    }
    final account = await _store.verifyLogin(email, password);
    if (account == null) {
      await _cache.increment(failuresKey, loginLockout);
      throw const ApiError(401, 'Wrong email or password.');
    }
    await _cache.delete(failuresKey);
    // Staff accounts (manager, cashier, ...) share the users table but have
    // no stations of their own; the app is for owners until roles land.
    if (account['role'] != 'owner') {
      throw const ApiError(403, 'This app is for station owners. Staff sign-in is coming later.');
    }
    final owner = {...account}..remove('role');
    return jsonResponse(await _startSession(owner));
  }

  // ---- Signed-in routes -------------------------------------------------------

  Future<Response> _logout(Request request) async {
    await _cache.delete(_sessionKey(request.context['token']! as String));
    return Response(204);
  }

  Future<Response> _me(Request request) async {
    final owner = await _store.owner(_ownerId(request));
    if (owner == null) throw const ApiError(401, 'Please sign in.');
    return jsonResponse(owner);
  }

  Future<Response> _stations(Request request) async {
    final stations = await _store.stations(_ownerId(request));
    for (final station in stations) {
      station['nozzles'] = await _withLiveReadings(station['nozzles']! as List<Map<String, Object?>>);
    }
    return jsonResponse(stations);
  }

  Future<Response> _createStation(Request request) async {
    final body = await readJson(request);
    final nozzleCounts = _gradeMap(body, 'nozzleCounts');
    final capacities = _gradeMap(body, 'capacities');
    final counts = {
      for (final grade in kFuelGrades)
        grade: requireInt(nozzleCounts, grade, min: 0, max: maxNozzlesPerGrade),
    };
    if (counts.values.every((count) => count == 0)) {
      throw const ApiError(422, 'Add at least one nozzle.');
    }
    final tankSizes = {
      for (final grade in kFuelGrades)
        grade: requireNumber(capacities, grade, min: 0, max: maxCapacityLitres),
    };
    // Every nozzle draws from a tank (nozzles.tank_id is required).
    for (final grade in kFuelGrades) {
      if (counts[grade]! > 0 && tankSizes[grade]! <= 0) {
        throw ApiError(422, 'Give $grade a tank capacity, since it has nozzles.');
      }
    }
    final station = await _store.createStation(
      ownerId: _ownerId(request),
      name: requireString(body, 'name', maxLength: 100),
      location: optionalString(body, 'location', maxLength: 255) ?? '',
      nozzleCounts: counts,
      capacities: tankSizes,
    );
    return jsonResponse(station, status: 201);
  }

  /// `{"Petrol": .., "Diesel": .., "Hi-Octane": ..}` under [key]; a grade
  /// left out counts as 0.
  static Map<String, dynamic> _gradeMap(Map<String, dynamic> body, String key) {
    final value = body[key] ?? const <String, dynamic>{};
    if (value is! Map<String, dynamic>) throw ApiError(422, '"$key" must be an object keyed by fuel grade.');
    return {for (final grade in kFuelGrades) grade: value[grade] ?? 0};
  }

  Future<Response> _updateStation(Request request, String id) async {
    final body = await readJson(request);
    final name = optionalString(body, 'name', maxLength: 100);
    if (name != null && name.isEmpty) throw const ApiError(422, '"name" can\'t be empty.');
    final location = optionalString(body, 'location', maxLength: 255);
    if (name == null && location == null) throw const ApiError(422, 'Send a new "name" or "location".');
    final station = await _store.updateStation(
      ownerId: _ownerId(request),
      stationId: parseId(id),
      name: name,
      location: location,
    );
    if (station == null) throw const ApiError(404, 'Station not found.');
    return jsonResponse(station);
  }

  Future<Response> _sales(Request request, String id) async {
    final stationId = await _ownedStation(request, id);
    final period = request.url.queryParameters['period'] ?? 'today';
    if (!salesPeriods.contains(period)) {
      throw ApiError(422, 'Unknown period "$period". Use one of: ${salesPeriods.join(', ')}.');
    }
    final key = 'sales:$stationId:$period';
    final cached = await _cache.get(key);
    if (cached != null) return rawJsonResponse(cached);
    final body = jsonEncode(await _store.sales(stationId, period));
    await _cache.setFor(key, body, salesCacheTtl);
    return rawJsonResponse(body);
  }

  Future<Response> _tanks(Request request, String id) async {
    final stationId = await _ownedStation(request, id);
    return jsonResponse(await _store.tanks(stationId));
  }

  Future<Response> _setThreshold(Request request, String id) async {
    final tank = await _store.ownedTank(_ownerId(request), parseId(id));
    if (tank == null) throw const ApiError(404, 'Tank not found.');
    final capacity = tank['capacity']! as double;
    final body = await readJson(request);
    final litres = requireNumber(body, 'litres', min: 1, max: maxCapacityLitres);
    if (litres > capacity) {
      throw ApiError(422, "Can't be more than the tank holds (${formatThousands(capacity)} L).");
    }
    await _store.setThreshold(
      ownerId: _ownerId(request),
      tankId: parseId(id),
      litres: litres,
      previous: tank['threshold']! as double,
    );
    return jsonResponse(await _store.ownedTank(_ownerId(request), parseId(id)));
  }

  Future<Response> _nozzles(Request request, String id) async {
    final stationId = await _ownedStation(request, id);
    return jsonResponse(await _withLiveReadings(await _store.nozzles(stationId)));
  }

  /// A pump (or the pump simulator) reporting one nozzle's reading. The
  /// reading goes to Redis only; PostgreSQL records just a status change.
  Future<Response> _setNozzleLive(Request request, String id) async {
    final nozzleId = parseId(id);
    if (!await _store.ownsNozzle(_ownerId(request), nozzleId)) throw const ApiError(404, 'Nozzle not found.');
    final body = await readJson(request);
    final status = requireString(body, 'status', maxLength: 20);
    if (!const ['dispensing', 'idle', 'fault'].contains(status)) {
      throw const ApiError(422, '"status" must be dispensing, idle or fault.');
    }
    final litres = requireNumber(body, 'litres', min: 0, max: 100000);
    final flowRate = requireNumber(body, 'flowRate', min: 0, max: 1000);
    await _cache.setHash(
      'nozzle-live:$nozzleId',
      {
        'status': status,
        'litres': '$litres',
        'flowRate': '$flowRate',
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      liveNozzleTtl,
    );
    await _store.setNozzleStatus(nozzleId, status);
    return Response(204);
  }

  /// Lays each nozzle's live Redis reading, if one is fresh, over its
  /// stored row. The lookups run concurrently over the one Redis connection.
  Future<List<Map<String, Object?>>> _withLiveReadings(List<Map<String, Object?>> nozzles) async {
    final live = await Future.wait([for (final n in nozzles) _cache.getHash('nozzle-live:${n['id']}')]);
    return [
      for (var i = 0; i < nozzles.length; i++)
        if (live[i].isEmpty)
          nozzles[i]
        else
          {
            ...nozzles[i],
            'status': live[i]['status'] ?? nozzles[i]['status'],
            'litres': double.tryParse(live[i]['litres'] ?? '') ?? nozzles[i]['litres'],
            'flowRate': double.tryParse(live[i]['flowRate'] ?? '') ?? 0.0,
            'lastUpdated': live[i]['updatedAt'] ?? nozzles[i]['lastUpdated'],
          },
    ];
  }

  Future<Response> _purchaseOrders(Request request, String id) async {
    final stationId = await _ownedStation(request, id);
    return jsonResponse(await _store.purchaseOrders(stationId));
  }

  Future<Response> _placeOrder(Request request, String id) async {
    final stationId = await _ownedStation(request, id);
    final body = await readJson(request);
    final vehicle = optionalString(body, 'vehicle', maxLength: 20) ?? 'carriage';
    if (!const ['self', 'carriage'].contains(vehicle)) {
      throw const ApiError(422, '"vehicle" must be self or carriage.');
    }
    final order = await _store.placeOrder(
      ownerId: _ownerId(request),
      stationId: stationId,
      tankId: parseId(body['tankId']),
      litres: requireNumber(body, 'litres', min: 1, max: maxCapacityLitres),
      vehicle: vehicle,
    );
    return jsonResponse(order, status: 201);
  }

  Future<Response> _vehicleLogs(Request request, String id) async {
    final stationId = await _ownedStation(request, id);
    return jsonResponse(await _store.vehicleLogs(stationId));
  }

  Future<Response> _staff(Request request) async => jsonResponse(await _store.staff(_ownerId(request)));

  Future<Response> _addStaff(Request request) async {
    final body = await readJson(request);
    final email = optionalString(body, 'email', maxLength: 254);
    if (email != null && email.isNotEmpty && !isValidEmail(email)) {
      throw const ApiError(422, 'Enter a valid email address.');
    }
    final role = optionalString(body, 'role', maxLength: 50) ?? '';
    final cnic = optionalString(body, 'cnic', maxLength: 20) ?? '';
    final member = await _store.addStaff(
      ownerId: _ownerId(request),
      name: requireString(body, 'name', maxLength: 100),
      role: role.isEmpty ? 'Attendant' : role,
      phone: requireString(body, 'phone', maxLength: 20),
      cnic: cnic.isEmpty ? null : cnic,
      email: email == null || email.isEmpty ? null : email,
    );
    if (member == null) throw const ApiError(409, 'A staff member with this CNIC is already registered.');
    return jsonResponse(member, status: 201);
  }
}
