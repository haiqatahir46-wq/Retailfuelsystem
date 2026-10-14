import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBottomNavItem {
  final IconData icon;
  final String label;

  const AppBottomNavItem({required this.icon, required this.label});
}

const List<AppBottomNavItem> kAppNavItems = [
  AppBottomNavItem(icon: Icons.home_outlined, label: 'Dashboard'),
  AppBottomNavItem(icon: Icons.local_gas_station_outlined, label: 'Nozzles'),
  AppBottomNavItem(icon: Icons.water_drop_outlined, label: 'Tanks'),
  AppBottomNavItem(icon: Icons.inventory_2_outlined, label: 'Stock'),
  AppBottomNavItem(icon: Icons.receipt_long_outlined, label: 'Logs'),
];

/// Each tab's index in [kAppNavItems]. A tab screen passes its own fixed
/// index to AppBottomNavBar and reports taps to MainTabsFlow, which alone
/// decides which tab shows - no screen keeps its own copy of "which tab is
/// selected".
abstract final class AppTab {
  static const dashboard = 0;
  static const nozzles = 1;
  static const tanks = 2;
  static const stock = 3;
  static const logs = 4;
}

/// Bottom navigation bar matching the PARCO app reference: off-white/white
/// bar, brand-red active icon+label with a small red dot under it, muted
/// gray-blue for inactive items.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: const Border(
          top: BorderSide(color: AppColors.borderDivider, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: SafeArea(
        top: false,
        // An equal share of the width per item, so five labels fit on a
        // narrow phone or with large text instead of overflowing the row.
        child: Row(
          children: List.generate(kAppNavItems.length, (index) {
            final item = kAppNavItems[index];
            final isActive = index == currentIndex;
            return Expanded(
              child: _NavItem(
                item: item,
                isActive: isActive,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
}

class _NavItem extends StatelessWidget {
  final AppBottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.brandRed : AppColors.secondaryText;

    // One node for a screen reader: "Stock, button, selected". The red dot
    // shows the selected tab only to the eye, so it is said out loud here,
    // with the tap; the label below would otherwise be read on its own.
    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: _buildItem(color),
    );
  }

  Widget _buildItem(Color color) {
    return InkWell(
      onTap: onTap,
      customBorder: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color, size: 24),
            const SizedBox(height: 4),
            // One line, shrunk to fit if it must, so a label never wraps
            // or pushes the bar taller than its neighbours.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.brandRed : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });
}
