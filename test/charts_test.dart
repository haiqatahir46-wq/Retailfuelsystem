import 'package:flutter_test/flutter_test.dart';
import 'package:petrolpump_flutter/widgets/sales_report_widgets.dart';

void main() {
  test('chartAxisLabel shortens report row labels', () {
    expect(chartAxisLabel('Day 3'), 'D3');
    expect(chartAxisLabel('Week 1'), 'W1');
    expect(chartAxisLabel('Month 12'), 'M12');
    expect(chartAxisLabel('Today'), 'Today');
  });

  group('chartYAxis', () {
    test('uses round steps with the top a little above the highest point', () {
      // The demo weekly, monthly and yearly peaks.
      expect(chartYAxis(22500), (maxY: 30000.0, step: 10000.0));
      expect(chartYAxis(138000), (maxY: 150000.0, step: 50000.0));
      expect(chartYAxis(628000), (maxY: 800000.0, step: 200000.0));
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
}
