import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/data/demo_sales.dart';
import 'package:petrolpump_flutter/models/sales.dart';
import 'package:petrolpump_flutter/screens/dashboard_screen.dart';
import 'package:petrolpump_flutter/widgets/sales_report_widgets.dart';

/// Pumps [chart] in a 320dp-wide phone's page padding, with the system text
/// size at [textScale].
Future<void> _pumpChart(WidgetTester tester, Widget chart, {double textScale = 1.35}) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: chart),
      ),
    ),
  );
}

/// The left-axis labels with a unit ("20k", "1.5M").
final _unitLabels = find.byWidgetPredicate((w) => w is Text && RegExp(r'^[\d.]+[kMB]$').hasMatch(w.data ?? ''));

/// Fails unless every label [labels] finds is drawn whole: on one line,
/// none of it cut off, so "500k" can never read "500".
void _expectDrawnWhole(WidgetTester tester, Finder labels) {
  expect(labels, findsWidgets);
  for (final label in labels.evaluate()) {
    final paragraph = label.renderObject! as RenderParagraph;
    final text = (label.widget as Text).data;
    expect(paragraph.didExceedMaxLines, isFalse, reason: text);
    expect(paragraph.size.width, greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity) - 0.01), reason: text);
  }
}

/// The x-axis labels showing, e.g. ['M3', 'M6', 'M9', 'M12'].
List<String> _bottomLabels(WidgetTester tester, String prefix) => [
      for (final t in tester.widgetList<Text>(find.byType(Text)))
        if (RegExp('^$prefix\\d+\$').hasMatch(t.data ?? '')) t.data!,
    ];

void main() {
  test('chartAxisLabel shortens report row labels', () {
    expect(chartAxisLabel('Day 3'), 'D3');
    expect(chartAxisLabel('Week 1'), 'W1');
    expect(chartAxisLabel('Month 12'), 'M12');
    expect(chartAxisLabel('Today'), 'Today');
  });

  group('chartYAxis', () {
    test('uses round steps with the top a little above the highest point', () {
      // Station-1's weekly, monthly and yearly peaks (Petrol on Day 6, in
      // Week 4 and in Month 11).
      expect(chartYAxis(22500), (maxY: 30000.0, step: 10000.0));
      expect(chartYAxis(134000), (maxY: 150000.0, step: 50000.0));
      expect(chartYAxis(532000), (maxY: 600000.0, step: 200000.0));
    });

    test('the top is always above the highest point and a whole number of steps', () {
      for (final max in [1.0, 7.5, 99.0, 1000.0, 18001.0, 1830600.0]) {
        final axis = chartYAxis(max);
        expect(axis.maxY, greaterThan(max), reason: '$max');
        expect((axis.maxY / axis.step) % 1, 0, reason: '$max');
      }
    });

    test('all-zero or broken data still gets a usable range', () {
      expect(chartYAxis(0), (maxY: 1.0, step: 1.0));
      expect(chartYAxis(double.nan), (maxY: 1.0, step: 1.0));
    });
  });

  group('axis labels at 135% text on a 320dp phone', () {
    testWidgets('the report chart keeps each left label\'s unit', (tester) async {
      await _pumpChart(tester, SalesBarChart(period: SalesReportPeriod.yearly, data: salesFor('station-1', SalesReportPeriod.yearly)));
      _expectDrawnWhole(tester, _unitLabels);
      expect(find.text('600k'), findsOneWidget);
    });

    testWidgets('the Dashboard trend chart keeps each left label\'s unit', (tester) async {
      await _pumpChart(tester, SalesTrendChart(rows: salesFor('station-1', SalesReportPeriod.weekly)));
      _expectDrawnWhole(tester, _unitLabels);
      expect(find.text('1.5M'), findsOneWidget);
    });

    testWidgets('Yearly labels every few months when 12 would overlap, always the newest', (tester) async {
      final yearly = salesFor('station-1', SalesReportPeriod.yearly);
      await _pumpChart(tester, SalesBarChart(period: SalesReportPeriod.yearly, data: yearly));
      final shown = _bottomLabels(tester, 'M');
      expect(shown.length, lessThan(12));
      expect(shown, contains('M12'));

      // With room to spare, every month is labelled.
      tester.view.physicalSize = const Size(1200, 800);
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      await tester.pumpAndSettle();
      expect(_bottomLabels(tester, 'M'), hasLength(12));
    });
  });
}
