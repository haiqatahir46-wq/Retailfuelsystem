import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/models/nozzle.dart';
import 'package:petrolpump_flutter/models/owner.dart';
import 'package:petrolpump_flutter/models/sales.dart';
import 'package:petrolpump_flutter/models/station.dart';
import 'package:petrolpump_flutter/models/tank_stock.dart';

TankStock _tank({double volume = 0, double capacity = 25000, double threshold = 18000}) => TankStock(
      id: 't',
      fuelName: 'Petrol',
      currentVolume: volume,
      capacity: capacity,
      threshold: threshold,
    );

void main() {
  group('TankStock.percentFull', () {
    test('is volume over capacity', () {
      expect(_tank(volume: 12500).percentFull, 0.5);
      expect(_tank(volume: 25000).percentFull, 1.0);
    });

    test('clamps to 0..1', () {
      expect(_tank(volume: 30000).percentFull, 1.0);
      expect(_tank(volume: -10).percentFull, 0.0);
    });

    test('is 0 for a capacity of 0 or less instead of NaN', () {
      expect(_tank(volume: 100, capacity: 0).percentFull, 0.0);
      expect(_tank(volume: 100, capacity: -5).percentFull, 0.0);
    });
  });

  group('TankStock.health', () {
    test('exactly at the threshold is healthy', () {
      expect(_tank(volume: 18000).health, TankHealth.healthy);
    });

    test('above the threshold is healthy', () {
      expect(_tank(volume: 25000).health, TankHealth.healthy);
    });

    test('just below the threshold is low', () {
      expect(_tank(volume: 17999).health, TankHealth.low);
    });

    test('exactly half the threshold is low', () {
      expect(_tank(volume: 9000).health, TankHealth.low);
    });

    test('below half the threshold is critical', () {
      expect(_tank(volume: 8999).health, TankHealth.critical);
      expect(_tank(volume: 0).health, TankHealth.critical);
    });

    test('a capacity of 0 is critical and does not throw', () {
      final tank = _tank(volume: 0, capacity: 0, threshold: 0);
      expect(tank.health, TankHealth.critical);
      expect(tank.percentFull, 0.0);
    });
  });

  test('TankStock.copyWith replaces only the given fields', () {
    final tank = _tank(volume: 100);
    final changed = tank.copyWith(threshold: 500);
    expect(changed.threshold, 500);
    expect(changed.currentVolume, 100);
    expect(changed.id, tank.id);
    expect(changed.capacity, tank.capacity);
  });

  group('formatThousands', () {
    test('adds separators', () {
      expect(formatThousands(0), '0');
      expect(formatThousands(999), '999');
      expect(formatThousands(1000), '1,000');
      expect(formatThousands(25000), '25,000');
      expect(formatThousands(1512000), '1,512,000');
    });

    test('rounds to a whole number', () {
      expect(formatThousands(1234.4), '1,234');
      expect(formatThousands(1234.6), '1,235');
    });

    test('handles negatives', () {
      expect(formatThousands(-1234), '-1,234');
    });
  });

  test('formatCompact shortens axis values', () {
    expect(formatCompact(0), '0');
    expect(formatCompact(950), '950');
    expect(formatCompact(1500), '1.5k');
    expect(formatCompact(20000), '20k');
    expect(formatCompact(800000), '800k');
    expect(formatCompact(2400000), '2.4M');
    expect(formatCompact(3000000), '3M');
  });

  test('formatDate', () {
    expect(formatDate(DateTime(2026, 5, 15)), '15 May 2026');
    expect(formatDate(DateTime(2026, 1, 3)), '3 Jan 2026');
  });

  group('PeriodSales', () {
    const row = PeriodSales(label: 'Day', petrolL: 100, dieselL: 200, octaneL: 10);

    test('revenue is litres × price per grade', () {
      expect(row.petrolRevenue, 100 * kPetrolPricePerLitre);
      expect(row.dieselRevenue, 200 * kDieselPricePerLitre);
      expect(row.octaneRevenue, 10 * kHiOctanePricePerLitre);
      expect(row.totalRevenue, 5000 + 9600 + 600);
      expect(row.totalLitres, 310);
    });

    test('litresOf picks the grade by name', () {
      expect(row.litresOf('Petrol'), 100);
      expect(row.litresOf('Diesel'), 200);
      expect(row.litresOf('Hi-Octane'), 10);
      expect(row.litresOf('Kerosene'), 0);
    });

    test('sum adds every row', () {
      final total = PeriodSales.sum(const [
        row,
        PeriodSales(label: 'Other', petrolL: 1, dieselL: 2, octaneL: 3),
      ], label: 'Today');
      expect(total.label, 'Today');
      expect(total.petrolL, 101);
      expect(total.dieselL, 202);
      expect(total.octaneL, 13);
      expect(total.totalRevenue, row.totalRevenue + 1 * 50 + 2 * 48 + 3 * 60);
    });

    test('sum of no rows is all zeros', () {
      final total = PeriodSales.sum(const []);
      expect(total.label, '');
      expect(total.totalLitres, 0);
      expect(total.totalRevenue, 0);
    });
  });

  test('pricePerLitre matches the price constants', () {
    expect(pricePerLitre('Petrol'), kPetrolPricePerLitre);
    expect(pricePerLitre('Diesel'), kDieselPricePerLitre);
    expect(pricePerLitre('Hi-Octane'), kHiOctanePricePerLitre);
    expect(pricePerLitre('Unknown'), 0);
    for (final grade in kFuelGrades) {
      expect(pricePerLitre(grade), greaterThan(0), reason: grade);
    }
  });

  group('Station.fromSignup', () {
    var n = 0;
    String id() => 'id-${++n}';

    test('first station is the named, active one; the rest are pending', () {
      final list = Station.fromSignup(stationName: 'Amir Filling', stationCount: 3, newId: id);
      expect(list, hasLength(3));
      expect(list.first.name, 'Amir Filling');
      expect(list.first.status, StationStatus.active);
      expect(list[1].name, 'Station 2');
      expect(list[1].status, StationStatus.pending);
      expect(list[2].name, 'Station 3');
      expect(list[2].status, StationStatus.pending);
      // Ids come from newId, one each; nothing is set up yet.
      expect(list.map((s) => s.id).toSet(), hasLength(3));
      for (final s in list) {
        expect(s.tanks, isEmpty);
        expect(s.nozzles, isEmpty);
      }
    });

    test('a single station gives one entry', () {
      final list = Station.fromSignup(stationName: 'Amir Filling', stationCount: 1, newId: id);
      expect(list, hasLength(1));
      expect(list.single.status, StationStatus.active);
    });

    test('a blank or spaces-only name falls back to "Station 1"; others are trimmed', () {
      expect(Station.fromSignup(stationName: '', stationCount: 1, newId: id).single.name, 'Station 1');
      expect(Station.fromSignup(stationName: '   ', stationCount: 1, newId: id).single.name, 'Station 1');
      expect(Station.fromSignup(stationName: '  Amir  ', stationCount: 1, newId: id).single.name, 'Amir');
    });

    test('the count is clamped to 1..maxSignupStations', () {
      expect(Station.fromSignup(stationName: 'A', stationCount: 0, newId: id), hasLength(1));
      expect(Station.fromSignup(stationName: 'A', stationCount: -5, newId: id), hasLength(1));
      expect(
        Station.fromSignup(stationName: 'A', stationCount: 999999999, newId: id),
        hasLength(Station.maxSignupStations),
      );
    });
  });

  group('Station.fromSetup', () {
    final now = DateTime(2026, 5, 22, 9);

    test('one tank per grade with a usable capacity, threshold a fixed fraction of it', () {
      final s = Station.fromSetup(
        id: 'x',
        name: 'New',
        location: '  Lahore  ',
        nozzleCounts: const {},
        capacities: const {'Petrol': 20000, 'Diesel': 0, 'Hi-Octane': double.nan},
        now: now,
      );
      expect(s.location, 'Lahore');
      expect(s.tanks, hasLength(1));
      final petrol = s.tanks.single;
      expect(petrol.id, 'x-petrol');
      expect(petrol.fuelName, 'Petrol');
      expect(petrol.capacity, 20000);
      expect(petrol.threshold, 20000 * Station.defaultThresholdFraction);
    });

    test('nozzle counts become idle, empty nozzles, two per pump, one grade per pump', () {
      final s = Station.fromSetup(
        id: 'x',
        name: 'New',
        location: '',
        nozzleCounts: const {'Petrol': 3, 'Diesel': 1, 'Hi-Octane': 0},
        capacities: const {},
        now: now,
      );
      expect(s.nozzles.map((n) => n.name), [
        'Pump 1 · Nozzle 1',
        'Pump 1 · Nozzle 2',
        'Pump 2 · Nozzle 1',
        'Pump 3 · Nozzle 1',
      ]);
      expect(s.nozzles.map((n) => n.fuelName), ['Petrol', 'Petrol', 'Petrol', 'Diesel']);
      for (final n in s.nozzles) {
        expect(n.status, NozzleStatus.idle);
        expect(n.litres, 0);
        expect(n.flowRate, 0);
        expect(n.lastUpdated, now);
      }
      expect(s.nozzles.map((n) => n.id).toSet(), hasLength(4));
    });

    test('nozzle counts are clamped, so huge or negative input stays bounded', () {
      final s = Station.fromSetup(
        id: 'x',
        name: 'New',
        location: '',
        nozzleCounts: const {'Petrol': 999999999, 'Diesel': -3},
        capacities: const {},
        now: now,
      );
      expect(s.nozzles, hasLength(Station.maxNozzlesPerGrade));
    });
  });

  group('Owner.fromSignup', () {
    test('an email gives the email and the part before the @ as the name', () {
      final o = Owner.fromSignup('  amir.khan@gmail.com ');
      expect(o.email, 'amir.khan@gmail.com');
      expect(o.name, 'amir.khan');
    });

    test('a username is the name, with no email', () {
      final o = Owner.fromSignup('Amir Khan');
      expect(o.name, 'Amir Khan');
      expect(o.email, '');
    });

    test('nothing usable typed falls back to "Owner"', () {
      expect(Owner.fromSignup('   ').name, 'Owner');
      expect(Owner.fromSignup('@gmail.com').name, 'Owner');
    });
  });
}
