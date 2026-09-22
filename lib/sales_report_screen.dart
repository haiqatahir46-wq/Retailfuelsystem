import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/bottom_nav.dart';
import 'package:petrolpump_flutter/wave_clipper.dart';

enum SalesReportPeriod { today, weekly, monthly, yearly }

// ---- The pricing model. Revenue is ALWAYS derived from litres - never
// stored as a separate number - so it can never drift out of sync with
// the litres it's supposed to represent. Swap these for real per-station
// prices (e.g. from FMS-06's price_history) when wiring up live data. ----
const kPetrolPricePerLitre = 50.0; // PKR/L
const kDieselPricePerLitre = 48.0; // PKR/L
const kHiOctanePricePerLitre = 60.0; // PKR/L

/// One row of sales data for a period (a day, a week, or a month) - litres
/// only. Revenue is computed on demand via the getters below:
/// revenue = litres × price per litre, the same formula as the FYP
/// proposal's business rules ("Sale amount = liters sold × selling price
/// per liter").
class PeriodSales {
  final String label;
  final double petrolL;
  final double dieselL;
  final double octaneL;

  const PeriodSales({
    required this.label,
    required this.petrolL,
    required this.dieselL,
    required this.octaneL,
  });

  double get petrolRevenue => petrolL * kPetrolPricePerLitre;
  double get dieselRevenue => dieselL * kDieselPricePerLitre;
  double get octaneRevenue => octaneL * kHiOctanePricePerLitre;
  double get totalRevenue => petrolRevenue + dieselRevenue + octaneRevenue;
}

const dieselColor = AppColors.primaryText;
const octaneColor = AppColors.statusDispensing;

/// 'Today', 'Weekly', 'Monthly' or 'Yearly' - shared by the sales report
/// screens and the Dashboard's own period dropdown.
String periodLabel(SalesReportPeriod p) {
  switch (p) {
    case SalesReportPeriod.today:
      return 'Today';
    case SalesReportPeriod.weekly:
      return 'Weekly';
    case SalesReportPeriod.monthly:
      return 'Monthly';
    case SalesReportPeriod.yearly:
      return 'Yearly';
  }
}

/// Adds thousands separators, e.g. 1512000 -> "1,512,000".
String formatThousands(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );

// ---- Per-station demo data. This is the core rule of the whole sales
// module: an owner must ONLY ever see the figures for the station(s) they
// own - never another owner's station, never a company-wide total unless
// they explicitly own every station in it. This map simulates that
// scoping on the client by keying every period's data on stationId. In
// production the authoritative filter MUST live in the backend query
// (e.g. `WHERE station_id = :id AND owner_id = :currentUser`) and be
// enforced server-side - a client that only *displays* the right data
// but queries an API that returns everyone's data is not actually
// secure, since the raw response could still be read from the network. ----

class StationSalesData {
  final List<PeriodSales> today;
  final List<PeriodSales> weekly;
  final List<PeriodSales> monthly;
  final List<PeriodSales> yearly;
  final List<double> weekTrend; // for the Dashboard's 7-day trend chart
  final String activePumps; // e.g. '8 / 12'

  const StationSalesData({
    required this.today,
    required this.weekly,
    required this.monthly,
    required this.yearly,
    required this.weekTrend,
    required this.activePumps,
  });

  List<PeriodSales> forPeriod(SalesReportPeriod period) {
    switch (period) {
      case SalesReportPeriod.today:
        return today;
      case SalesReportPeriod.weekly:
        return weekly;
      case SalesReportPeriod.monthly:
        return monthly;
      case SalesReportPeriod.yearly:
        return yearly;
    }
  }
}

const demoSalesByStation = <String, StationSalesData>{
  'station-1': StationSalesData(
    activePumps: '8 / 12',
    weekTrend: [40, 62, 52, 78, 74, 95, 100],
    today: [
      PeriodSales(label: 'Today', petrolL: 18000, dieselL: 9000, octaneL: 3000),
    ],
    weekly: [
      PeriodSales(label: 'Day 1', petrolL: 18000, dieselL: 9000, octaneL: 3000),
      PeriodSales(label: 'Day 2', petrolL: 18000, dieselL: 9000, octaneL: 3000),
      PeriodSales(label: 'Day 3', petrolL: 17200, dieselL: 8600, octaneL: 2800),
      PeriodSales(label: 'Day 4', petrolL: 19500, dieselL: 9400, octaneL: 3100),
      PeriodSales(label: 'Day 5', petrolL: 19000, dieselL: 9200, octaneL: 3050),
      PeriodSales(label: 'Day 6', petrolL: 21000, dieselL: 9800, octaneL: 3300),
      PeriodSales(label: 'Day 7', petrolL: 22500, dieselL: 10200, octaneL: 3600),
    ],
    monthly: [
      PeriodSales(label: 'Week 1', petrolL: 126000, dieselL: 63000, octaneL: 21000),
      PeriodSales(label: 'Week 2', petrolL: 131000, dieselL: 65000, octaneL: 21800),
      PeriodSales(label: 'Week 3', petrolL: 128500, dieselL: 64200, octaneL: 21500),
      PeriodSales(label: 'Week 4', petrolL: 138000, dieselL: 67800, octaneL: 22900),
    ],
    yearly: [
      PeriodSales(label: 'Month 1', petrolL: 523500, dieselL: 260000, octaneL: 87200),
      PeriodSales(label: 'Month 2', petrolL: 498000, dieselL: 247500, octaneL: 83400),
      PeriodSales(label: 'Month 3', petrolL: 541000, dieselL: 268800, octaneL: 90600),
      PeriodSales(label: 'Month 4', petrolL: 556200, dieselL: 276000, octaneL: 93100),
      PeriodSales(label: 'Month 5', petrolL: 562000, dieselL: 279500, octaneL: 94200),
      PeriodSales(label: 'Month 6', petrolL: 578000, dieselL: 287800, octaneL: 97000),
      PeriodSales(label: 'Month 7', petrolL: 591500, dieselL: 294200, octaneL: 99200),
      PeriodSales(label: 'Month 8', petrolL: 585000, dieselL: 291000, octaneL: 98100),
      PeriodSales(label: 'Month 9', petrolL: 602000, dieselL: 299500, octaneL: 101000),
      PeriodSales(label: 'Month 10', petrolL: 615500, dieselL: 306200, octaneL: 103400),
      PeriodSales(label: 'Month 11', petrolL: 609000, dieselL: 303000, octaneL: 102300),
      PeriodSales(label: 'Month 12', petrolL: 628000, dieselL: 312500, octaneL: 105600),
    ],
  ),
  // A second station under the same owner (or a different owner entirely)
  // with its own, completely separate figures - proof that the numbers
  // really do change per station rather than being one shared global set.
  'station-2': StationSalesData(
    activePumps: '5 / 8',
    weekTrend: [30, 42, 38, 55, 50, 68, 72],
    today: [
      PeriodSales(label: 'Today', petrolL: 9000, dieselL: 4500, octaneL: 1500),
    ],
    weekly: [
      PeriodSales(label: 'Day 1', petrolL: 9000, dieselL: 4500, octaneL: 1500),
      PeriodSales(label: 'Day 2', petrolL: 9200, dieselL: 4600, octaneL: 1550),
      PeriodSales(label: 'Day 3', petrolL: 8600, dieselL: 4300, octaneL: 1400),
      PeriodSales(label: 'Day 4', petrolL: 9700, dieselL: 4700, octaneL: 1550),
      PeriodSales(label: 'Day 5', petrolL: 9500, dieselL: 4600, octaneL: 1525),
      PeriodSales(label: 'Day 6', petrolL: 10500, dieselL: 4900, octaneL: 1650),
      PeriodSales(label: 'Day 7', petrolL: 11200, dieselL: 5100, octaneL: 1800),
    ],
    monthly: [
      PeriodSales(label: 'Week 1', petrolL: 63000, dieselL: 31500, octaneL: 10500),
      PeriodSales(label: 'Week 2', petrolL: 65500, dieselL: 32500, octaneL: 10900),
      PeriodSales(label: 'Week 3', petrolL: 64000, dieselL: 32000, octaneL: 10750),
      PeriodSales(label: 'Week 4', petrolL: 69000, dieselL: 34000, octaneL: 11450),
    ],
    yearly: [
      PeriodSales(label: 'Month 1', petrolL: 261500, dieselL: 130000, octaneL: 43600),
      PeriodSales(label: 'Month 2', petrolL: 249000, dieselL: 123500, octaneL: 41700),
      PeriodSales(label: 'Month 3', petrolL: 270500, dieselL: 134400, octaneL: 45300),
      PeriodSales(label: 'Month 4', petrolL: 278000, dieselL: 138000, octaneL: 46550),
      PeriodSales(label: 'Month 5', petrolL: 281000, dieselL: 139500, octaneL: 47100),
      PeriodSales(label: 'Month 6', petrolL: 289000, dieselL: 143900, octaneL: 48500),
      PeriodSales(label: 'Month 7', petrolL: 295500, dieselL: 147000, octaneL: 49600),
      PeriodSales(label: 'Month 8', petrolL: 292500, dieselL: 145500, octaneL: 49050),
      PeriodSales(label: 'Month 9', petrolL: 301000, dieselL: 149500, octaneL: 50500),
      PeriodSales(label: 'Month 10', petrolL: 307500, dieselL: 153000, octaneL: 51700),
      PeriodSales(label: 'Month 11', petrolL: 304500, dieselL: 151500, octaneL: 51150),
      PeriodSales(label: 'Month 12', petrolL: 314000, dieselL: 156500, octaneL: 52800),
    ],
  ),
};

/// Looks up ONE station's data for a period. Returns an empty list (never
/// another station's numbers) for an unrecognized id - e.g. a station
/// that was just added and has no sales history yet.
List<PeriodSales> salesFor(String stationId, SalesReportPeriod period) =>
    demoSalesByStation[stationId]?.forPeriod(period) ?? const [];

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
  const TodaySaleScreen({super.key, required this.stationId, this.stationImage});

  @override
  Widget build(BuildContext context) => _SalesReportScreen(
        stationId: stationId,
        initialPeriod: SalesReportPeriod.today,
        stationImage: stationImage,
      );
}

class WeeklySaleScreen extends StatelessWidget {
  final String stationId;
  const WeeklySaleScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) =>
      _SalesReportScreen(stationId: stationId, initialPeriod: SalesReportPeriod.weekly);
}

class MonthlySaleScreen extends StatelessWidget {
  final String stationId;
  const MonthlySaleScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) =>
      _SalesReportScreen(stationId: stationId, initialPeriod: SalesReportPeriod.monthly);
}

class YearlySaleScreen extends StatelessWidget {
  final String stationId;
  const YearlySaleScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) =>
      _SalesReportScreen(stationId: stationId, initialPeriod: SalesReportPeriod.yearly);
}

class _SalesReportScreen extends StatefulWidget {
  final String stationId;
  final SalesReportPeriod initialPeriod;
  final Widget? stationImage;
  const _SalesReportScreen({required this.stationId, required this.initialPeriod, this.stationImage});

  @override
  State<_SalesReportScreen> createState() => _SalesReportScreenState();
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
  const TotalRevenueCard({super.key, required this.label, required this.total});

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
}

/// The single dropdown that replaces the old segmented tab control -
/// tapping it opens a menu of all four periods; picking one switches the
/// whole screen in place.
class PeriodDropdown extends StatelessWidget {
  final SalesReportPeriod period;
  final String label;
  final ValueChanged<SalesReportPeriod> onChanged;

  const PeriodDropdown({super.key, required this.period, required this.label, required this.onChanged});

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
}

class PeriodCard extends StatelessWidget {
  final PeriodSales sales;

  const PeriodCard({super.key, required this.sales});

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
}

class _FuelValue extends StatelessWidget {
  final Color dot;
  final String name;
  final String value;

  const _FuelValue({required this.dot, required this.name, required this.value});

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
}

class _RevenueValue extends StatelessWidget {
  final String name;
  final String value;
  const _RevenueValue({required this.name, required this.value});

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
}

/// Grouped bar chart (weekly/monthly) or line chart (yearly), built with
/// fl_chart, one series per fuel grade.
class SalesBarChart extends StatelessWidget {
  final SalesReportPeriod period;
  final List<PeriodSales> data;

  const SalesBarChart({super.key, required this.period, required this.data});

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
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

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
}

/// Placeholder used on the Today view until a real station photo is
/// passed in via TodaySaleScreen(stationImage: ...).
class _StationPlaceholder extends StatelessWidget {
  const _StationPlaceholder();

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
}
