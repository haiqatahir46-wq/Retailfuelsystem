// Requires fl_chart - see dashboard_screen.dart's header comment for the
// pubspec.yaml line to add. Same dependency, no extra package needed.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../data/demo_sales.dart';
import '../models/sales.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/wave_clipper.dart';

const dieselColor = AppColors.primaryText;
const octaneColor = AppColors.statusDispensing;

/// Today Sale screen. Same underlying implementation as WeeklySaleScreen,
/// MonthlySaleScreen and YearlySaleScreen - the "Today ▾" dropdown at the
/// top switches between all four without leaving the screen.
///
/// [stationId] is REQUIRED and scopes every figure on this screen to that
/// one station - it must be the id of a station the signed-in owner
/// actually owns (e.g. from SelectStationScreen's `selectedStationId`).
/// Never pass a hardcoded or user-suppliable id from outside the owner's
/// own station list.
class TodaySaleScreen extends StatelessWidget {
  final String stationId;
  final Widget? stationImage;

  @override
  Widget build(BuildContext context) => _SalesReportScreen(
        stationId: stationId,
        initialPeriod: SalesReportPeriod.today,
        stationImage: stationImage,
      );

  const TodaySaleScreen({super.key, required this.stationId, this.stationImage});
}

class WeeklySaleScreen extends StatelessWidget {
  final String stationId;

  @override
  Widget build(BuildContext context) =>
      _SalesReportScreen(stationId: stationId, initialPeriod: SalesReportPeriod.weekly);

  const WeeklySaleScreen({super.key, required this.stationId});
}

class MonthlySaleScreen extends StatelessWidget {
  final String stationId;

  @override
  Widget build(BuildContext context) =>
      _SalesReportScreen(stationId: stationId, initialPeriod: SalesReportPeriod.monthly);

  const MonthlySaleScreen({super.key, required this.stationId});
}

class YearlySaleScreen extends StatelessWidget {
  final String stationId;

  @override
  Widget build(BuildContext context) =>
      _SalesReportScreen(stationId: stationId, initialPeriod: SalesReportPeriod.yearly);

  const YearlySaleScreen({super.key, required this.stationId});
}

class _SalesReportScreen extends StatefulWidget {
  final String stationId;
  final SalesReportPeriod initialPeriod;
  final Widget? stationImage;

  @override
  State<_SalesReportScreen> createState() => _SalesReportScreenState();

  const _SalesReportScreen({required this.stationId, required this.initialPeriod, this.stationImage});
}

class _SalesReportScreenState extends State<_SalesReportScreen> {
  late SalesReportPeriod _period = widget.initialPeriod;
  int _navIndex = 0; // Dashboard tab - same navbar as the Dashboard screen

  String get _title {
    switch (_period) {
      case SalesReportPeriod.today:
        return 'Today Sale';
      case SalesReportPeriod.weekly:
        return 'Weekly Sale';
      case SalesReportPeriod.monthly:
        return 'Monthly Sale';
      case SalesReportPeriod.yearly:
        return 'Yearly Sale';
    }
  }

  // Scoped to THIS station only - see salesFor()'s doc comment above.
  List<PeriodSales> get _data => salesFor(widget.stationId, _period);

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _data.fold<double>(0, (sum, d) => sum + d.totalRevenue);

    // The Today view gets a station-photo banner (same WaveClipper as the
    // splash/login/signup screens) - it's a single, light-content screen so
    // there's room for it. Weekly/Monthly/Yearly stay plain: a photo above
    // a long scrollable list of periods would just get scrolled away.
    final showPhoto = _period == SalesReportPeriod.today;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (showPhoto)
              SizedBox(
                height: 150,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: AppColors.cardBackground),
                  child: ClipPath(
                    clipper: const WaveClipper(),
                    child: SizedBox.expand(
                      child: widget.stationImage ?? const _StationPlaceholder(),
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(bottom: BorderSide(color: AppColors.borderDivider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                  // ONE dropdown for Today / Weekly / Monthly / Yearly -
                  // picking an option switches the whole screen's content.
                  PeriodDropdown(
                    period: _period,
                    label: periodLabel(_period),
                    onChanged: (p) => setState(() => _period = p),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                itemCount: _data.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TotalRevenueCard(label: periodLabel(_period), total: 'PKR ${formatThousands(totalRevenue)}'),
                    );
                  }
                  final dataIndex = index - 1;
                  if (dataIndex == _data.length) {
                    return SalesBarChart(period: _period, data: _data);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PeriodCard(sales: _data[dataIndex]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

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
        boxShadow: [BoxShadow(color: AppColors.brandRed.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Revenue · $label',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          Text(
            total,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  const TotalRevenueCard({super.key, required this.label, required this.total});
}

/// The single dropdown that replaces the old segmented tab control -
/// tapping it opens a menu of all four periods; picking one switches the
/// whole screen in place.
class PeriodDropdown extends StatelessWidget {
  final SalesReportPeriod period;
  final String label;
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
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  const PeriodDropdown({super.key, required this.period, required this.label, required this.onChanged});
}

class PeriodCard extends StatelessWidget {
  final PeriodSales sales;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
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
              _FuelValue(dot: AppColors.brandRed, name: 'Petrol', value: '${formatThousands(sales.petrolL)} L'),
              _FuelValue(dot: dieselColor, name: 'Diesel', value: '${formatThousands(sales.dieselL)} L'),
              _FuelValue(dot: octaneColor, name: 'Hi-Octane', value: '${formatThousands(sales.octaneL)} L'),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: AppColors.borderDivider)),
          Row(
            children: [
              _RevenueValue(name: 'Petrol Rev', value: 'PKR ${formatThousands(sales.petrolRevenue)}'),
              _RevenueValue(name: 'Diesel Rev', value: 'PKR ${formatThousands(sales.dieselRevenue)}'),
              _RevenueValue(name: 'Hi-Octane Rev', value: 'PKR ${formatThousands(sales.octaneRevenue)}'),
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
              Text(name, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
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
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandRed)),
        ],
      ),
    );
  }

  const _RevenueValue({required this.name, required this.value});
}

/// Grouped bar chart (weekly/monthly) or line chart (yearly), built with
/// fl_chart, one series per fuel grade.
class SalesBarChart extends StatelessWidget {
  final SalesReportPeriod period;
  final List<PeriodSales> data;

  String _graphTitle(SalesReportPeriod p) {
    switch (p) {
      case SalesReportPeriod.today:
        return "Today's Graph";
      case SalesReportPeriod.weekly:
        return 'Weekly Graph';
      case SalesReportPeriod.monthly:
        return 'Monthly Graph';
      case SalesReportPeriod.yearly:
        return 'Yearly Graph';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _graphTitle(period),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: period == SalesReportPeriod.yearly ? _buildLineChart() : _buildBarChart(),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _LegendDot(color: AppColors.brandRed, label: 'Petrol'),
              SizedBox(width: 14),
              _LegendDot(color: dieselColor, label: 'Diesel'),
              SizedBox(width: 14),
              _LegendDot(color: octaneColor, label: 'Hi-Octane'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxVal = data
        .expand((d) => [d.petrolL, d.dieselL, d.octaneL])
        .fold<double>(0, (a, b) => b > a ? b : a);

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.borderDivider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[i].label.split(' ').last,
                    style: const TextStyle(fontSize: 10, color: AppColors.secondaryText),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(toY: data[i].petrolL, color: AppColors.brandRed, width: 6),
                BarChartRodData(toY: data[i].dieselL, color: dieselColor, width: 6),
                BarChartRodData(toY: data[i].octaneL, color: octaneColor, width: 6),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    List<FlSpot> spotsFor(double Function(PeriodSales) pick) => [
          for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), pick(data[i])),
        ];

    LineChartBarData line(List<FlSpot> spots, Color color) => LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
        );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.borderDivider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[i].label.split(' ').last,
                    style: const TextStyle(fontSize: 10, color: AppColors.secondaryText),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          line(spotsFor((d) => d.petrolL), AppColors.brandRed),
          line(spotsFor((d) => d.dieselL), dieselColor),
          line(spotsFor((d) => d.octaneL), octaneColor),
        ],
      ),
    );
  }

  const SalesBarChart({super.key, required this.period, required this.data});
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

/// Placeholder used on the Today view until a real station photo is
/// passed in via TodaySaleScreen(stationImage: ...).
class _StationPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB0141A), AppColors.brandRed],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_gas_station,
          size: 48,
          color: Colors.white.withOpacity(0.25),
        ),
      ),
    );
  }

  const _StationPlaceholder();
}
