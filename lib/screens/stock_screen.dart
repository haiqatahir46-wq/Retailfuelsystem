import 'package:flutter/material.dart';
import '../data/demo_tanks.dart';
import '../models/tank_stock.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_bar.dart';

/// Opened from the "Stock" tab in the bottom nav. Top of the screen is
/// the StationRow, then a plain station-photo banner (NOT wave-clipped
/// like Dashboard/Splash - a straight-edged rectangle here), then
/// straight into one card per fuel grade with its health status, fill
/// bar, current/capacity/threshold stats and Set Threshold/Create Reorder
/// actions, then Recent Purchased Orders. Keeps the bottom nav, since
/// this is a tab, not a drill-down. The hamburger drawer is still there -
/// swipe in from the left edge to open it, same as before - there's just
/// no icon button for it now that the top bar itself is gone.
///
/// [stationId] is REQUIRED - Current Volume on every tank card is computed
/// from THIS station's own today's sales (see tanksForStation() above),
/// same rule as Dashboard: an owner must never see a tank level that isn't
/// actually derived from their own station's real sales.
class StockScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String userName;
  final String userEmail;
  final Widget? stationImage;
  final List<TankStock>? tanks;
  final List<PurchaseOrder> purchaseOrders;
  final VoidCallback? onStationTap;
  final void Function(TankStock tank)? onSetThreshold;
  final void Function(TankStock tank)? onCreateReorder;
  final VoidCallback? onProfileTap;
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final ValueChanged<int>? onNavTap;

  @override
  State<StockScreen> createState() => _StockScreenState();

  const StockScreen({
    super.key,
    required this.stationId,
    this.stationName = 'Amir Filling, Pattoki',
    this.userName = 'Haiqa Tahir',
    this.userEmail = 'haiqa@parco.example',
    this.stationImage,
    this.tanks,
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
}

class _StockScreenState extends State<StockScreen> {
  int _navIndex = 3; // Stock tab active

  // Scoped to widget.stationId ONLY, computed fresh from today's real
  // sales - never a fixed list unrelated to actual sale data.
  List<TankStock> get _tanks => widget.tanks ?? tanksForStation(widget.stationId);

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
                  for (final tank in _tanks) ...[
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

  const _TankCard({required this.tank, required this.onSetThreshold, required this.onCreateReorder});
}

class _TankStat extends StatelessWidget {
  final String label;
  final String value;

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

  const _TankStat({required this.label, required this.value});
}

class _PurchaseOrderRow extends StatelessWidget {
  final PurchaseOrder order;

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

  const _PurchaseOrderRow({required this.order});
}

/// Shown when no real station photo has been supplied yet. Plain
/// rectangle - no wave clip on this screen.
class _StationPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.redLightSelected,
      alignment: Alignment.center,
      child: const Icon(Icons.local_gas_station, size: 40, color: AppColors.brandRed),
    );
  }

  const _StationPlaceholder();
}
