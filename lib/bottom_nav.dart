import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';

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

/// Bottom navigation bar matching the PARCO app reference: off-white/white
/// bar, brand-red active icon+label with a small red dot under it, muted
/// gray-blue for inactive items.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(kAppNavItems.length, (index) {
            final item = kAppNavItems[index];
            final isActive = index == currentIndex;
            return _NavItem(
              item: item,
              isActive: isActive,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppBottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.brandRed : AppColors.secondaryText;

    return InkWell(
      onTap: onTap,
      customBorder: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
}
