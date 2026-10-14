import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/sales.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import 'empty_state.dart';

// The pieces of the Dashboard's Weekly / Monthly / Yearly sales report:
// the period dropdown, the total card, one card per period row and the
// chart.

/// The red "Total Revenue · Weekly   PKR 1,234,000" card. The label and the
/// amount get half the row each (both flex 1): the label wraps onto a
/// second line if it must, and the amount shrinks to fit its half, so a
/// long total never overflows a narrow screen.
class TotalRevenueCard extends StatelessWidget {
  final String label;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.brandRed,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.brandRed.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total Revenue · $label',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                total,
                maxLines: 1,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  const TotalRevenueCard({super.key, required this.label, required this.total});
}

/// The one dropdown for Today / Weekly / Monthly / Yearly: tapping it opens
/// a menu of all four periods, and picking one switches the report in
/// place. It shows [period]'s own name (periodLabel).
class PeriodDropdown extends StatelessWidget {
  final SalesReportPeriod period;
  final ValueChanged<SalesReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SalesReportPeriod>(
      onSelected: onChanged,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => SalesReportPeriod.values
          .map(
            (p) => PopupMenuItem(
              value: p,
              child: Text(
                periodLabel(p),
                style: TextStyle(
                  fontWeight: p == period ? FontWeight.w700 : FontWeight.w500,
                  color: p == period ? AppColors.brandRed : AppColors.primaryText,
                ),
              ),
            ),
          )
          .toList(),
      // The menu button's tap area is its child, so the child is at least
      // 48dp tall (the recommended minimum) with the smaller box centred
      // in it, which keeps its look.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Align(
          widthFactor: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDivider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  periodLabel(period),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.secondaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  const PeriodDropdown({super.key, required this.period, required this.onChanged});
}

/// One period row of the report (a day, week or month): litres and revenue
/// per grade.
class PeriodCard extends StatelessWidget {
  final PeriodSales sales;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sales.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final fuel in kFuelGrades)
                _FuelValue(dot: AppColors.fuel(fuel), name: fuel, value: '${formatThousands(sales.litresOf(fuel))} L'),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: AppColors.borderDivider)),
          Row(
            children: [
              for (final fuel in kFuelGrades)
                _RevenueValue(
                  name: '$fuel Rev',
                  value: 'PKR ${formatThousands(sales.litresOf(fuel) * pricePerLitre(fuel))}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  const PeriodCard({super.key, required this.sales});
}

class _FuelValue extends StatelessWidget {
  final Color dot;
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          _ScaleDownText(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
        ],
      ),
    );
  }

  const _FuelValue({required this.dot, required this.name, required this.value});
}

class _RevenueValue extends StatelessWidget {
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText)),
          _ScaleDownText(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandRed)),
        ],
      ),
    );
  }

  const _RevenueValue({required this.name, required this.value});
}

/// One line of text that shrinks to its column's width instead of wrapping
/// a figure such as "PKR 1,512,000" across two lines.
class _ScaleDownText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _ScaleDownText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text, maxLines: 1, style: style),
    );
  }
}

/// The sales report's chart, litres sold per grade (one color per grade):
/// grouped bars for Weekly and Monthly, a line per grade for Yearly. The
/// left axis shows compact litres ("20k") and a tap shows the exact figure
/// ("Petrol: 18,000 L").
class SalesBarChart extends StatelessWidget {
  final SalesReportPeriod period;
  final List<PeriodSales> data;

  String get _title => '${periodLabel(period)} Sales (litres)';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 10),
          if (data.isEmpty)
            const EmptyState('No sales recorded for this period yet.')
          else ...[
            SizedBox(
              height: 170,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final left = compactLeftTitles(context, _maxLitres);
                  // Every label that fits: on a narrow chart or with large
                  // text, Yearly's 12 would overlap, so some are skipped.
                  final stride = axisLabelStride(
                    context,
                    labels: [for (final d in data) chartAxisLabel(d.label)],
                    width: constraints.maxWidth - left.sideTitles.reservedSize,
                  );
                  return period == SalesReportPeriod.yearly ? _buildLineChart(left, stride) : _buildBarChart(left, stride);
                },
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final fuel in kFuelGrades) _LegendDot(color: AppColors.fuel(fuel), label: fuel),
              ],
            ),
          ],
        ],
      ),
    );
  }

  double get _maxLitres => data
      .expand((d) => [for (final fuel in kFuelGrades) d.litresOf(fuel)])
      .fold<double>(0, (a, b) => b > a ? b : a);

  /// Bottom labels: one per row, shortened ("W1"), skipping anything
  /// between rows. With a [stride] above 1 only every stride-th row is
  /// labelled, counting back from the newest, which always is.
  AxisTitles _bottomTitles(int stride) => AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            final i = value.round();
            if (value != i || i < 0 || i >= data.length) return const SizedBox.shrink();
            if ((data.length - 1 - i) % stride != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(chartAxisLabel(data[i].label), maxLines: 1, style: _axisStyle),
            );
          },
        ),
      );

  Widget _buildBarChart(AxisTitles leftTitles, int stride) {
    final axis = chartYAxis(_maxLitres);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: axis.maxY,
        gridData: _grid(axis.step),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: leftTitles,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: _bottomTitles(stride),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryText,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${kFuelGrades[rodIndex]}: ${formatThousands(rod.toY)} L',
              _tooltipStyle,
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                for (final fuel in kFuelGrades)
                  BarChartRodData(toY: data[i].litresOf(fuel), color: AppColors.fuel(fuel), width: 6),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLineChart(AxisTitles leftTitles, int stride) {
    final axis = chartYAxis(_maxLitres);

    LineChartBarData line(String fuel) => LineChartBarData(
          spots: [
            for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].litresOf(fuel)),
          ],
          isCurved: true,
          preventCurveOverShooting: true,
          color: AppColors.fuel(fuel),
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
        );

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: axis.maxY,
        gridData: _grid(axis.step),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: leftTitles,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          // interval: 1 (in _bottomTitles) puts a label on every month that
          // [stride] keeps, rather than fl_chart picking its own interval.
          bottomTitles: _bottomTitles(stride),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryText,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touched) => [
              for (final s in touched)
                LineTooltipItem('${kFuelGrades[s.barIndex]}: ${formatThousands(s.y)} L', _tooltipStyle),
            ],
          ),
        ),
        lineBarsData: [for (final fuel in kFuelGrades) line(fuel)],
      ),
    );
  }

  FlGridData _grid(double step) => FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: step,
        getDrawingHorizontalLine: (_) => FlLine(color: AppColors.borderDivider, strokeWidth: 1),
      );

  static const _tooltipStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white);

  const SalesBarChart({super.key, required this.period, required this.data});
}

const _axisStyle = TextStyle(fontSize: 10, color: AppColors.secondaryText);

/// A left axis for a chart whose highest point is [maxValue], labelled
/// every chartYAxis step with compact values ("20k", "1.5M"). Shared by
/// the report chart and the Dashboard's trend chart.
///
/// The column is as wide as the widest label at the system text size, so
/// larger text widens it rather than cutting labels short; were a label
/// still too wide, it shrinks to fit. Either way the unit stays: a clipped
/// "1.5M" would read "1.5", the wrong magnitude.
AxisTitles compactLeftTitles(BuildContext context, double maxValue) {
  final axis = chartYAxis(maxValue);
  final labels = [for (var v = 0.0; v <= axis.maxY; v += axis.step) formatCompact(v)];
  // Room for the widest label, plus the gap before the plot; never less
  // than the 34dp it has always had, nor more than a fifth of a phone.
  final reservedSize = (measureAxisLabels(context, labels) + 6).clamp(34.0, 72.0);
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      interval: axis.step,
      reservedSize: reservedSize,
      getTitlesWidget: (value, meta) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(formatCompact(value), maxLines: 1, style: _axisStyle),
        ),
      ),
    ),
  );
}

/// The width of the widest of [labels] drawn as an axis label at the
/// system text size (MediaQuery's text scaler).
double measureAxisLabels(BuildContext context, Iterable<String> labels) {
  final scaler = MediaQuery.textScalerOf(context);
  final style = DefaultTextStyle.of(context).style.merge(_axisStyle);
  var widest = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    widest = math.max(widest, painter.width);
    painter.dispose();
  }
  return widest;
}

/// How many rows each x-axis label must cover so that none overlap: 1
/// (label every row) when [labels] fit side by side across [width] at the
/// system text size, otherwise 2 (every other row), 3, ... The chart
/// passes its own width (from a LayoutBuilder) less the left axis.
int axisLabelStride(BuildContext context, {required List<String> labels, required double width}) {
  if (labels.isEmpty || width <= 0) return 1;
  // Each row's share of the width, and what one label needs: its text plus
  // a little air on either side.
  final perRow = width / labels.length;
  final needed = measureAxisLabels(context, labels) + 6;
  return math.max(1, (needed / perRow).ceil());
}

/// A short x-axis label for a report row: "Day 3" -> "D3", "Week 1" ->
/// "W1", "Month 12" -> "M12". Any other label is returned as it is.
String chartAxisLabel(String rowLabel) {
  final match = RegExp(r'^([A-Za-z])[A-Za-z]*\s+(\d+)$').firstMatch(rowLabel.trim());
  return match == null ? rowLabel : '${match.group(1)!.toUpperCase()}${match.group(2)}';
}

/// The y-axis for a chart whose highest point is [maxValue]: a round label
/// step (1, 2 or 5 times a power of ten, about four of them) and a top a
/// little above the highest point, on a step. Labels then read 0, 10k,
/// 20k, 30k rather than 0, 6,187.5, ...; an all-zero chart still gets a
/// usable range.
({double maxY, double step}) chartYAxis(double maxValue) {
  if (!maxValue.isFinite || maxValue <= 0) return (maxY: 1, step: 1);
  final rough = maxValue / 4;
  final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final fraction = rough / magnitude;
  final step = (fraction <= 1 ? 1.0 : fraction <= 2 ? 2.0 : fraction <= 5 ? 5.0 : 10.0) * magnitude;
  final maxY = step * (maxValue * 1.05 / step).ceil();
  return (maxY: maxY, step: step);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
      ],
    );
  }

  const _LegendDot({required this.color, required this.label});
}
