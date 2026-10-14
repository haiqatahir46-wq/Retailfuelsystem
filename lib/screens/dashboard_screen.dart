import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../data/demo_sales.dart';
import '../models/nozzle.dart';
import '../models/sales.dart';
import '../models/tank_stock.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/tank_health_style.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/sales_report_widgets.dart';
import '../widgets/station_photo.dart';
import '../widgets/wave_clipper.dart';

/// The Dashboard tab: today's overview (or a Weekly/Monthly/Yearly sales
/// report) for one station.
///
/// [tanks] and [nozzles] are this station's, from the session
/// (MainTabsFlow passes session.tanksFor / session.nozzlesFor), so the
/// Dashboard agrees with Stock, Tanks and Nozzles: [nozzles] gives the
/// Active Nozzles count and [tanks] the low-stock alert, which lists every
/// tank that isn't healthy and opens Stock (via [onNavTap]) to reorder.
/// The sales figures are looked up by [stationId] with salesFor.
class DashboardScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String userName;
  final String userEmail;
  final List<TankStock> tanks;
  final List<Nozzle> nozzles;
  final Widget? stationImage;
  final ValueChanged<int> onNavTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onLocationTap;

  const DashboardScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.userName,
    required this.userEmail,
    required this.tanks,
    required this.nozzles,
    required this.onNavTap,
    this.stationImage,
    this.onProfileTap,
    this.onHelpCenterTap,
    this.onSettingsTap,
    this.onLogoutTap,
    this.onLocationTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SalesReportPeriod _period = SalesReportPeriod.today;

  // Everything below is scoped to widget.stationId ONLY - see salesFor()'s
  // doc comment in demo_sales.dart for why this matters: an owner must
  // never see another station's figures, whether it's their own second
  // station or (worse) a different owner's station entirely.
  List<PeriodSales> get _periodData => salesFor(widget.stationId, _period);

  @override
  Widget build(BuildContext context) {
    // The photo banner only makes sense for Today - once Weekly/Monthly/
    // Yearly show their long scrollable list of periods, the photo would
    // just get scrolled away.
    final showPhoto = _period == SalesReportPeriod.today;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        userName: widget.userName,
        userEmail: widget.userEmail,
        onProfileTap: widget.onProfileTap,
        onHelpCenterTap: widget.onHelpCenterTap,
        onSettingsTap: widget.onSettingsTap,
        onLogoutTap: widget.onLogoutTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Fixed top bar - stays above the photo at all times, so
            // hamburger/Help Center/Profile/notifications are always
            // reachable without scrolling. Help Center and Profile are
            // real working icons here, not just entries buried in the
            // hamburger drawer.
            AppTopBar(
              onHelpCenterTap: widget.onHelpCenterTap,
              onProfileTap: widget.onProfileTap,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showPhoto)
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(color: AppColors.cardBackground),
                          child: ClipPath(
                            clipper: const WaveClipper(),
                            child: SizedBox.expand(
                              child: widget.stationImage ?? const StationPhoto(),
                            ),
                          ),
                        ),
                      ),
                    StationRow(stationName: widget.stationName, onTap: widget.onLocationTap),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Overview',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ),
                              // The dropdown heads the content it controls
                              // (under the photo and the station row):
                              // picking a period swaps everything below,
                              // it isn't decorative.
                              PeriodDropdown(
                                period: _period,
                                onChanged: (p) => setState(() => _period = p),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_period == SalesReportPeriod.today) ..._buildTodayContent() else ..._buildPeriodContent(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: AppTab.dashboard, onTap: widget.onNavTap),
    );
  }

  /// Today = the original Dashboard Overview: aggregate stat cards, the
  /// low-stock alert, the 7-day trend chart and the fuel breakdown - all
  /// computed from THIS station's own today rows (combined with
  /// PeriodSales.sum, the same way the tank levels and the Today report
  /// add them up) via the shared litres × price formula, never separate
  /// hand-typed numbers that could drift out of sync with (or leak)
  /// another station's figures. The active count comes from the same
  /// nozzle list the Nozzles tab shows ([DashboardScreen.nozzles]), and the
  /// alert from the same tanks Stock shows ([DashboardScreen.tanks]).
  List<Widget> _buildTodayContent() {
    final today = PeriodSales.sum(_periodData, label: 'Today');
    final nozzles = widget.nozzles;
    final dispensing = nozzles.where((n) => n.status == NozzleStatus.dispensing).length;
    // Critical before low, so the worst tank comes first and sets the
    // banner's color.
    final lowTanks = [
      for (final health in [TankHealth.critical, TankHealth.low])
        ...widget.tanks.where((t) => t.health == health),
    ];

    // "PKR" goes in the caption, not the figure: "1,512,000" alone keeps a
    // readable size in a third of the width, where "PKR 1,512,000" shrank
    // smaller than its own caption.
    final revenue = _StatCard(
      icon: Icons.swap_vert,
      value: formatThousands(today.totalRevenue),
      label: 'Revenue Today (PKR)',
    );
    final litres = _StatCard(
      icon: Icons.local_gas_station_outlined,
      value: '${formatThousands(today.totalLitres)} L',
      label: 'Litres Dispensed',
    );
    final active = _StatCard(
      icon: Icons.access_time,
      value: '$dispensing / ${nozzles.length}',
      label: 'Active Nozzles',
    );

    return [
      // Three cards side by side. Below about 360dp of screen (320 inside
      // the page padding) a third is too narrow: the figures would shrink
      // smaller than their captions, so Revenue Today takes a row of its
      // own and the other two share the next.
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 320) return _StatRow(cards: [revenue, litres, active]);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [revenue, const SizedBox(height: 10), _StatRow(cards: [litres, active])],
          );
        },
      ),
      if (lowTanks.isNotEmpty) ...[
        const SizedBox(height: 14),
        // Create Reorder lives on Stock, so that's where the alert goes.
        _LowStockBanner(tanks: lowTanks, onTap: () => widget.onNavTap(AppTab.stock)),
      ],
      const SizedBox(height: 14),
      SalesTrendChart(rows: salesFor(widget.stationId, SalesReportPeriod.weekly)),
      const SizedBox(height: 20),
      const Text(
        'Fuel Breakdown',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
      ),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, fuel) in kFuelGrades.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _FuelMiniCard(
                  dotColor: AppColors.fuel(fuel),
                  name: fuel,
                  litres: '${formatThousands(today.litresOf(fuel))} L',
                  revenue: 'PKR ${formatThousands(today.litresOf(fuel) * pricePerLitre(fuel))}',
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  /// Weekly/Monthly/Yearly: the total-revenue card, one card per period
  /// row and the chart (lib/widgets/sales_report_widgets.dart).
  List<Widget> _buildPeriodContent() {
    final data = _periodData;
    final totalRevenue = PeriodSales.sum(data).totalRevenue;

    return [
      TotalRevenueCard(label: periodLabel(_period), total: 'PKR ${formatThousands(totalRevenue)}'),
      const SizedBox(height: 10),
      for (final d in data)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PeriodCard(sales: d),
        ),
      SalesBarChart(period: _period, data: data),
    ];
  }
}

/// Stat cards sharing a row equally. IntrinsicHeight + stretch: they stay
/// one height even when one caption wraps to a second line.
class _StatRow extends StatelessWidget {
  final List<Widget> cards;

  const _StatRow({required this.cards});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, card) in cards.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: card),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: AppColors.redLightSelected, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: AppColors.brandRed),
          ),
          // A third of a phone's width is tight for "1,512,000", so the
          // figure shrinks to fit rather than wrapping or overflowing.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
        ],
      ),
    );
  }
}

/// The low-stock alert: one line per tank below its reorder threshold,
/// e.g. "Petrol is critical: 7,000 L left (threshold 18,000 L)". [tanks]
/// come worst first, and the first one's health colors the banner. The
/// whole banner, "Reorder" included, is one tap target for [onTap].
class _LowStockBanner extends StatelessWidget {
  final List<TankStock> tanks;
  final VoidCallback onTap;

  const _LowStockBanner({required this.tanks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = tanks.first.health.color;
    final radius = BorderRadius.circular(12);

    return Material(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: color.withValues(alpha: 0.35))),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, tank) in tanks.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
                        child: Text(
                          '${tank.fuelName} is ${tank.health.label.toLowerCase()}: '
                          '${formatThousands(tank.currentVolume)} L left '
                          '(threshold ${formatThousands(tank.threshold)} L)',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Reorder',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandRed),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.brandRed),
            ],
          ),
        ),
      ),
    );
  }
}

/// 7-day revenue trend, drawn with fl_chart's LineChart. Only shown for the
/// Today period - Weekly/Monthly/Yearly use SalesBarChart instead.
///
/// Built straight from the station's weekly sales rows (one point per row,
/// its totalRevenue), so the line, the change badge and the axis labels
/// always match the Weekly report rather than a separately typed series.
/// The rows run oldest -> newest (see StationSalesData), so the last point
/// is today: it gets the end dot, it equals "Revenue Today" above it, and
/// the badge is the change from the first day to today.
///
/// Public only so tests can pump it with rows of their own (one row, a
/// first day of 0, none at all); the Dashboard is its one real user.
class SalesTrendChart extends StatelessWidget {
  final List<PeriodSales> rows;

  const SalesTrendChart({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final values = [for (final r in rows) r.totalRevenue];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Sales Trend (PKR, 7 Days)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                ),
              ),
              const SizedBox(width: 8),
              ?_changeBadge(values),
            ],
          ),
          const SizedBox(height: 8),
          if (values.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No sales recorded this week yet.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final left = compactLeftTitles(context, values.reduce((a, b) => a > b ? a : b));
                  // Skips every other day's label when they wouldn't fit
                  // side by side (a narrow phone with large text).
                  final stride = axisLabelStride(
                    context,
                    labels: [for (final r in rows) chartAxisLabel(r.label)],
                    width: constraints.maxWidth - left.sideTitles.reservedSize,
                  );
                  return LineChart(_chartData(values, left, stride));
                },
              ),
            ),
        ],
      ),
    );
  }

  /// "▲ 12.4%" (green) or "▼ 3.1%" (red): the change from the first
  /// (oldest) point to the last (today). Null - so nothing is shown - when
  /// there aren't two points to compare or the first is 0 (no meaningful
  /// percentage).
  Widget? _changeBadge(List<double> values) {
    if (values.length < 2 || values.first == 0) return null;
    final change = (values.last - values.first) / values.first * 100;
    final up = change >= 0;
    return Text(
      '${up ? '▲' : '▼'} ${change.abs().toStringAsFixed(1)}%',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: up ? AppColors.statusDispensing : AppColors.statusFault,
      ),
    );
  }

  LineChartData _chartData(List<double> values, AxisTitles leftTitles, int stride) {
    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    // Round steps with a little headroom, so the line and its end dot never
    // touch the top edge; all-zero data still gets a non-zero range.
    final axis = chartYAxis(values.reduce((a, b) => a > b ? a : b));

    return LineChartData(
      minY: 0,
      maxY: axis.maxY,
      // A little padding either side, so the first and last labels sit
      // fully under their points instead of hanging off the card.
      minX: -0.3,
      maxX: values.length - 1 + 0.3,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: axis.step,
        getDrawingHorizontalLine: (_) => FlLine(color: AppColors.borderDivider, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: leftTitles,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              // Only whole x values are data points; skip the padding edges,
              // and every day [stride] leaves out (counting back from today,
              // which is always labelled).
              final i = value.round();
              if (value != i || i < 0 || i >= rows.length) return const SizedBox.shrink();
              if ((rows.length - 1 - i) % stride != 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  chartAxisLabel(rows[i].label),
                  maxLines: 1,
                  style: const TextStyle(fontSize: 10, color: AppColors.secondaryText),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.primaryText,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touched) => [
            for (final s in touched)
              LineTooltipItem(
                '${rows[s.spotIndex].label}: PKR ${formatThousands(s.y)}',
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              ),
          ],
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          // Keeps the curve from overshooting below 0 or above a peak
          // between points, so it never suggests a value that wasn't there.
          preventCurveOverShooting: true,
          color: AppColors.brandRed,
          barWidth: 3,
          // One dot, on the newest point (today).
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: index == spots.length - 1 ? 4 : 0,
              color: AppColors.brandRed,
              strokeWidth: 0,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.brandRed.withValues(alpha: 0.18),
                AppColors.brandRed.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FuelMiniCard extends StatelessWidget {
  final Color dotColor;
  final String name;
  final String litres;
  final String revenue;

  const _FuelMiniCard({
    required this.dotColor,
    required this.name,
    required this.litres,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Figures shrink to the card's width instead of wrapping.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              litres,
              maxLines: 1,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(revenue, maxLines: 1, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
          ),
        ],
      ),
    );
  }
}
