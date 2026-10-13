import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/data/demo_logs.dart';
import 'package:petrolpump_flutter/data/demo_nozzles.dart';
import 'package:petrolpump_flutter/data/demo_sales.dart';
import 'package:petrolpump_flutter/data/demo_tanks.dart';
import 'package:petrolpump_flutter/models/nozzle.dart';
import 'package:petrolpump_flutter/models/sales.dart';
import 'package:petrolpump_flutter/models/tank_stock.dart';

const _unknown = 'no-such-station';

void main() {
  group('unknown station ids give empty lists, never another station\'s data', () {
    test('salesFor', () {
      for (final period in SalesReportPeriod.values) {
        expect(salesFor(_unknown, period), isEmpty, reason: '$period');
      }
    });
    test('tanksForStation', () => expect(tanksForStation(_unknown), isEmpty));
    test('purchaseOrdersFor', () => expect(purchaseOrdersFor(_unknown), isEmpty));
    test('logsFor', () => expect(logsFor(_unknown), isEmpty));
    test('nozzlesFor', () => expect(nozzlesFor(_unknown), isEmpty));
  });

  group('station-1 and station-2 have their own data', () {
    test('sales', () {
      for (final period in SalesReportPeriod.values) {
        final a = PeriodSales.sum(salesFor('station-1', period));
        final b = PeriodSales.sum(salesFor('station-2', period));
        expect(a.totalLitres, isNot(b.totalLitres), reason: '$period');
      }
    });

    test('tanks', () {
      final a = tanksForStation('station-1');
      final b = tanksForStation('station-2');
      expect(a, isNotEmpty);
      expect(b, isNotEmpty);
      expect(a.map((t) => t.currentVolume), isNot(b.map((t) => t.currentVolume)));
      // Ids are unique across stations, so per-tank settings can't collide.
      final ids = [...a, ...b].map((t) => t.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('purchase orders, with PO numbers unique across stations', () {
      final a = purchaseOrdersFor('station-1');
      final b = purchaseOrdersFor('station-2');
      expect(a, isNotEmpty);
      expect(b, isNotEmpty);
      final numbers = [...a, ...b].map((o) => o.poNumber).toList();
      expect(numbers.toSet(), hasLength(numbers.length));
    });

    test('purchase orders include both statuses', () {
      final statuses = [...purchaseOrdersFor('station-1'), ...purchaseOrdersFor('station-2')].map((o) => o.status).toSet();
      expect(statuses, containsAll(PurchaseOrderStatus.values));
    });

    test('logs', () {
      final a = logsFor('station-1');
      final b = logsFor('station-2');
      expect(a, isNotEmpty);
      expect(b, isNotEmpty);
      expect(a.length, isNot(b.length));
    });

    test('nozzles cover all three grades at each station', () {
      for (final id in ['station-1', 'station-2']) {
        final grades = nozzlesFor(id).map((n) => n.fuelName).toSet();
        expect(grades, containsAll(kFuelGrades), reason: id);
      }
      expect(nozzlesFor('station-1').length, isNot(nozzlesFor('station-2').length));
      final ids = [...nozzlesFor('station-1'), ...nozzlesFor('station-2')].map((n) => n.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every nozzle status appears in the demo data', () {
      final statuses = nozzlesFor('station-1').map((n) => n.status).toSet();
      expect(statuses, containsAll(NozzleStatus.values));
    });
  });

  group('buildTanks', () {
    const configs = [
      TankConfig(id: 'a-petrol', fuelName: 'Petrol', capacity: 25000, threshold: 18000),
      TankConfig(id: 'a-diesel', fuelName: 'Diesel', capacity: 10000, threshold: 4000),
      TankConfig(id: 'a-octane', fuelName: 'Hi-Octane', capacity: 5000, threshold: 1000),
    ];
    const today = PeriodSales(label: 'Today', petrolL: 6000, dieselL: 12000, octaneL: 0);

    test('volume is capacity minus that grade\'s sales today, clamped to 0..capacity', () {
      final tanks = buildTanks(configs: configs, today: today);
      expect(tanks.map((t) => t.id), ['a-petrol', 'a-diesel', 'a-octane']);
      expect(tanks[0].currentVolume, 19000);
      expect(tanks[1].currentVolume, 0); // sold more than it holds
      expect(tanks[2].currentVolume, 5000);
      expect(tanks[0].threshold, 18000);
    });

    test('no sales yet means every tank is full', () {
      final tanks = buildTanks(configs: configs, today: null);
      expect(tanks.map((t) => t.currentVolume), [25000, 10000, 5000]);
    });

    test('a capacity of 0 gives an empty tank instead of throwing', () {
      final tanks = buildTanks(
        configs: const [TankConfig(id: 'z', fuelName: 'Petrol', capacity: 0, threshold: 100)],
        today: today,
      );
      expect(tanks.single.currentVolume, 0);
      expect(tanks.single.health, TankHealth.critical);
    });

    test('threshold overrides apply by tank id', () {
      final tanks = buildTanks(configs: configs, today: today, thresholdOverrides: const {'a-diesel': 500});
      expect(tanks[1].threshold, 500);
      expect(tanks[0].threshold, 18000);
      expect(tanks[2].threshold, 1000);
    });

    test('tanksForStation matches capacity minus today\'s summed sales', () {
      final today = PeriodSales.sum(salesFor('station-1', SalesReportPeriod.today));
      final configs = demoTankConfigs['station-1']!;
      final tanks = tanksForStation('station-1');
      expect(tanks, hasLength(configs.length));
      for (var i = 0; i < tanks.length; i++) {
        expect(tanks[i].id, configs[i].id);
        expect(tanks[i].currentVolume, configs[i].capacity - today.litresOf(configs[i].fuelName));
      }
    });

    test('tanksForStation applies threshold overrides', () {
      final tanks = tanksForStation('station-1', thresholdOverrides: const {'station-1-petrol': 5000});
      final petrol = tanks.firstWhere((t) => t.id == 'station-1-petrol');
      final diesel = tanks.firstWhere((t) => t.id == 'station-1-diesel');
      expect(petrol.threshold, 5000);
      expect(petrol.health, TankHealth.healthy); // 7,000 L left vs a 5,000 L threshold
      expect(diesel.threshold, 18000);
    });
  });
}
