import 'package:flutter/material.dart';
import '../screens/account_details_screen.dart';
import '../screens/help_center_screen.dart';
import '../screens/profile_screen.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import 'login_flow.dart';
import 'route_guard.dart';
import 'staff_flow.dart';

/// Opened from the Dashboard/Nozzles profile avatar or the drawer (on
/// Dashboard and Stock). Shows the
/// signed-in owner and current station from the session, owns the Account
/// Details / Staff / Help & Support drill-downs, and pops its own
/// bottom-nav taps back up to MainTabsFlow rather than pushing a second
/// copy of the main tabs.
class ProfileFlow extends StatelessWidget {
  final int navIndex;

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    final owner = session.owner;
    final station = session.currentStation;
    // Signed out while this route is on its way out (logOut clears the
    // session before Login replaces it): nothing left to show.
    if (owner == null || station == null) return const ColoredBox(color: AppColors.background);

    return ProfileScreen(
      stationName: station.name,
      ownerName: owner.name,
      address: station.location.isEmpty ? station.name : station.location,
      nozzleCount: session.nozzlesFor(station.id).length,
      // TODO: placeholder - nothing records when the account started yet.
      yearsActive: 3,
      navIndex: navIndex,
      onBack: () => Navigator.of(context).pop(),
      onNavTap: (i) => Navigator.of(context).pop(i),
      onEditProfile: null, // TODO: no edit-profile screen exists yet
      onAccountDetailsTap: () {
        if (!isTopRoute(context)) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AccountDetailsScreen(
              stationName: station.name,
              onBack: () => Navigator.of(context).pop(),
              onSubmit: (details) => Navigator.of(context).pop(),
            ),
          ),
        );
      },
      onStaffManagementTap: () {
        if (!isTopRoute(context)) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const StaffFlow()),
        );
      },
      onHelpSupportTap: () {
        if (!isTopRoute(context)) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HelpCenterScreen(onBack: () => Navigator.of(context).pop()),
          ),
        );
      },
      onLogout: () => logOut(context),
    );
  }

  const ProfileFlow({super.key, required this.navIndex});
}
