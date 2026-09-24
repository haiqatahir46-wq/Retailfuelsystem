import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';

/// Fixed top bar shared by every main tab screen (Dashboard, Stock, ...) -
/// hamburger (opens the screen's AppDrawer), the PARCO brand, and on the
/// right: Help Center, notifications and Profile. Help Center and Profile
/// are real, working icons - tapping them calls onHelpCenterTap/
/// onProfileTap directly, they don't just sit inside the hamburger drawer.
class AppTopBar extends StatelessWidget {
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onProfileTap;

  const AppTopBar({super.key, this.onHelpCenterTap, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.borderDivider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.menu, color: AppColors.primaryText, size: 24),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const SizedBox(width: 4),
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
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                icon: const Icon(Icons.help_outline, color: AppColors.secondaryText, size: 22),
                tooltip: 'Help Center',
                onPressed: onHelpCenterTap,
              ),
              const SizedBox(width: 6),
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
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onProfileTap,
                child: const Tooltip(
                  message: 'Profile',
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.redLightSelected,
                    child: Icon(Icons.person, size: 16, color: AppColors.brandRed),
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

/// Tappable station-name row - opens the Google Places location search
/// (Dashboard) or the station switcher (Stock). Sits directly under
/// AppTopBar on every main tab screen that shows one.
class StationRow extends StatelessWidget {
  final String stationName;
  final VoidCallback? onTap;

  const StationRow({super.key, required this.stationName, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.cardBackground,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
    );
  }
}
