import 'package:flutter/material.dart';
import '../screens/account_details_screen.dart';
import '../screens/help_center_screen.dart';
import '../screens/profile_screen.dart';
import 'login_flow.dart';
import 'staff_flow.dart';

/// Opened from Dashboard/Stock's Profile icon (or drawer). Owns the
/// Account Details / Staff / Help & Support drill-downs, and pops its own
/// bottom-nav taps back up to MainTabsFlow rather than pushing a second
/// copy of the main tabs.
class ProfileFlow extends StatelessWidget {
  final String stationName;
  final int navIndex;

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      stationName: stationName,
      // TODO: all four of these are placeholders - there's no backend yet
      // to pull the real signed-in owner's name, address, nozzle count or
      // years active from.
      ownerName: 'Haiqa Tahir',
      address: stationName,
      nozzleCount: 10,
      yearsActive: 3,
      navIndex: navIndex,
      onBack: () => Navigator.of(context).pop(),
      onNavTap: (i) => Navigator.of(context).pop(i),
      onEditProfile: null, // TODO: no edit-profile screen exists yet
      onAccountDetailsTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AccountDetailsScreen(
              stationName: stationName,
              onBack: () => Navigator.of(context).pop(),
              onSubmit: (details) => Navigator.of(context).pop(),
            ),
          ),
        );
      },
      onStaffManagementTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => StaffFlow(stationName: stationName)),
        );
      },
      onHelpSupportTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HelpCenterScreen(onBack: () => Navigator.of(context).pop()),
          ),
        );
      },
      onLogout: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginFlow()),
          (route) => false,
        );
      },
    );
  }

  const ProfileFlow({super.key, required this.stationName, required this.navIndex});
}
