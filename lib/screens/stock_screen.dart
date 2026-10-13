import 'package:flutter/material.dart';
import '../models/sales.dart';
import '../models/tank_stock.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/tank_health_style.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/station_photo.dart';
import '../widgets/tank_widgets.dart';

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
/// [tanks] and [purchaseOrders] are ONE station's, from the session
/// (MainTabsFlow passes session.tanksFor / session.purchaseOrdersFor):
/// Current Volume on every tank card is derived from that station's own
/// sales today, never a tank level from anywhere else, and the orders
/// include any placed this session, newest first.
class StockScreen extends StatelessWidget {
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
  final ValueChanged<int> onNavTap;

  const StockScreen({
    super.key,
    required this.stationName,
    required this.userName,
    required this.userEmail,
    required this.tanks,
    required this.purchaseOrders,
    required this.onNavTap,
    this.stationImage,
    this.onStationTap,
    this.onSetThreshold,
    this.onCreateReorder,
    this.onProfileTap,
    this.onHelpCenterTap,
    this.onSettingsTap,
    this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        userName: userName,
        userEmail: userEmail,
        onProfileTap: onProfileTap,
        onHelpCenterTap: onHelpCenterTap,
        onSettingsTap: onSettingsTap,
        onLogoutTap: onLogoutTap,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Location first, then the photo right below it.
            StationRow(stationName: stationName, onTap: onStationTap),
            // Plain photo banner - deliberately NOT wave-clipped, just a
            // straight-edged rectangle, unlike the Dashboard/Splash/Login/
            // Signup banners.
            SizedBox(
              height: 150,
              width: double.infinity,
              child: stationImage ?? const StationPhoto(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  if (tanks.isEmpty) const EmptyState('No tanks set up for this station yet.'),
                  for (final tank in tanks) ...[
                    _TankCard(
                      tank: tank,
                      onSetThreshold: () => onSetThreshold?.call(tank),
                      onCreateReorder: () => onCreateReorder?.call(tank),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    'Recent Purchased Orders',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 12),
                  if (purchaseOrders.isEmpty) const EmptyState('No purchase orders for this station yet.'),
                  for (final po in purchaseOrders) ...[
                    _PurchaseOrderRow(order: po),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: AppTab.stock, onTap: onNavTap),
    );
  }
}

class _TankCard extends StatelessWidget {
  final TankStock tank;
  final VoidCallback onSetThreshold;
  final VoidCallback onCreateReorder;

  @override
  Widget build(BuildContext context) {
    final statusColor = tank.health.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TankCardHeader(tank: tank),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: tank.percentFull,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(tank.percentFull * 100).round()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TankStat(label: 'Current Volume', value: '${formatThousands(tank.currentVolume)} L'),
              TankStat(label: 'Tank Capacity', value: '${formatThousands(tank.capacity)} L'),
              TankStat(label: 'Threshold', value: '${formatThousands(tank.threshold)} L'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // A minimum height, not a fixed one, so larger text makes the
              // buttons taller instead of clipping their labels.
              Expanded(
                child: OutlinedButton(
                  onPressed: onSetThreshold,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    foregroundColor: AppColors.secondaryText,
                    side: const BorderSide(color: AppColors.borderDivider, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Set Threshold', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onCreateReorder,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    backgroundColor: AppColors.brandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Create Reorder', textAlign: TextAlign.center),
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

class _PurchaseOrderRow extends StatelessWidget {
  final PurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final delivered = order.status == PurchaseOrderStatus.delivered;
    final statusColor = delivered ? AppColors.statusDispensing : AppColors.statusAttention;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDecorations.cardShadow,
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
                Text(formatDate(order.date), style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              '${order.fuelName} · ${formatThousands(order.litres)} L',
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
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    delivered ? 'Delivered' : 'Pending',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)),
                  child: Text(order.vehicle.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
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
