import 'package:flutter/material.dart';
import '../screens/create_reorder_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/help_center_screen.dart';
import '../screens/logs_screen.dart';
import '../screens/nozzles_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stock_screen.dart';
import '../screens/threshold_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'login_flow.dart';
import 'profile_flow.dart';
import 'select_station_flow.dart';

/// Owns which bottom-nav tab is showing (Dashboard / Nozzles / Tanks /
/// Stock / Logs) and swaps the body in place with setState - Dashboard,
/// Stock, Logs and Nozzles are each a full Scaffold with their own
/// AppBottomNavBar built in, so tapping a tab just changes which one gets
/// built, the same way a bottom-nav IndexedStack would. Drill-downs
/// (Profile, Account Details, Staff, Threshold, Reorder, Help Center,
/// Settings, Select Station) use Navigator.push on top of whichever tab
/// is active.
class MainTabsFlow extends StatefulWidget {
  final String stationId;
  final String stationName;

  const MainTabsFlow({super.key, required this.stationId, this.stationName = 'Amir Filling, Pattoki'});

  @override
  State<MainTabsFlow> createState() => _MainTabsFlowState();
}

class _MainTabsFlowState extends State<MainTabsFlow> {
  int _tabIndex = 0;

  void _goToTab(int i) => setState(() => _tabIndex = i);

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginFlow()),
      (route) => false,
    );
  }

  void _openHelpCenter() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HelpCenterScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onBack: () => Navigator.of(context).pop(),
          onLogout: _logout,
        ),
      ),
    );
  }

  void _openSelectStation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectStationFlow(stationId: widget.stationId, stationName: widget.stationName),
      ),
    );
  }

  /// Profile is a push, not a tab - but it has its own bottom nav (see
  /// ProfileScreen's navIndex/onNavTap), so tapping a tab FROM Profile
  /// needs to pop back here and land on that tab rather than pushing a
  /// second copy of the main tabs. Returning the tapped index via pop's
  /// result is what makes that work.
  void _openProfile() async {
    final tappedTab = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => ProfileFlow(stationName: widget.stationName, navIndex: _tabIndex),
      ),
    );
    if (tappedTab != null && mounted) setState(() => _tabIndex = tappedTab);
  }

  // The tapped tank itself isn't used - Set Threshold/Create Reorder on
  // ANY tank card opens the full list of tanks, matching ThresholdScreen
  // and CreateReorderScreen's own design.
  void _openThreshold(TankStock _) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ThresholdScreen(
          stationName: widget.stationName,
          tanks: tanksForStation(widget.stationId),
          onBack: () => Navigator.of(context).pop(),
          onConfirmThreshold: (t, newThreshold) => Navigator.of(context).pop(),
          onReorder: (t) => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openCreateReorder(TankStock _) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateReorderScreen(
          stationName: widget.stationName,
          tanks: tanksForStation(widget.stationId),
          onBack: () => Navigator.of(context).pop(),
          onSubmitReorder: (t, quantity) => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_tabIndex) {
      case 1:
        return NozzlesScreen(stationName: widget.stationName, onNavTap: _goToTab);
      case 2:
        return _TanksTab(stationId: widget.stationId, stationName: widget.stationName, navIndex: _tabIndex, onNavTap: _goToTab);
      case 3:
        return StockScreen(
          stationId: widget.stationId,
          stationName: widget.stationName,
          onNavTap: _goToTab,
          onStationTap: _openSelectStation,
          onSetThreshold: _openThreshold,
          onCreateReorder: _openCreateReorder,
          onProfileTap: _openProfile,
          onHelpCenterTap: _openHelpCenter,
          onSettingsTap: _openSettings,
          onLogoutTap: _logout,
        );
      case 4:
        return LogsScreen(stationName: widget.stationName, onNavTap: _goToTab);
      default:
        return DashboardScreen(
          stationId: widget.stationId,
          stationName: widget.stationName,
          onQuickLinkTap: _goToTab,
          onProfileTap: _openProfile,
          onHelpCenterTap: _openHelpCenter,
          onSettingsTap: _openSettings,
          onLogoutTap: _logout,
          onLocationTap: _openSelectStation,
        );
    }
  }
}

/// Tanks tab - a quick-glance read of every tank's fill level and health,
/// reusing the exact same real-sales-derived data Stock uses
/// (tanksForStation) so the numbers never drift apart, but without
/// Stock's management actions (Set Threshold/Create Reorder/purchase
/// orders) - those stay on Stock, this is just the at-a-glance view the
/// bottom nav's separate "Tanks" icon implies. Private to this file -
/// nothing outside MainTabsFlow ever needs to build one directly.
class _TanksTab extends StatelessWidget {
  final String stationId;
  final String stationName;
  final int navIndex;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        title: Text(
          stationName,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderDivider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          const Text(
            'Tank Levels',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 14),
          for (final tank in tanksForStation(stationId)) ...[
            _TankLevelCard(tank: tank),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: navIndex, onTap: onNavTap),
    );
  }

  const _TanksTab({
    required this.stationId,
    required this.stationName,
    required this.navIndex,
    required this.onNavTap,
  });
}

class _TankLevelCard extends StatelessWidget {
  final TankStock tank;

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
          const SizedBox(height: 6),
          Text(
            '${_fmt(tank.currentVolume)} L of ${_fmt(tank.capacity)} L (${(tank.percentFull * 100).round()}%)',
            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }

  const _TankLevelCard({required this.tank});
}