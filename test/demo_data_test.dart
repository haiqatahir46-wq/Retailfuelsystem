import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/data/demo_logs.dart';
import 'package:petrolpump_flutter/data/demo_nozzles.dart';
import 'package:petrolpump_flutter/data/demo_sales.dart';
import 'package:petrolpump_flutter/data/demo_stations.dart';
import 'package:petrolpump_flutter/data/demo_tanks.dart';
import 'package:petrolpump_flutter/models/log_entry.dart';
import 'package:petrolpump_flutter/models/sales.dart';
import 'package:petrolpump_flutter/models/station.dart';
import 'package:petrolpump_flutter/models/tank_stock.dart';

// Invariants every demo station's data must keep, so no two screens can
// show figures that contradict each other. A new demo station is checked
// automatically.

/// Every grade's litres in [a] equal those in [b] (labels aside).
void _expectSameLitres(PeriodSales a, PeriodSales b, String reason) {
  for (final grade in kFuelGrades) {
    expect(a.litresOf(grade), b.litresOf(grade), reason: '$reason: $grade');
  }
}

/// Litres per grade, summed over [items].
Map<String, double> _litresByGrade<T>(Iterable<T> items, String Function(T) grade, double Function(T) litres) {
  final totals = <String, double>{};
  for (final item in items) {
    totals.update(grade(item), (v) => v + litres(item), ifAbsent: () => litres(item));
  }
  return totals;
}

void main() {
  final ids = {for (final s in demoStations) s.id};

  test('every demo station has sales, tanks, orders, logs and nozzles', () {
    expect(ids, isNotEmpty);
    expect(demoSalesByStation.keys.toSet(), ids);
    for (final id in ids) {
      for (final period in SalesReportPeriod.values) {
        expect(salesFor(id, period), isNotEmpty, reason: '$id $period');
      }
      expect(tanksForStation(id), isNotEmpty, reason: id);
      expect(purchaseOrdersFor(id), isNotEmpty, reason: id);
      expect(logsFor(id), isNotEmpty, reason: id);
      expect(nozzlesFor(id), isNotEmpty, reason: id);
    }
  });

  for (final id in ids) {
    group(id, () {
      final today = PeriodSales.sum(salesFor(id, SalesReportPeriod.today));
      final weekly = salesFor(id, SalesReportPeriod.weekly);
      final monthly = salesFor(id, SalesReportPeriod.monthly);
      final yearly = salesFor(id, SalesReportPeriod.yearly);

      test('periods run oldest -> newest and nest inside each other', () {
        expect(weekly, hasLength(7));
        expect(monthly, hasLength(4));
        expect(yearly, hasLength(12));
        _expectSameLitres(weekly.last, today, 'last weekly row is today');
        _expectSameLitres(monthly.last, PeriodSales.sum(weekly), 'last monthly row is the 7 days');
        _expectSameLitres(yearly.last, PeriodSales.sum(monthly), 'last yearly row is the 4 weeks');
        expect(weekly.last.label, 'Day 7');
        expect(monthly.last.label, 'Week 4');
        expect(yearly.last.label, 'Month 12');
      });

      test('every fuel name is one of kFuelGrades', () {
        final names = {
          ...tanksForStation(id).map((t) => t.fuelName),
          ...nozzlesFor(id).map((n) => n.fuelName),
          ...purchaseOrdersFor(id).map((o) => o.fuelName),
          ...logsFor(id).map((e) => e.fuelType),
        };
        expect(kFuelGrades, containsAll(names));
      });

      test('every order names one of the station\'s tanks, of its own grade', () {
        final tanks = {for (final t in tanksForStation(id)) t.id: t};
        for (final o in purchaseOrdersFor(id)) {
          expect(tanks.keys, contains(o.tankId), reason: o.poNumber);
          expect(o.fuelName, tanks[o.tankId]!.fuelName, reason: o.poNumber);
        }
      });

      test('no purchase order is dated in the future', () {
        final now = DateTime.now();
        for (final o in purchaseOrdersFor(id)) {
          expect(o.date.isAfter(now), isFalse, reason: o.poNumber);
        }
      });

      test('pending orders fit in their tank\'s room', () {
        for (final tank in tanksForStation(id)) {
          final pending = purchaseOrdersFor(id)
              .where((o) => o.tankId == tank.id && o.status == PurchaseOrderStatus.pending)
              .fold<double>(0, (sum, o) => sum + o.litres);
          expect(pending, lessThanOrEqualTo(tank.spaceLeft), reason: tank.id);
        }
      });

      test('nozzle litres per grade are within today\'s sales of that grade', () {
        final byGrade = _litresByGrade(nozzlesFor(id), (n) => n.fuelName, (n) => n.litres);
        byGrade.forEach((grade, litres) {
          expect(litres, lessThanOrEqualTo(today.litresOf(grade)), reason: grade);
        });
      });

      test('completed log litres per grade are within today\'s sales of that grade', () {
        final completed = logsFor(id).where((e) => e.status == LogStatus.completed && e.litres != null);
        final byGrade = _litresByGrade(completed, (e) => e.fuelType, (e) => e.litres!);
        expect(byGrade, isNotEmpty);
        byGrade.forEach((grade, litres) {
          expect(litres, lessThanOrEqualTo(today.litresOf(grade)), reason: grade);
        });
      });

      test('every figure is inside the forms\' maxima', () {
        for (final t in tanksForStation(id)) {
          expect(t.capacity, lessThanOrEqualTo(Station.maxCapacityLitres), reason: t.id);
        }
        for (final e in logsFor(id)) {
          expect(e.litres ?? 0, lessThanOrEqualTo(VehicleLogEntry.maxLitres));
        }
      });
    });
  }

  test('PO numbers are unique across the demo stations', () {
    final numbers = [for (final id in ids) ...purchaseOrdersFor(id).map((o) => o.poNumber)];
    expect(numbers.toSet(), hasLength(numbers.length));
  });

  test('nozzle update times are measured from when they are read', () {
    final before = DateTime.now();
    final nozzles = nozzlesFor('station-1');
    final after = DateTime.now();
    // Pump 1 Nozzle 1 last reported a minute ago - whenever it is read.
    final p1n1 = nozzles.firstWhere((n) => n.id == 'station-1-p1n1');
    expect(p1n1.lastUpdated.isBefore(before.subtract(const Duration(minutes: 1))), isFalse);
    expect(p1n1.lastUpdated.isAfter(after.subtract(const Duration(minutes: 1))), isFalse);
    // A fresh list each read, not one kept from the first.
    expect(identical(nozzlesFor('station-1').first, nozzlesFor('station-1').first), isFalse);
  });
}
