import 'package:flutter/material.dart';
import '../data/demo_sales.dart';
import '../models/nozzle.dart';
import '../models/sales.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';

/// Nozzles screen - the per-nozzle sales/status detail (fuel filter,
/// today's totals for the selected grade, live nozzle status list). No
/// chart here and no photo - that overview-level content belongs on the
/// Dashboard instead.
///
/// [nozzles] are THIS station's, every grade, from the session
/// (MainTabsFlow passes session.nozzlesFor) - the same list the Dashboard's
/// active/total count reads. Everything below the fuel chips follows the
/// selected grade: the sales card (today's litres from salesFor by
/// [stationId], revenue = litres × pricePerLitre, the same formula as the
/// Dashboard), the status counts and the nozzle cards.
class NozzlesScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  final List<Nozzle> nozzles;
  final ValueChanged<int> onNavTap;

  @override
  State<NozzlesScreen> createState() => _NozzlesScreenState();

  const NozzlesScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.nozzles,
    required this.onNavTap,
  });
}

class _NozzlesScreenState extends State<NozzlesScreen> {
  int _fuelIndex = 0; // Petrol selected

  @override
  Widget build(BuildContext context) {
    final fuelName = kFuelGrades[_fuelIndex];
    final nozzles = [
      for (final n in widget.nozzles)
        if (n.fuelName == fuelName) n,
    ];
    final litresToday = PeriodSales.sum(salesFor(widget.stationId, SalesReportPeriod.today)).litresOf(fuelName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(stationName: widget.stationName),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nozzle Sales',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        _TodayDropdown(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (final (i, fuel) in kFuelGrades.indexed) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _FuelChip(
                              label: fuel,
                              selected: _fuelIndex == i,
                              onTap: () => setState(() => _fuelIndex = i),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SalesCard(
                      fuelName: fuelName,
                      litres: litresToday,
                      revenue: litresToday * pricePerLitre(fuelName),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nozzle Status',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatusChips(nozzles: nozzles),
                    const SizedBox(height: 12),
                    if (nozzles.isEmpty) EmptyState('No $fuelName nozzles set up for this station yet.'),
                    for (final nozzle in nozzles) ...[
                      _NozzleCard(nozzle: nozzle),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: AppTab.nozzles, onTap: widget.onNavTap),
    );
  }
}

/// The brand, bell and avatar row (the same pieces as the Dashboard's
/// AppTopBar, without its menu and Help icons) over the station name.
class _Header extends StatelessWidget {
  final String stationName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.borderDivider)),
      ),
      child: Column(
        children: [
          const Padding(
            // Less on the right and above and below: the avatar's 48dp tap
            // target supplies that space itself.
            padding: EdgeInsets.fromLTRB(20, 4, 10, 0),
            child: Row(
              children: [
                Expanded(child: AppBrandMark()),
                NotificationBell(),
                // Profile isn't reachable from this tab yet, so the avatar
                // has nothing to open.
                ProfileAvatarButton(),
              ],
            ),
          ),
          StationRow(stationName: stationName, padding: const EdgeInsets.fromLTRB(20, 0, 20, 10)),
        ],
      ),
    );
  }

  const _Header({required this.stationName});
}

class _TodayDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
        SizedBox(width: 2),
        Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.secondaryText),
      ],
    );
  }

  const _TodayDropdown();
}

class _FuelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.redLightSelected : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.brandRed : AppColors.borderDivider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_gas_station_outlined,
              size: 16,
              color: selected ? AppColors.brandRed : AppColors.secondaryText,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? AppColors.brandRed : AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  const _FuelChip({required this.label, required this.selected, required this.onTap});
}

/// Today's litres and revenue for the selected grade.
class _SalesCard extends StatelessWidget {
  final String fuelName;
  final double litres;
  final double revenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: AppColors.brandRed, width: 4)),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$fuelName Sales (Today)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _StatBlock(label: 'Total Litres', value: '${formatThousands(litres)} L')),
              const SizedBox(width: 16),
              Expanded(child: _StatBlock(label: 'Total Revenue', value: 'PKR ${formatThousands(revenue)}')),
            ],
          ),
        ],
      ),
    );
  }

  const _SalesCard({required this.fuelName, required this.litres, required this.revenue});
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
        // Shrinks to its half of the card rather than wrapping the figure.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
        ),
      ],
    );
  }

  const _StatBlock({required this.label, required this.value});
}

/// How many of the selected grade's nozzles are in each state. Display
/// only: tapping a chip doesn't filter the list yet.
class _StatusChips extends StatelessWidget {
  final List<Nozzle> nozzles;

  @override
  Widget build(BuildContext context) {
    int count(NozzleStatus status) => nozzles.where((n) => n.status == status).length;

    Widget chip(String label, {bool active = false, Color? color}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.redLightSelected : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.brandRed : AppColors.borderDivider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: active ? AppColors.brandRed : (color ?? AppColors.secondaryText),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('All ${nozzles.length}', active: true),
        chip('Dispensing ${count(NozzleStatus.dispensing)}', color: AppColors.statusDispensing),
        chip('Idle ${count(NozzleStatus.idle)}'),
        chip('Faults ${count(NozzleStatus.fault)}', color: AppColors.statusFault),
      ],
    );
  }

  const _StatusChips({required this.nozzles});
}

/// "just now", "5 min ago", "2 h ago" - how long since the pump last
/// reported this nozzle.
String _timeAgo(DateTime t) {
  final elapsed = DateTime.now().difference(t);
  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
  return '${elapsed.inHours} h ago';
}

class _NozzleCard extends StatelessWidget {
  final Nozzle nozzle;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final Color iconBg;
    switch (nozzle.status) {
      case NozzleStatus.dispensing:
        statusColor = AppColors.statusDispensing;
        statusLabel = 'Dispensing';
        iconBg = AppColors.redLightSelected;
      case NozzleStatus.idle:
        statusColor = AppColors.statusIdle;
        statusLabel = 'Idle';
        iconBg = AppColors.background;
      case NozzleStatus.fault:
        statusColor = AppColors.statusFault;
        statusLabel = 'Fault';
        iconBg = AppColors.statusFault.withValues(alpha: 0.1);
    }
    final faulty = nozzle.status == NozzleStatus.fault;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        // A faulty nozzle is outlined in the fault color so it stands out
        // in the list, not just in its small status label.
        border: faulty ? Border.all(color: AppColors.statusFault.withValues(alpha: 0.5)) : null,
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(
              faulty ? Icons.error_outline : Icons.local_gas_station_outlined,
              color: faulty ? AppColors.statusFault : AppColors.brandRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nozzle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                  ],
                ),
                Text(nozzle.fuelName, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  children: [
                    _MetaText(bold: '${nozzle.litres.toStringAsFixed(2)} L', label: 'Litres'),
                    _MetaText(bold: '${nozzle.flowRate.toStringAsFixed(1)} L/min', label: 'Flow'),
                    Text(_timeAgo(nozzle.lastUpdated), style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  const _NozzleCard({required this.nozzle});
}

class _MetaText extends StatelessWidget {
  final String bold;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Text.rich, unlike RichText, follows the system text size.
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
        children: [
          TextSpan(text: '$bold ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryText)),
          TextSpan(text: label),
        ],
      ),
    );
  }

  const _MetaText({required this.bold, required this.label});
}
