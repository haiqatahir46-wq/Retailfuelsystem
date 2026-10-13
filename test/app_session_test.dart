import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/data/demo_logs.dart';
import 'package:petrolpump_flutter/data/demo_owner.dart';
import 'package:petrolpump_flutter/data/demo_sales.dart';
import 'package:petrolpump_flutter/data/demo_staff.dart';
import 'package:petrolpump_flutter/data/demo_tanks.dart';
import 'package:petrolpump_flutter/models/nozzle.dart';
import 'package:petrolpump_flutter/models/sales.dart';
import 'package:petrolpump_flutter/models/station.dart';
import 'package:petrolpump_flutter/models/tank_stock.dart';
import 'package:petrolpump_flutter/state/app_session.dart';

/// Every id the demo data is keyed on. Nothing created in the app may reuse
/// one, or it would show that demo station's figures.
final _demoKeys = {...demoSalesByStation.keys, ...demoTankConfigs.keys};

AppSession _demoSession() => AppSession()..signInDemo(email: 'owner@example.com');

AppSession _signedUp({String name = 'Amir Filling', int count = 3}) =>
    AppSession()..signUp(usernameOrEmail: 'amir@gmail.com', stationName: name, stationCount: count);

void main() {
  test('starts signed out with nothing in it', () {
    final s = AppSession();
    expect(s.isSignedIn, isFalse);
    expect(s.owner, isNull);
    expect(s.stations, isEmpty);
    expect(s.currentStation, isNull);
    expect(s.staff, isEmpty);
  });

  group('signInDemo', () {
    test('gives the demo owner (with the typed email), stations and staff', () {
      final s = _demoSession();
      expect(s.isSignedIn, isTrue);
      expect(s.owner!.name, demoOwner.name);
      expect(s.owner!.email, 'owner@example.com');
      expect(s.stations.map((st) => st.id), ['station-1', 'station-2']);
      expect(s.currentStation!.id, 'station-1');
      expect(s.currentStation!.name, 'Amir Filling, Pattoki');
      expect(s.staff.map((m) => m.id), demoStaffMembers.map((m) => m.id));
    });

    test('a blank email shows the demo one', () {
      final s = AppSession()..signInDemo(email: '  ');
      expect(s.owner!.email, demoOwner.email);
    });

    test('the demo stations show the demo data', () {
      final s = _demoSession();
      expect(s.tanksFor('station-1').map((t) => t.id), tanksForStation('station-1').map((t) => t.id));
      expect(s.tanksFor('station-1').map((t) => t.currentVolume), tanksForStation('station-1').map((t) => t.currentVolume));
      expect(s.purchaseOrdersFor('station-2').map((o) => o.poNumber), purchaseOrdersFor('station-2').map((o) => o.poNumber));
      expect(s.logsFor('station-1'), logsFor('station-1'));
      expect(s.nozzlesFor('station-1'), hasLength(12));
    });

    test('lookups for a station the owner doesn\'t have are empty', () {
      final s = _demoSession();
      expect(s.tanksFor('no-such-station'), isEmpty);
      expect(s.purchaseOrdersFor('no-such-station'), isEmpty);
      expect(s.nozzlesFor('no-such-station'), isEmpty);
      expect(s.logsFor('no-such-station'), isEmpty);
    });
  });

  group('signUp', () {
    test('the owner comes from what was typed', () {
      expect(_signedUp().owner!.name, 'amir');
      expect(_signedUp().owner!.email, 'amir@gmail.com');
      final byName = AppSession()..signUp(usernameOrEmail: 'Amir Khan', stationName: 'A', stationCount: 1);
      expect(byName.owner!.name, 'Amir Khan');
      expect(byName.owner!.email, '');
    });

    test('station ids are unique and never a demo key', () {
      final ids = [..._signedUp(count: 20).stations, ..._signedUp(count: 20).stations].map((st) => st.id).toList();
      expect(ids, hasLength(40));
      expect(ids.toSet(), hasLength(40));
      expect(ids.where(_demoKeys.contains), isEmpty);
    });

    test('a signed-up station has no demo sales, tanks, orders, logs or nozzles', () {
      final s = _signedUp();
      expect(s.currentStation, s.stations.first);
      for (final st in s.stations) {
        for (final period in SalesReportPeriod.values) {
          expect(salesFor(st.id, period), isEmpty);
        }
        expect(s.tanksFor(st.id), isEmpty);
        expect(s.purchaseOrdersFor(st.id), isEmpty);
        expect(s.logsFor(st.id), isEmpty);
        expect(s.nozzlesFor(st.id), isEmpty);
      }
    });

    test('the demo stations are not the new owner\'s', () {
      final s = _signedUp();
      expect(s.stationById('station-1'), isNull);
      expect(s.tanksFor('station-1'), isEmpty);
      expect(s.purchaseOrdersFor('station-1'), isEmpty);
    });

    test('staff starts empty', () => expect(_signedUp().staff, isEmpty));

    test('the station count is clamped', () {
      expect(_signedUp(count: 999999999).stations, hasLength(Station.maxSignupStations));
      expect(_signedUp(count: 0).stations, hasLength(1));
      expect(_signedUp(count: -4).stations, hasLength(1));
    });

    test('a blank station name is normalised once, for every reader', () {
      final s = _signedUp(name: '   ', count: 2);
      expect(s.stations.first.name, 'Station 1');
      expect(s.currentStation!.name, 'Station 1');
      expect(s.stations[1].name, 'Station 2');
      expect(_signedUp(name: '  Amir Filling ').currentStation!.name, 'Amir Filling');
    });
  });

  group('stations', () {
    test('addStation builds tanks and nozzles from the form, with a fresh id', () {
      final s = _demoSession();
      final added = s.addStation(
        name: '  New Station ',
        location: 'Lahore',
        nozzleCounts: const {'Petrol': 2, 'Diesel': 1},
        capacities: const {'Petrol': 20000, 'Diesel': 10000},
      );
      expect(s.stations.last, added);
      expect(added.name, 'New Station');
      expect(_demoKeys.contains(added.id), isFalse);
      // Not made current: switching is Select Station's job.
      expect(s.currentStation!.id, 'station-1');

      final tanks = s.tanksFor(added.id);
      expect(tanks.map((t) => t.fuelName), ['Petrol', 'Diesel']);
      // No sales yet, so every tank is full and healthy.
      expect(tanks.map((t) => t.currentVolume), [20000, 10000]);
      expect(tanks.first.threshold, 20000 * Station.defaultThresholdFraction);
      expect(tanks.every((t) => t.health == TankHealth.healthy), isTrue);

      final nozzles = s.nozzlesFor(added.id);
      expect(nozzles, hasLength(3));
      expect(nozzles.every((n) => n.status == NozzleStatus.idle && n.litres == 0), isTrue);
      expect(s.logsFor(added.id), isEmpty);
      expect(s.purchaseOrdersFor(added.id), isEmpty);
    });

    test('a blank added station name becomes "Station N"', () {
      final s = _demoSession();
      final added = s.addStation(name: ' ', location: '', nozzleCounts: const {}, capacities: const {});
      expect(added.name, 'Station 3');
    });

    test('two added stations get different ids', () {
      final s = _demoSession();
      final a = s.addStation(name: 'A', location: '', nozzleCounts: const {}, capacities: const {});
      final b = s.addStation(name: 'B', location: '', nozzleCounts: const {}, capacities: const {});
      expect(a.id, isNot(b.id));
    });

    test('selectStation switches the current station; an unknown id is ignored', () {
      final s = _demoSession();
      s.selectStation('station-2');
      expect(s.currentStation!.id, 'station-2');
      s.selectStation('no-such-station');
      expect(s.currentStation!.id, 'station-2');
    });

    test('updateStationLocation changes only the location', () {
      final s = _demoSession();
      s.updateStationLocation('station-1', '  Main Bazaar, Pattoki  ');
      final st = s.stationById('station-1')!;
      expect(st.location, 'Main Bazaar, Pattoki');
      expect(st.name, 'Amir Filling, Pattoki');
    });
  });

  test('addStaff persists, with a fresh id', () {
    final s = _demoSession();
    final before = s.staff.length;
    final added = s.addStaff(name: ' Ali Raza ', role: 'Attendant', phone: '0300-0000000');
    expect(s.staff, hasLength(before + 1));
    expect(s.staff.last.name, 'Ali Raza');
    expect(s.staff.map((m) => m.id).toSet(), hasLength(before + 1));
    expect(s.staff.last.id, added.id);
  });

  group('setThreshold', () {
    test('changes that tank\'s threshold and health, and only that tank\'s', () {
      final s = _demoSession();
      TankStock petrol() => s.tanksFor('station-1').firstWhere((t) => t.id == 'station-1-petrol');
      // 7,000 L left against the demo 18,000 L threshold.
      expect(petrol().health, TankHealth.critical);

      expect(s.setThreshold('station-1-petrol', 5000), isTrue);
      expect(petrol().threshold, 5000);
      expect(petrol().health, TankHealth.healthy);
      expect(s.tanksFor('station-1').firstWhere((t) => t.id == 'station-1-diesel').threshold, 18000);
    });

    test('rejects a value that isn\'t a finite, non-negative number of litres', () {
      final s = _demoSession();
      expect(s.setThreshold('station-1-petrol', -1), isFalse);
      expect(s.setThreshold('station-1-petrol', double.nan), isFalse);
      expect(s.setThreshold('station-1-petrol', double.infinity), isFalse);
      expect(s.tanksFor('station-1').first.threshold, 18000);
    });
  });

  group('placeReorder', () {
    test('adds a pending order dated today at the top, with a unique PO number', () {
      final s = _demoSession();
      final tank = s.tanksFor('station-1').first;
      final first = s.placeReorder(stationId: 'station-1', tank: tank, litres: 5000)!;
      final second = s.placeReorder(stationId: 'station-1', tank: tank, litres: 3000)!;

      final orders = s.purchaseOrdersFor('station-1');
      expect(orders.first, second);
      expect(orders[1], first);
      expect(orders, hasLength(purchaseOrdersFor('station-1').length + 2));
      expect(second.status, PurchaseOrderStatus.pending);
      expect(second.fuelName, tank.fuelName);
      expect(second.litres, 3000);
      final now = DateTime.now();
      expect(second.date, DateTime(now.year, now.month, now.day));

      final numbers = orders.map((o) => o.poNumber).toList();
      expect(numbers.toSet(), hasLength(numbers.length));
      // Placed at station-1 only.
      expect(s.purchaseOrdersFor('station-2'), hasLength(purchaseOrdersFor('station-2').length));
    });

    test('places nothing for zero, negative or non-finite litres, or another owner\'s station', () {
      final s = _demoSession();
      final tank = s.tanksFor('station-1').first;
      expect(s.placeReorder(stationId: 'station-1', tank: tank, litres: 0), isNull);
      expect(s.placeReorder(stationId: 'station-1', tank: tank, litres: -10), isNull);
      expect(s.placeReorder(stationId: 'station-1', tank: tank, litres: double.nan), isNull);
      expect(s.placeReorder(stationId: 'no-such-station', tank: tank, litres: 100), isNull);
      expect(s.purchaseOrdersFor('station-1'), hasLength(purchaseOrdersFor('station-1').length));
    });
  });

  test('signOut clears everything', () {
    final s = _demoSession();
    s.addStaff(name: 'A', role: 'Attendant', phone: '1');
    s.setThreshold('station-1-petrol', 5000);
    s.placeReorder(stationId: 'station-1', tank: s.tanksFor('station-1').first, litres: 100);
    s.signOut();
    expect(s.isSignedIn, isFalse);
    expect(s.owner, isNull);
    expect(s.stations, isEmpty);
    expect(s.currentStation, isNull);
    expect(s.staff, isEmpty);
    expect(s.tanksFor('station-1'), isEmpty);

    // A fresh sign-in starts clean: no threshold or order carried over.
    s.signInDemo(email: 'x@example.com');
    expect(s.tanksFor('station-1').first.threshold, 18000);
    expect(s.purchaseOrdersFor('station-1'), hasLength(purchaseOrdersFor('station-1').length));
  });

  test('every change notifies listeners', () {
    final s = AppSession();
    var calls = 0;
    s.addListener(() => calls++);
    s.signInDemo(email: 'a@b.c');
    s.selectStation('station-2');
    s.addStation(name: 'N', location: '', nozzleCounts: const {}, capacities: const {});
    s.updateStationLocation('station-2', 'Somewhere');
    s.addStaff(name: 'A', role: 'Attendant', phone: '1');
    s.setThreshold('station-2-petrol', 100);
    s.placeReorder(stationId: 'station-2', tank: s.tanksFor('station-2').first, litres: 100);
    s.signOut();
    expect(calls, 8);
  });
}
