import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';

/// Nozzles screen - the per-nozzle sales/status detail (fuel filter,
/// today's Petrol totals, live nozzle status list). No chart here and no
/// photo - that overview-level content belongs on the Dashboard instead.
/// The nozzle list length/content is per-station, wired up from real data
/// later; this is the layout + styling.
class NozzlesScreen extends StatefulWidget {
  final String stationName;
  final ValueChanged<int>? onNavTap;

  @override
  State<NozzlesScreen> createState() => _NozzlesScreenState();

  const NozzlesScreen({
    super.key,
    this.stationName = 'Amir Filling, Pattoki',
    this.onNavTap,
  });
}

class _NozzlesScreenState extends State<NozzlesScreen> {
  int _navIndex = 1; // Nozzles tab active
  int _fuelIndex = 0; // Petrol selected

  @override
  Widget build(BuildContext context) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Nozzle Sales',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        _TodayDropdown(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _FuelChip(
                            label: 'Petrol',
                            selected: _fuelIndex == 0,
                            onTap: () => setState(() => _fuelIndex = 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FuelChip(
                            label: 'Diesel',
                            selected: _fuelIndex == 1,
                            onTap: () => setState(() => _fuelIndex = 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FuelChip(
                            label: 'Hi-Octane',
                            selected: _fuelIndex == 2,
                            onTap: () => setState(() => _fuelIndex = 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _SalesCard(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Nozzle Status',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
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
                    const _StatusChips(),
                    const SizedBox(height: 12),
                    const _NozzleCard(
                      name: 'Pump 1 · Nozzle 1',
                      grade: 'Petrol',
                      litres: '12.76 L',
                      flow: '32.4 L/min',
                      lastUpdate: '1 min ago',
                      status: NozzleStatus.dispensing,
                    ),
                    const SizedBox(height: 10),
                    const _NozzleCard(
                      name: 'Pump 1 · Nozzle 2',
                      grade: 'Petrol',
                      litres: '0.00 L',
                      flow: '0 L/min',
                      lastUpdate: '5 min ago',
                      status: NozzleStatus.idle,
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
          widget.onNavTap?.call(i);
        },
      ),
    );
  }
}

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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brandRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'P',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PARCO',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_outlined, color: AppColors.secondaryText, size: 22),
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.brandRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    const CircleAvatar(radius: 14, backgroundColor: AppColors.borderDivider),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.brandRed, size: 16),
                const SizedBox(width: 6),
                Text(
                  stationName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryText, size: 16),
              ],
            ),
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppColors.brandRed : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  const _FuelChip({required this.label, required this.selected, required this.onTap});
}

class _SalesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: AppColors.brandRed, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Petrol Sales (Today)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _StatBlock(label: 'Total Litres', value: '18,000 L'),
              SizedBox(width: 32),
              _StatBlock(label: 'Total Revenue', value: 'PKR 908,000'),
            ],
          ),
        ],
      ),
    );
  }

  const _SalesCard();
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
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
      ],
    );
  }

  const _StatBlock({required this.label, required this.value});
}

class _StatusChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
        chip('All 12', active: true),
        chip('Dispensing 6', color: AppColors.statusDispensing),
        chip('Idle 4'),
        chip('Faults 2', color: AppColors.statusFault),
      ],
    );
  }

  const _StatusChips();
}

enum NozzleStatus { dispensing, idle, fault }

class _NozzleCard extends StatelessWidget {
  final String name;
  final String grade;
  final String litres;
  final String flow;
  final String lastUpdate;
  final NozzleStatus status;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final Color iconBg;
    switch (status) {
      case NozzleStatus.dispensing:
        statusColor = AppColors.statusDispensing;
        statusLabel = 'Dispensing';
        iconBg = AppColors.redLightSelected;
        break;
      case NozzleStatus.idle:
        statusColor = AppColors.statusIdle;
        statusLabel = 'Idle';
        iconBg = AppColors.background;
        break;
      case NozzleStatus.fault:
        statusColor = AppColors.statusFault;
        statusLabel = 'Fault';
        iconBg = const Color(0xFFFDECEC);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.local_gas_station_outlined, color: AppColors.brandRed, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                      ],
                    ),
                  ],
                ),
                Text(grade, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  children: [
                    _MetaText(bold: litres, label: 'Litres'),
                    _MetaText(bold: flow, label: 'Flow'),
                    Text(lastUpdate, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  const _NozzleCard({
    required this.name,
    required this.grade,
    required this.litres,
    required this.flow,
    required this.lastUpdate,
    required this.status,
  });
}

class _MetaText extends StatelessWidget {
  final String bold;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
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
