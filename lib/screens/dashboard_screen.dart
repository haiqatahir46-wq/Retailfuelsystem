import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/wave_clipper.dart';
import 'sales_report_screens.dart';

class DashboardScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String userName;
  final String userEmail;
  final Widget? stationImage;
  final ValueChanged<int>? onQuickLinkTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onLocationTap;

  const DashboardScreen({
    super.key,
    required this.stationId,
    this.stationName = 'Amir Filling, Pattoki',
    this.userName = 'Haiqa Tahir',
    this.userEmail = 'haiqa@parco.example',
    this.stationImage,
    this.onQuickLinkTap,
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
  int _navIndex = 0; // Dashboard tab active
  SalesReportPeriod _period = SalesReportPeriod.today;

  static const _weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Everything below is scoped to widget.stationId ONLY - see salesFor()'s
  // doc comment in sales_report_screens.dart for why this matters: an
  // owner must never see another station's figures, whether it's their
  // own second station or (worse) a different owner's station entirely.
  StationSalesData? get _station => demoSalesByStation[widget.stationId];
  List<PeriodSales> get _periodData => salesFor(widget.stationId, _period);

  @override
  Widget build(BuildContext context) {
    // The photo banner only makes sense for Today - once Weekly/Monthly/
    // Yearly show their long scrollable list of periods, the photo would
    // just get scrolled away, same reasoning as the standalone Today Sale
    // screen in sales_report_screens.dart.
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
                              child: widget.stationImage ?? const _StationPlaceholder(),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              // The dropdown sits directly under the photo -
                              // same dropdown as the standalone sales
                              // report screens, picking a period actually
                              // swaps the content below, it isn't
                              // decorative.
                              PeriodDropdown(
                                period: _period,
                                label: periodLabel(_period),
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
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          widget.onQuickLinkTap?.call(i);
        },
      ),
    );
  }

  /// Today = the original Dashboard Overview: aggregate stat cards, the
  /// low-stock alert, the 7-day trend chart and the fuel breakdown - all
  /// computed from THIS station's own today entry via the shared litres ×
  /// price formula, never separate hand-typed numbers that could drift
  /// out of sync with (or leak) another station's figures.
  List<Widget> _buildTodayContent() {
    final station = _station;
    final today = _periodData.isNotEmpty ? _periodData.first : null;
    final totalLitres = today == null ? 0.0 : today.petrolL + today.dieselL + today.octaneL;
    final totalRevenue = today?.totalRevenue ?? 0.0;

    return [
      Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.swap_vert,
              value: 'PKR ${formatThousands(totalRevenue)}',
              label: 'Revenue Today',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.local_gas_station_outlined,
              value: '${formatThousands(totalLitres)} L',
              label: 'Litres Dispensed',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.access_time,
              value: station?.activePumps ?? '0 / 0',
              label: 'Active Pumps',
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      const _AlertBanner(
        text: 'Diesel tank is below reorder threshold (5,000 L left)',
        actionLabel: 'Reorder',
      ),
      const SizedBox(height: 14),
      _SalesTrendChart(values: station?.weekTrend ?? const [], labels: _weekLabels),
      const SizedBox(height: 20),
      const Text(
        'Fuel Breakdown',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _FuelMiniCard(
              dotColor: AppColors.brandRed,
              name: 'Petrol',
              litres: '${formatThousands(today?.petrolL ?? 0)} L',
              revenue: 'PKR ${formatThousands(today?.petrolRevenue ?? 0)}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FuelMiniCard(
              dotColor: AppColors.primaryText,
              name: 'Diesel',
              litres: '${formatThousands(today?.dieselL ?? 0)} L',
              revenue: 'PKR ${formatThousands(today?.dieselRevenue ?? 0)}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FuelMiniCard(
              dotColor: AppColors.statusDispensing,
              name: 'Hi-Octane',
              litres: '${formatThousands(today?.octaneL ?? 0)} L',
              revenue: 'PKR ${formatThousands(today?.octaneRevenue ?? 0)}',
            ),
          ),
        ],
      ),
    ];
  }

  /// Weekly/Monthly/Yearly = the same total-revenue card, per-period cards
  /// and bar/line chart already built (and working) for the standalone
  /// Weekly/Monthly/Yearly screens - reused here so the two never drift.
  List<Widget> _buildPeriodContent() {
    final data = _periodData;
    final totalRevenue = data.fold<double>(0, (sum, d) => sum + d.totalRevenue);

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

// AppTopBar and StationRow now live in ../widgets/app_top_bar.dart, shared
// with StockScreen (and any other main tab) instead of duplicated here.

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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
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
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String text;
  final String actionLabel;

  const _AlertBanner({required this.text, required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFBE3B8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.statusAttention, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF7A5A17)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            actionLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandRed),
          ),
        ],
      ),
    );
  }
}

/// 7-day aggregate sales trend, drawn with fl_chart's LineChart. Only shown
/// for the Today period - Weekly/Monthly/Yearly use SalesBarChart instead.
class _SalesTrendChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _SalesTrendChart({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Sales Trend (7 Days)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText),
              ),
              Text(
                '▲ 12.4%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.statusDispensing),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 40,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.borderDivider, strokeWidth: 1),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: true),
                minY: 0,
                maxY: 110,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.brandRed,
                    barWidth: 3,
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
                          AppColors.brandRed.withOpacity(0.18),
                          AppColors.brandRed.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map((d) => Text(d, style: const TextStyle(fontSize: 10, color: AppColors.secondaryText)))
                  .toList(),
            ),
          ),
        ],
      ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
            ],
          ),
          const SizedBox(height: 6),
          Text(litres, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
          const SizedBox(height: 2),
          Text(revenue, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
        ],
      ),
    );
  }
}

/// Shown when no real station photo has been supplied yet. To wire in the
/// real TOTAL PARCO photo, pass:
///   DashboardScreen(
///     stationImage: Image.asset(
///       'assets/images/station.webp',
///       fit: BoxFit.cover,
///       alignment: const Alignment(0, 0.2), // keep the canopy/signage in frame, not the sky
///     ),
///   )
class _StationPlaceholder extends StatelessWidget {
  const _StationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.redLightSelected,
      alignment: Alignment.center,
      child: const Icon(Icons.local_gas_station, size: 40, color: AppColors.brandRed),
    );
  }
}