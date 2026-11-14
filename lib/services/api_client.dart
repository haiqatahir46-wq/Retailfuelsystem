import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/delivery_vehicle.dart';
import '../models/log_entry.dart';
import '../models/nozzle.dart';
import '../models/owner.dart';
import '../models/sales.dart';
import '../models/staff.dart';
import '../models/station.dart';
import '../models/tank_stock.dart';

/// Where the API server (the server/ folder) listens. Override it with
/// `--dart-define=API_BASE_URL=http://192.168.1.20:8080`, e.g. for a real
/// phone on the same Wi-Fi as the PC running the server.
const kApiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

/// The server on this PC: the Android emulator reaches the PC's localhost
/// at 10.0.2.2; web, Windows and the iOS simulator use localhost itself.
String defaultApiBaseUrl() {
  if (kApiBaseUrlOverride.isNotEmpty) return kApiBaseUrlOverride;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

/// A request that failed. [message] is always safe to show the user: the
/// server's own error sentence when it sent one, otherwise a fixed one.
class ApiException implements Exception {
  final String message;

  /// The HTTP status, or null when the server couldn't be reached at all.
  final int? status;

  const ApiException(this.message, {this.status});

  @override
  String toString() => message;
}

/// One station as the server sends it, with its tanks' current levels.
class ApiStation {
  final Station station;
  final List<TankStock> tanks;

  /// Litres already on order per tank id.
  final Map<String, double> pendingLitres;

  const ApiStation({required this.station, required this.tanks, required this.pendingLitres});
}

/// A station's tanks plus what each has on order.
class ApiTanks {
  final List<TankStock> tanks;
  final Map<String, double> pendingLitres;

  const ApiTanks(this.tanks, this.pendingLitres);
}

/// Talks to the PARCO Fuel System API over HTTP and turns its JSON into the
/// app's models. Holds the signed-in owner's token (sent as a bearer token
/// with every request) for as long as the app runs.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, this.timeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? defaultApiBaseUrl();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;
  String? _token;

  bool get isSignedIn => _token != null;

  // ---- Account ----------------------------------------------------------------

  Future<Owner> login({required String email, required String password}) async {
    final body = await _send('POST', '/auth/login', body: {'email': email, 'password': password});
    return _startSession(body);
  }

  Future<Owner> signUp({
    required String email,
    required String password,
    required String stationName,
    required int stationCount,
  }) async {
    final body = await _send('POST', '/auth/signup', body: {
      'email': email,
      'password': password,
      'stationName': stationName,
      'stationCount': stationCount,
    });
    return _startSession(body);
  }

  Owner _startSession(Object? body) {
    final json = _map(body);
    final token = json['token'];
    if (token is! String || token.isEmpty) throw const ApiException(_unexpected);
    _token = token;
    return _owner(json['owner']);
  }

  /// Ends the session on the server (best effort: a network failure here
  /// mustn't stop the app signing out) and forgets the token.
  Future<void> logout() async {
    if (_token == null) return;
    try {
      await _send('POST', '/auth/logout');
    } on ApiException {
      // The server forgets unused sessions after a week anyway.
    } finally {
      _token = null;
    }
  }

  // ---- Reads ----------------------------------------------------------------

  Future<List<ApiStation>> stations() async => _list(await _send('GET', '/stations')).map(_station).toList();

  Future<List<StaffMember>> staff() async => _list(await _send('GET', '/staff')).map(_staffMember).toList();

  Future<List<PeriodSales>> sales(String stationId, SalesReportPeriod period) async {
    final rows = _list(await _send('GET', '/stations/${_path(stationId)}/sales?period=${period.name}'));
    return [
      for (final row in rows.map(_map))
        PeriodSales(
          label: _string(row['label']),
          petrolL: _number(row['petrolL']),
          dieselL: _number(row['dieselL']),
          octaneL: _number(row['octaneL']),
        ),
    ];
  }

  Future<ApiTanks> tanks(String stationId) async =>
      _tanks(_list(await _send('GET', '/stations/${_path(stationId)}/tanks')));

  Future<List<Nozzle>> nozzles(String stationId) async =>
      _list(await _send('GET', '/stations/${_path(stationId)}/nozzles')).map(_nozzle).toList();

  Future<List<PurchaseOrder>> purchaseOrders(String stationId) async =>
      _list(await _send('GET', '/stations/${_path(stationId)}/purchase-orders')).map(_order).toList();

  Future<List<VehicleLogEntry>> vehicleLogs(String stationId) async =>
      _list(await _send('GET', '/stations/${_path(stationId)}/vehicle-logs')).map(_logEntry).toList();

  // ---- Changes --------------------------------------------------------------

  Future<ApiStation> addStation({
    required String name,
    required String location,
    required Map<String, int> nozzleCounts,
    required Map<String, double> capacities,
  }) async {
    return _station(await _send('POST', '/stations', body: {
      'name': name,
      'location': location,
      'nozzleCounts': nozzleCounts,
      'capacities': capacities,
    }));
  }

  Future<ApiStation> updateStationLocation(String stationId, String location) async =>
      _station(await _send('PATCH', '/stations/${_path(stationId)}', body: {'location': location}));

  Future<StaffMember> addStaff({required String name, required String role, required String phone}) async =>
      _staffMember(await _send('POST', '/staff', body: {'name': name, 'role': role, 'phone': phone}));

  Future<void> setThreshold(String tankId, double litres) async {
    await _send('PUT', '/tanks/${_path(tankId)}/threshold', body: {'litres': litres});
  }

  Future<PurchaseOrder> placeReorder({required String stationId, required String tankId, required double litres}) async =>
      _order(await _send('POST', '/stations/${_path(stationId)}/purchase-orders', body: {
        'tankId': tankId,
        'litres': litres,
      }));

  void close() => _client.close();

  // ---- HTTP -------------------------------------------------------------------

  static const _unreachable = "Can't reach the server. Check that it is running, then try again.";
  static const _tooSlow = 'The server took too long to answer. Try again.';
  static const _unexpected = 'The server sent an unexpected reply.';

  /// Sends one request and returns its decoded JSON body (null for 204).
  /// Every failure becomes an [ApiException] with a user-safe message.
  Future<Object?> _send(String method, String path, {Map<String, Object?>? body}) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    if (_token != null) request.headers['authorization'] = 'Bearer $_token';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request).timeout(timeout)).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(_tooSlow);
    } on ApiException {
      rethrow;
    } catch (_) {
      // http.ClientException, SocketException (native) and the like: the
      // server isn't running, or the address is wrong.
      throw const ApiException(_unreachable);
    }

    Object? decoded;
    if (response.bodyBytes.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw ApiException(_unexpected, status: response.statusCode);
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    // The server's errors are {"error": "<sentence safe to show>"}.
    final message = decoded is Map && decoded['error'] is String ? decoded['error'] as String : null;
    if (response.statusCode == 401 && _token != null && path != '/auth/login') {
      throw ApiException(message ?? 'Your session has expired. Please sign in again.', status: 401);
    }
    throw ApiException(message ?? 'Something went wrong on the server (HTTP ${response.statusCode}).',
        status: response.statusCode);
  }

  /// Ids go into URLs; the server's are numbers, but nothing typed should
  /// ever be able to change the path.
  static String _path(String id) => Uri.encodeComponent(id);

  // ---- JSON -> models -----------------------------------------------------------

  static Map<String, Object?> _map(Object? json) =>
      json is Map<String, Object?> ? json : throw const ApiException(_unexpected);

  static List<Object?> _list(Object? json) => json is List<Object?> ? json : throw const ApiException(_unexpected);

  static String _string(Object? value) => value is String ? value : throw const ApiException(_unexpected);

  static double _number(Object? value) => value is num ? value.toDouble() : throw const ApiException(_unexpected);

  static double? _numberOrNull(Object? value) => value == null ? null : _number(value);

  static DateTime _time(Object? value) {
    final parsed = DateTime.tryParse(_string(value));
    return parsed?.toLocal() ?? (throw const ApiException(_unexpected));
  }

  static Owner _owner(Object? json) {
    final m = _map(json);
    return Owner(name: _string(m['name']), email: _string(m['email']));
  }

  static ApiStation _station(Object? json) {
    final m = _map(json);
    final tanks = _tanks(_list(m['tanks']));
    final id = _string(m['id']);
    return ApiStation(
      station: Station(
        id: id,
        name: _string(m['name']),
        location: m['location'] is String ? m['location'] as String : '',
        status: m['status'] == 'pending' ? StationStatus.pending : StationStatus.active,
        tanks: [
          for (final t in tanks.tanks)
            TankConfig(id: t.id, fuelName: t.fuelName, capacity: t.capacity, threshold: t.threshold),
        ],
        nozzles: _list(m['nozzles']).map(_nozzle).toList(),
      ),
      tanks: tanks.tanks,
      pendingLitres: tanks.pendingLitres,
    );
  }

  static ApiTanks _tanks(List<Object?> rows) {
    final tanks = <TankStock>[];
    final pending = <String, double>{};
    for (final m in rows.map(_map)) {
      final id = _string(m['id']);
      tanks.add(TankStock(
        id: id,
        fuelName: _string(m['fuelName']),
        currentVolume: _number(m['currentVolume']),
        capacity: _number(m['capacity']),
        threshold: _number(m['threshold']),
      ));
      pending[id] = _number(m['pendingLitres']);
    }
    return ApiTanks(List.unmodifiable(tanks), Map.unmodifiable(pending));
  }

  static Nozzle _nozzle(Object? json) {
    final m = _map(json);
    return Nozzle(
      id: _string(m['id']),
      pumpNumber: _number(m['pumpNumber']).toInt(),
      nozzleNumber: _number(m['nozzleNumber']).toInt(),
      fuelName: _string(m['fuelName']),
      litres: _number(m['litres']),
      flowRate: _number(m['flowRate']),
      lastUpdated: _time(m['lastUpdated']),
      status: switch (m['status']) {
        'dispensing' => NozzleStatus.dispensing,
        'fault' => NozzleStatus.fault,
        _ => NozzleStatus.idle,
      },
    );
  }

  static PurchaseOrder _order(Object? json) {
    final m = _map(json);
    return PurchaseOrder(
      poNumber: _string(m['poNumber']),
      date: _time(m['date']),
      tankId: _string(m['tankId']),
      fuelName: _string(m['fuelName']),
      litres: _number(m['litres']),
      vehicle: m['vehicle'] == 'self' ? DeliveryVehicle.self : DeliveryVehicle.carriage,
      status: m['status'] == 'delivered' ? PurchaseOrderStatus.delivered : PurchaseOrderStatus.pending,
    );
  }

  static VehicleLogEntry _logEntry(Object? json) {
    final m = _map(json);
    return VehicleLogEntry(
      vehicle: m['vehicle'] == 'carriage' ? DeliveryVehicle.carriage : DeliveryVehicle.self,
      fuelType: _string(m['fuelType']),
      litres: _numberOrNull(m['litres']),
      status: m['status'] == 'completed' ? LogStatus.completed : LogStatus.pending,
    );
  }

  static StaffMember _staffMember(Object? json) {
    final m = _map(json);
    return StaffMember(
      id: _string(m['id']),
      name: _string(m['name']),
      role: _string(m['role']),
      phone: m['phone'] is String ? m['phone'] as String : '',
      status: m['status'] == 'on_leave' ? StaffStatus.onLeave : StaffStatus.active,
    );
  }
}
