import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/data/demo_sales.dart';
import 'package:petrolpump_flutter/models/sales.dart';
import 'package:petrolpump_flutter/navigation/main_tabs_flow.dart';
import 'package:petrolpump_flutter/screens/dashboard_screen.dart';
import 'package:petrolpump_flutter/state/app_session.dart';

/// The main tabs for the demo owner, on station-1: Petrol 7,000 L
/// (critical), Diesel 16,000 L (low) and Hi-Octane 22,000 L (healthy), each
/// with an 18,000 L threshold.
Future<AppSession> _openTabs(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final session = AppSession()..signInDemo(email: 'owner@example.com');
  addTearDown(session.dispose);
  await tester.pumpWidget(AppSessionScope(session: session, child: const MaterialApp(home: MainTabsFlow())));
  await tester.pumpAndSettle();
  return session;
}

/// A weekly row whose revenue is [petrolL] × the Petrol price.
PeriodSales _day(int n, double petrolL) => PeriodSales(label: 'Day $n', petrolL: petrolL, dieselL: 0, octaneL: 0);

/// Pumps the trend chart alone, with [rows] as its week.
Future<void> _pumpTrend(WidgetTester tester, List<PeriodSales> rows) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SalesTrendChart(rows: rows))));
}

/// The ▲/▼ change badge, if one is showing.
Finder _badge() => find.byWidgetPredicate((w) => w is Text && RegExp('^[▲▼] ').hasMatch(w.data ?? ''));

void main() {
  group('Dashboard sales trend', () {
    testWidgets('its latest point is Revenue Today, for every demo station', (tester) async {
      final session = await _openTabs(tester);
      for (final id in ['station-1', 'station-2']) {
        session.selectStation(id);
        await tester.pumpAndSettle();
        final today = PeriodSales.sum(salesFor(id, SalesReportPeriod.today)).totalRevenue;
        final spots = tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.single.spots;
        expect(spots, hasLength(7), reason: id);
        expect(spots.last.y, today, reason: id);
        // The figure on the Revenue Today (PKR) card is that same number.
        expect(find.text(formatThousands(spots.last.y)), findsOneWidget, reason: id);
      }
      // station-1: PKR 1,408,200 on Day 1, PKR 1,512,000 today.
      session.selectStation('station-1');
      await tester.pumpAndSettle();
      expect(find.text('1,512,000'), findsOneWidget);
      expect(find.text('▲ 7.4%'), findsOneWidget);
    });

    testWidgets('the badge measures first -> last: up is ▲, down is ▼', (tester) async {
      await _pumpTrend(tester, [_day(1, 100), _day(2, 500), _day(3, 150)]);
      expect(find.text('▲ 50.0%'), findsOneWidget);

      await _pumpTrend(tester, [_day(1, 200), _day(2, 50), _day(3, 150)]);
      expect(find.text('▼ 25.0%'), findsOneWidget);

      await _pumpTrend(tester, [_day(1, 200), _day(2, 200)]);
      expect(find.text('▲ 0.0%'), findsOneWidget);
    });

    testWidgets('no badge with fewer than 2 points or a first point of 0', (tester) async {
      await _pumpTrend(tester, [_day(1, 100)]);
      expect(_badge(), findsNothing);
      expect(find.byType(LineChart), findsOneWidget);

      await _pumpTrend(tester, [_day(1, 0), _day(2, 100)]);
      expect(_badge(), findsNothing);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('no rows shows a message instead of a chart', (tester) async {
      await _pumpTrend(tester, const []);
      expect(find.text('No sales recorded this week yet.'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
      expect(_badge(), findsNothing);
    });
  });

  group('Dashboard low-stock alert', () {
    testWidgets('names every tank below its threshold, worst first', (tester) async {
      await _openTabs(tester);
      final critical = find.text('Petrol is critical: 7,000 L left (threshold 18,000 L)');
      final low = find.text('Diesel is low: 16,000 L left (threshold 18,000 L)');
      expect(critical, findsOneWidget);
      expect(low, findsOneWidget);
      expect(find.textContaining('Hi-Octane is'), findsNothing);
      expect(tester.getTopLeft(critical).dy, lessThan(tester.getTopLeft(low).dy));
    });

    testWidgets('tapping it opens Stock', (tester) async {
      await _openTabs(tester);
      await tester.tap(find.text('Reorder'));
      await tester.pumpAndSettle();
      expect(find.text('Recent Purchased Orders'), findsOneWidget);
    });

    testWidgets('is hidden once every tank is healthy', (tester) async {
      final session = await _openTabs(tester);
      session.setThreshold('station-1-petrol', 5000);
      session.setThreshold('station-1-diesel', 5000);
      await tester.pumpAndSettle();
      expect(find.textContaining('is critical'), findsNothing);
      expect(find.textContaining('is low'), findsNothing);
      expect(find.text('Reorder'), findsNothing);
    });

    testWidgets('is hidden for a station with no tanks', (tester) async {
      final session = await _openTabs(tester);
      final station = session.addStation(
        name: 'No Tanks',
        location: 'Lahore',
        nozzleCounts: const {'Petrol': 1},
        capacities: const {},
      );
      session.selectStation(station.id);
      await tester.pumpAndSettle();
      expect(find.text('No Tanks'), findsOneWidget);
      expect(find.text('Reorder'), findsNothing);
    });
  });

  group('Nozzles tab', () {
    testWidgets('the sales card and status counts follow the selected grade', (tester) async {
      await _openTabs(tester);
      await tester.tap(find.text('Nozzles'));
      await tester.pumpAndSettle();

      // Petrol: 18,000 L today × PKR 50, the same figures as the Dashboard.
      expect(find.text('Petrol Sales (Today)'), findsOneWidget);
      expect(find.text('18,000 L'), findsOneWidget);
      expect(find.text('PKR 900,000'), findsOneWidget);
      expect(find.text('All 6'), findsOneWidget);
      expect(find.text('Dispensing 4'), findsOneWidget);
      expect(find.text('Idle 1'), findsOneWidget);
      expect(find.text('Faults 1'), findsOneWidget);
      expect(find.text('Fault'), findsOneWidget); // the faulty nozzle's card

      // Diesel: 9,000 L × PKR 48.
      await tester.tap(find.text('Diesel'));
      await tester.pumpAndSettle();
      expect(find.text('Diesel Sales (Today)'), findsOneWidget);
      expect(find.text('9,000 L'), findsOneWidget);
      expect(find.text('PKR 432,000'), findsOneWidget);
      expect(find.text('All 4'), findsOneWidget);
      expect(find.text('Dispensing 3'), findsOneWidget);
      expect(find.text('Faults 0'), findsOneWidget);
    });

    testWidgets('a grade with no nozzles says so', (tester) async {
      final session = await _openTabs(tester);
      final station = session.addStation(
        name: 'Petrol Only',
        location: 'Lahore',
        nozzleCounts: const {'Petrol': 2},
        capacities: const {'Petrol': 20000},
      );
      session.selectStation(station.id);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nozzles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hi-Octane'));
      await tester.pumpAndSettle();

      expect(find.text('No Hi-Octane nozzles set up for this station yet.'), findsOneWidget);
      expect(find.text('All 0'), findsOneWidget);
      // A new station has no sales yet.
      expect(find.text('PKR 0'), findsOneWidget);
    });
  });
}
