import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/bottom_nav.dart';
import 'package:petrolpump_flutter/app_drawer.dart';
import 'package:petrolpump_flutter/app_top_bar.dart';

enum TankHealth { healthy, low, critical }

class TankStock {
  final String fuelName;
  final double currentVolume;
  final double capacity;
  final double threshold;

  const TankStock({
    required this.fuelName,
    required this.currentVolume,
    required this.capacity,
    required this.threshold,
  });

  double get percentFull => (currentVolume / capacity).clamp(0, 1);

  TankHealth get health {
    if (currentVolume >= threshold) return TankHealth.healthy;
    if (currentVolume >= threshold * 0.5) return TankHealth.low;
    return TankHealth.critical;
  }
}

enum DeliveryVehicle { self, carriage }

class PurchaseOrder {
  final String poNumber;
  final String date;
  final String fuelName;
  final double litres;
  final DeliveryVehicle vehicle;

  const PurchaseOrder({
    required this.poNumber,
    required this.date,
    required this.fuelName,
    required this.litres,
    required this.vehicle,
  });
}

// Demo data - wire to real ATG/tank-gauge readings later (see the Logs
// screen discussion on fetching from the station's ATG system). Capacity
// and threshold match the Figma reference (25,000 L / 18,000 L for every
// tank); currentVolume is derived from the reference's own 76%/42%/23%
// figures rather than the flat "12,760 L" repeated for all three there,
// since that number couldn't have been right for all three at once.
const demoTankStock = [
  TankStock(fuelName: 'Petrol', currentVolume: 19000, capacity: 25000, threshold: 18000),
  TankStock(fuelName: 'Diesel', currentVolume: 10500, capacity: 25000, threshold: 18000),
  TankStock(fuelName: 'Hi-Octane', currentVolume: 5750, capacity: 25000, threshold: 18000),
];

const demoPurchaseOrders = [
  PurchaseOrder(poNumber: 'PO-2026-0058', date: '15 May 2026', fuelName: 'Diesel', litres: 20000, vehicle: DeliveryVehicle.carriage),
  PurchaseOrder(poNumber: 'PO-2026-0058', date: '15 May 2026', fuelName: 'Petrol', litres: 20000, vehicle: DeliveryVehicle.self),
  PurchaseOrder(poNumber: 'PO-2026-0058', date: '15 May 2026', fuelName: 'Hi-Octane', litres: 20000, vehicle: DeliveryVehicle.carriage),
];

/// Opened from the "Stock" tab in the bottom nav. Top of the screen is
/// the StationRow, then a plain station-photo banner (NOT wave-clipped
/// like Dashboard/Splash - a straight-edged rectangle here), then
/// straight into one card per fuel grade with its health status, fill
/// bar, current/capacity/threshold stats and Set Threshold/Create Reorder
/// actions, then Recent Purchased Orders. Keeps the bottom nav, since
/// this is a tab, not a drill-down. The hamburger drawer is still there -
/// swipe in from the left edge to open it, same as before - there's just
/// no icon button for it now that the top bar itself is gone.
class StockScreen extends StatefulWidget {
  final String stationName;
  final String userName;
  final String userEmail;
  final Widget? stationImage;
  final List<TankStock> tanks;
  final List<PurchaseOrder> purchaseOrders;
  final VoidCallback? onStationTap;
  final void Function(TankStock tank)? onSetThreshold;
  final void Function(TankStock tank)? onCreateReorder;
  final VoidCallback? onProfileTap;
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final ValueChanged<int>? onNavTap;

  const StockScreen({
    super.key,
    this.stationName = 'Amir Filling, Pattoki',
    this.userName = 'Haiqa Tahir',
    this.userEmail = 'haiqa@parco.example',
    this.stationImage,
    this.tanks = demoTankStock,
    this.purchaseOrders = demoPurchaseOrders,
    this.onStationTap,
    this.onSetThreshold,
    this.onCreateReorder,
    this.onProfileTap,
    this.onHelpCenterTap,
    this.onSettingsTap,
    this.onLogoutTap,
    this.onNavTap,
  });

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  int _navIndex = 3; // Stock tab active

  @override
  Widget build(BuildContext context) {
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
            // Location first, then the photo right below it.
            StationRow(stationName: widget.stationName, onTap: widget.onStationTap),
            // Plain photo banner - deliberately NOT wave-clipped, just a
            // straight-edged rectangle, unlike the Dashboard/Splash/Login/
            // Signup banners.
            SizedBox(
              height: 150,
              width: double.infinity,
              child: widget.stationImage ?? const _StationPlaceholder(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  for (final tank in widget.tanks) ...[
                    _TankCard(
                      tank: tank,
                      onSetThreshold: () => widget.onSetThreshold?.call(tank),
                      onCreateReorder: () => widget.onCreateReorder?.call(tank),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    'Recent Purchased Orders',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 12),
                  for (final po in widget.purchaseOrders) ...[
                    _PurchaseOrderRow(order: po),
                    const SizedBox(height: 10),
                  ],
                ],
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

class _TankCard extends StatelessWidget {
  final TankStock tank;
  final VoidCallback onSetThreshold;
  final VoidCallback onCreateReorder;

  const _TankCard({required this.tank, required this.onSetThreshold, required this.onCreateReorder});

  Color get _statusColor {
    switch (tank.health) {
      case TankHealth.healthy:
        return AppColors.statusDispensing;
      case TankHealth.low:
        return AppColors.statusAttention;
      case TankHealth.critical:
        return AppColors.statusFault;
    }
  }

  String get _statusLabel {
    switch (tank.health) {
      case TankHealth.healthy:
        return 'Healthy';
      case TankHealth.low:
        return 'Low';
      case TankHealth.critical:
        return 'Critical';
    }
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => ',',
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tank.fuelName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(_statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: tank.percentFull,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(_statusColor),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(tank.percentFull * 100).round()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TankStat(label: 'Current Volume', value: '${_fmt(tank.currentVolume)} L'),
              _TankStat(label: 'Tank Capacity', value: '${_fmt(tank.capacity)} L'),
              _TankStat(label: 'Threshold', value: '${_fmt(tank.threshold)} L'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: onSetThreshold,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryText,
                      side: const BorderSide(color: AppColors.borderDivider, width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Set Threshold'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: onCreateReorder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Create Reorder'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TankStat extends StatelessWidget {
  final String label;
  final String value;
  const _TankStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText)),
        ],
      ),
    );
  }
}

class _PurchaseOrderRow extends StatelessWidget {
  final PurchaseOrder order;
  const _PurchaseOrderRow({required this.order});

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => ',',
      );

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = order.vehicle == DeliveryVehicle.self ? 'Self' : 'Carriage';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.poNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                const SizedBox(height: 2),
                Text(order.date, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              '${order.fuelName} · ${_fmt(order.litres)} L',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primaryText),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.statusDispensing.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Delivered', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.statusDispensing)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)),
                  child: Text(vehicleLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when no real station photo has been supplied yet. Plain
/// rectangle - no wave clip on this screen.
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
