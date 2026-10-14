import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The Dashboard's fixed top bar: hamburger (opens the screen's AppDrawer),
/// the PARCO brand, and on the right Help Center, notifications and
/// Profile. Help Center and Profile are real, working icons - tapping them
/// calls onHelpCenterTap/onProfileTap directly, they don't just sit inside
/// the hamburger drawer. The Nozzles header reuses its pieces
/// ([AppBrandMark], [NotificationBell], [ProfileAvatarButton]).
class AppTopBar extends StatelessWidget {
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      // The avatar's 48dp tap target already adds 10dp of space on its
      // right and above and below the 28dp circle, so the padding there is
      // smaller to keep the bar's usual size.
      padding: const EdgeInsets.fromLTRB(20, 6, 10, 6),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.borderDivider)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.menu, color: AppColors.primaryText, size: 24),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(child: AppBrandMark()),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: const Icon(Icons.help_outline, color: AppColors.secondaryText, size: 22),
            tooltip: 'Help Center',
            onPressed: onHelpCenterTap,
          ),
          const SizedBox(width: 6),
          const NotificationBell(),
          ProfileAvatarButton(onTap: onProfileTap),
        ],
      ),
    );
  }

  const AppTopBar({super.key, this.onHelpCenterTap, this.onProfileTap});
}

/// The red "P" square and the PARCO wordmark. Scales down rather than
/// overflowing when a narrow screen or large text leaves it little room.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
    );
  }
}

/// The notification bell. Notifications aren't built yet, so it does
/// nothing, and it shows the red unread dot only when told there is
/// something unread ([hasUnread]) - never as decoration.
class NotificationBell extends StatelessWidget {
  final bool hasUnread;

  const NotificationBell({super.key, this.hasUnread = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined, color: AppColors.secondaryText, size: 22),
        if (hasUnread)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.brandRed, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}

/// The small profile circle, centred in a 48x48 tap target (the minimum
/// recommended touch size) rather than being only as big as the circle.
/// Without [onTap] it is just the picture: no ripple and no tooltip.
class ProfileAvatarButton extends StatelessWidget {
  final VoidCallback? onTap;

  const ProfileAvatarButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    const avatar = SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.redLightSelected,
          child: Icon(Icons.person, size: 16, color: AppColors.brandRed),
        ),
      ),
    );
    if (onTap == null) return avatar;
    return Tooltip(
      message: 'Profile',
      child: InkResponse(onTap: onTap, radius: 24, child: avatar),
    );
  }
}

/// The current station's name, under the top bar. On Dashboard and Stock
/// it is tappable ([onTap]) and opens the station switcher (Select
/// Station); the chevron is shown only then, so on Nozzles, where it is a
/// plain label, it doesn't look tappable. A long name is cut short with an
/// ellipsis instead of overflowing. A tappable row is at least 48dp tall
/// (the recommended minimum tap height), the name centred in it.
class StationRow extends StatelessWidget {
  final String stationName;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: onTap == null ? 0 : 48),
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.brandRed, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    stationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryText, size: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  const StationRow({
    super.key,
    required this.stationName,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 10),
  });
}
