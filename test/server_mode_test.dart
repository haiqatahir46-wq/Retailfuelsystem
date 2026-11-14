import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petrolpump_flutter/models/log_entry.dart';
import 'package:petrolpump_flutter/models/nozzle.dart';
import 'package:petrolpump_flutter/models/sales.dart';
import 'package:petrolpump_flutter/models/staff.dart';
import 'package:petrolpump_flutter/models/station.dart';
import 'package:petrolpump_flutter/models/tank_stock.dart';
import 'package:petrolpump_flutter/services/api_client.dart';
import 'package:petrolpump_flutter/state/app_session.dart';

/// A stand-in for the API server (server/): the same routes and JSON
/// shapes, with one owner, one station and a little state, so the client
/// and the session can be tested without the network.
class _FakeServer {
  final requests = <String>[];
  String? token;
  double threshold = 18000;
  double pending = 2000;
  var orders = <Map<String, Object?>>[
    {
      'poNumber': 'PO-2026-0001',
      'date': '2026-10-20T05:00:00.000Z',
      'fuelName': 'Petrol',
      'tankId': '7',
      'litres': 2000.0,
      'vehicle': 'carriage',
      'status': 'pending',
    },
  ];

  /// Set to make every station-data request fail, as a down server would.
  bool failStationData = false;

  Map<String, Object?> get _tank => {
        'id': '7',
        'stationId': '3',
        'fuelName': 'Petrol',
        'capacity': 25000.0,
        'threshold': threshold,
        'currentVolume': 7000.0,
        'pendingLitres': pending,
      };

  Map<String, Object?> get _nozzle => {
        'id': '21',
        'pumpNumber': 1,
        'nozzleNumber': 1,
        'fuelName': 'Petrol',
        'litres': 42.5,
        'flowRate': 38.0,
        'lastUpdated': '2026-10-24T03:00:00.000Z',
        'status': 'dispensing',
      };

  late final client = MockClient((request) async {
    final path = request.url.path;
    requests.add('${request.method} $path${request.url.hasQuery ? '?${request.url.query}' : ''}');
    http.Response json(Object? body, [int status = 200]) =>
        http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

    if (path == '/auth/login') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      if (body['password'] != 'demo1234') return json({'error': 'Wrong email or password.'}, 401);
      token = 'secret-token';
      return json({
        'token': token,
        'owner': {'id': '1', 'name': 'Demo Owner', 'email': body['email']},
      });
    }
    if (request.headers['authorization'] != 'Bearer $token') return json({'error': 'Please sign in.'}, 401);
    if (path == '/auth/logout') return http.Response('', 204);
    if (path == '/stations') {
      return json([
        {'id': '3', 'name': 'Amir Filling, Pattoki', 'location': 'Pattoki, Punjab', 'status': 'active', 'tanks': [_tank], 'nozzles': [_nozzle]},
      ]);
    }
    if (path == '/staff') {
      return json([
        {'id': '1', 'name': 'Bilal Ahmed', 'role': 'Manager', 'phone': '0300-1234567', 'status': 'active'},
        {'id': '3', 'name': 'Imran Shah', 'role': 'Cashier', 'phone': '0302-3456789', 'status': 'on_leave'},
      ]);
    }
    if (failStationData && path.startsWith('/stations/3/')) {
      return json({'error': 'Something went wrong on the server.'}, 500);
    }
    if (path == '/stations/3/tanks') return json([_tank]);
    if (path == '/stations/3/nozzles') return json([_nozzle]);
    if (path == '/stations/3/vehicle-logs') {
      return json([
        {'id': '9', 'vehicle': 'carriage', 'fuelType': 'Diesel', 'litres': null, 'status': 'pending'},
      ]);
    }
    if (path == '/stations/3/sales') {
      final period = request.url.queryParameters['period'];
      final rows = period == 'weekly' ? 7 : 1;
      return json([
        for (var i = 1; i <= rows; i++)
          {'label': period == 'today' ? 'Today' : 'Day $i', 'petrolL': 1000.0 * i, 'dieselL': 500.0, 'octaneL': 100.0},
      ]);
    }
    if (path == '/stations/3/purchase-orders' && request.method == 'GET') return json(orders);
    if (path == '/stations/3/purchase-orders' && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      final litres = (body['litres'] as num).toDouble();
      if (litres > 16000) return json({'error': 'Only 16,000 L of space left (2,000 L already on order).'}, 422);
      pending += litres;
      final order = {
        'poNumber': 'PO-2026-0002',
        'date': '2026-10-24T04:00:00.000Z',
        'fuelName': 'Petrol',
        'tankId': body['tankId'],
        'litres': litres,
        'vehicle': 'carriage',
        'status': 'pending',
      };
      orders = [order, ...orders];
      return json(order, 201);
    }
    if (path == '/tanks/7/threshold') {
      threshold = ((jsonDecode(request.body) as Map)['litres'] as num).toDouble();
      return json(_tank);
    }
    return json({'error': 'Not found.'}, 404);
  });

  ApiClient api() => ApiClient(client: client, baseUrl: 'http://api.test');
}

void main() {
  group('ApiClient', () {
    test('login keeps the token and sends it with every later request', () async {
      final server = _FakeServer();
      final api = server.api();
      final owner = await api.login(email: 'owner@parco.example', password: 'demo1234');
      expect(owner.name, 'Demo Owner');
      expect(owner.email, 'owner@parco.example');
      expect(api.isSignedIn, isTrue);
      expect(await api.staff(), hasLength(2)); // the fake server refuses requests without the token
    });

    test("the server's error sentence becomes the message", () async {
      final api = _FakeServer().api();
      await expectLater(
        api.login(email: 'owner@parco.example', password: 'wrong'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Wrong email or password.')
            .having((e) => e.status, 'status', 401)),
      );
      expect(api.isSignedIn, isFalse);
    });

    test('an unreachable server gives a plain message, not a stack trace', () async {
      final api = ApiClient(
        client: MockClient((_) async => throw http.ClientException('Connection refused')),
        baseUrl: 'http://api.test',
      );
      await expectLater(
        api.login(email: 'a@b.co', password: 'x'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains("Can't reach the server"))),
      );
    });

    test('a reply that is not the expected JSON is reported, not crashed on', () async {
      final api = ApiClient(client: MockClient((_) async => http.Response('<html>proxy</html>', 200)), baseUrl: 'http://x');
      await expectLater(api.login(email: 'a@b.co', password: 'x'), throwsA(isA<ApiException>()));
      final wrongShape = ApiClient(client: MockClient((_) async => http.Response('{"token": 5}', 200)), baseUrl: 'http://x');
      await expectLater(wrongShape.login(email: 'a@b.co', password: 'x'), throwsA(isA<ApiException>()));
    });

    test('maps every JSON shape onto the app models', () async {
      final server = _FakeServer();
      final api = server.api();
      await api.login(email: 'owner@parco.example', password: 'demo1234');

      final station = (await api.stations()).single;
      expect(station.station.id, '3');
      expect(station.station.location, 'Pattoki, Punjab');
      expect(station.station.status, StationStatus.active);
      expect(station.station.tanks.single.capacity, 25000);
      expect(station.tanks.single.currentVolume, 7000);
      expect(station.pendingLitres, {'7': 2000.0});

      final nozzle = (await api.nozzles('3')).single;
      expect(nozzle.name, 'Pump 1 · Nozzle 1');
      expect(nozzle.status, NozzleStatus.dispensing);
      expect(nozzle.flowRate, 38);

      final log = (await api.vehicleLogs('3')).single;
      expect(log.litres, isNull);
      expect(log.status, LogStatus.pending);

      expect((await api.staff()).last.status, StaffStatus.onLeave);
      expect((await api.purchaseOrders('3')).single.status, PurchaseOrderStatus.pending);
      final weekly = await api.sales('3', SalesReportPeriod.weekly);
      expect(weekly, hasLength(7));
      expect(weekly.last.petrolL, 7000);
      expect(server.requests, contains('GET /stations/3/sales?period=weekly'));
    });

    test('logout ends the session on the server and forgets the token', () async {
      final server = _FakeServer();
      final api = server.api();
      await api.login(email: 'owner@parco.example', password: 'demo1234');
      await api.logout();
      expect(api.isSignedIn, isFalse);
      expect(server.requests.last, 'POST /auth/logout');
    });
  });

  group('AppSession with the server', () {
    test('signIn loads the stations, staff and the first station\'s data', () async {
      final server = _FakeServer();
      final session = AppSession(api: server.api());
      expect(session.usesServer, isTrue);
      await session.signIn(email: 'owner@parco.example', password: 'demo1234');

      expect(session.owner!.name, 'Demo Owner');
      expect(session.currentStation!.name, 'Amir Filling, Pattoki');
      expect(session.staff, hasLength(2));
      expect(session.hasDataFor('3'), isTrue);
      expect(session.tanksFor('3').single.currentVolume, 7000);
      expect(session.nozzlesFor('3').single.litres, 42.5);
      expect(session.purchaseOrdersFor('3').single.poNumber, 'PO-2026-0001');
      expect(session.logsFor('3'), hasLength(1));
      expect(session.salesFor('3', SalesReportPeriod.weekly), hasLength(7));
      expect(session.salesFor('3', SalesReportPeriod.today).single.label, 'Today');
      expect(session.pendingLitresFor('7'), 2000);
      // Nothing for a station the owner doesn't have.
      expect(session.tanksFor('999'), isEmpty);
      expect(session.salesFor('999', SalesReportPeriod.today), isEmpty);
      session.dispose();
    });

    test('a wrong password throws and leaves no one signed in', () async {
      final session = AppSession(api: _FakeServer().api());
      await expectLater(session.signIn(email: 'owner@parco.example', password: 'nope'), throwsA(isA<ApiException>()));
      expect(session.isSignedIn, isFalse);
      session.dispose();
    });

    test('a reorder goes to the server and the tank\'s pending litres and orders are reloaded', () async {
      final server = _FakeServer();
      final session = AppSession(api: server.api());
      await session.signIn(email: 'owner@parco.example', password: 'demo1234');
      final tank = session.tanksFor('3').single;

      final order = await session.placeReorder(stationId: '3', tank: tank, litres: 3000);
      expect(order!.poNumber, 'PO-2026-0002');
      expect(session.purchaseOrdersFor('3').first.poNumber, 'PO-2026-0002');
      expect(session.pendingLitresFor('7'), 5000);

      // The server's refusal comes back with its reason; nothing changes here.
      await expectLater(
        session.placeReorder(stationId: '3', tank: tank, litres: 20000),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', startsWith('Only 16,000 L'))),
      );
      expect(session.purchaseOrdersFor('3'), hasLength(2));
      session.dispose();
    });

    test('a threshold is saved on the server and the tank reloaded', () async {
      final server = _FakeServer();
      final session = AppSession(api: server.api());
      await session.signIn(email: 'owner@parco.example', password: 'demo1234');
      expect(await session.setThreshold('7', 5000), isTrue);
      expect(server.threshold, 5000);
      expect(session.tanksFor('3').single.threshold, 5000);
      expect(session.tanksFor('3').single.health, TankHealth.healthy);
      session.dispose();
    });

    test('a station that fails to load reports why, and Retry loads it', () async {
      final server = _FakeServer()..failStationData = true;
      final session = AppSession(api: server.api());
      await session.signIn(email: 'owner@parco.example', password: 'demo1234');
      expect(session.hasDataFor('3'), isFalse);
      expect(session.loadErrorFor('3'), 'Something went wrong on the server.');

      server.failStationData = false;
      await session.refresh();
      expect(session.hasDataFor('3'), isTrue);
      expect(session.loadErrorFor('3'), isNull);
      session.dispose();
    });

    test('signOut forgets everything and ends the server session', () async {
      final server = _FakeServer();
      final session = AppSession(api: server.api());
      await session.signIn(email: 'owner@parco.example', password: 'demo1234');
      session.signOut();
      expect(session.isSignedIn, isFalse);
      expect(session.stations, isEmpty);
      expect(session.tanksFor('3'), isEmpty);
      await Future<void>.delayed(Duration.zero); // the logout request is sent in the background
      expect(server.requests.last, 'POST /auth/logout');
      session.dispose();
    });
  });
}
