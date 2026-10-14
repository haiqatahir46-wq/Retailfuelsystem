import 'package:flutter/material.dart';
import '../models/sales.dart';
import '../models/tank_stock.dart';
import '../screens/create_reorder_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/help_center_screen.dart';
import '../screens/logs_screen.dart';
import '../screens/nozzles_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stock_screen.dart';
import '../screens/threshold_screen.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/tank_health_style.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/tank_widgets.dart';
import 'login_flow.dart';
import 'profile_flow.dart';
import 'route_guard.dart';
import 'select_station_flow.dart';

/// The five bottom-nav tabs (Dashboard / Nozzles / Tanks / Stock / Logs)
/// for the session's current station. Each tab is a full Scaffold with its
/// own AppBottomNavBar; they all sit in an IndexedStack, so switching tabs
/// only changes which one is visible and each keeps its state (a half-filled
/// log, the chosen Dashboard period, the scroll position). Each tab's key
/// includes the station id, so switching station starts every tab afresh
/// instead of carrying one station's form or selection into another's.
///
/// Reads the owner, the current station and its data from the session and
/// passes them into the screens. Drill-downs (Profile, Threshold, Reorder,
/// Help Center, Settings, Select Station) are pushed on top of whichever
/// tab is active. System back on any tab but Dashboard goes to Dashboard.
class MainTabsFlow extends StatefulWidget {
  const MainTabsFlow({super.key});

  @override
  State<MainTabsFlow> createState() => _MainTabsFlowState();
}

class _MainTabsFlowState extends State<MainTabsFlow> {
  int _tabIndex = AppTab.dashboard;

  void _goToTab(int i) => setState(() => _tabIndex = i);

  /// Back on a tab other than Dashboard (PopScope's canPop is false there).
  /// An open drawer is a local history entry on this route, which back
  /// would normally close, so close it first; otherwise go to Dashboard,
  /// where the next back leaves as usual.
  void _handleBlockedBack() {
    if (ModalRoute.of(context)?.willHandlePopInternally ?? false) {
      // Navigator.pop ignores PopScope and removes the drawer's entry, not
      // this route.
      Navigator.of(context).pop();
      return;
    }
    _goToTab(AppTab.dashboard);
  }

  void _openHelpCenter() {
    if (!isTopRoute(context)) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HelpCenterScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _openSettings() {
    if (!isTopRoute(context)) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onBack: () => Navigator.of(context).pop(),
          onLogout: () => logOut(context),
        ),
      ),
    );
  }

  void _openSelectStation() {
    if (!isTopRoute(context)) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SelectStationFlow()),
    );
  }

  /// Profile is a push, not a tab - but it has its own bottom nav (see
  /// ProfileScreen's navIndex/onNavTap), so tapping a tab FROM Profile
  /// needs to pop back here and land on that tab rather than pushing a
  /// second copy of the main tabs. Returning the tapped index via pop's
  /// result is what makes that work.
  void _openProfile() async {
    if (!isTopRoute(context)) return;
    final tappedTab = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (context) => ProfileFlow(navIndex: _tabIndex)),
    );
    if (tappedTab != null && mounted) setState(() => _tabIndex = tappedTab);
  }

  // Set Threshold / Create Reorder on ANY tank card opens the full list of
  // that station's tanks, matching ThresholdScreen and CreateReorderScreen's
  // own design. [from] is the context of the route doing the opening (the
  // tabs, or Threshold for its Reorder button), checked so a double tap
  // opens one screen. Each route reads the session in its builder, so a
  // confirmed threshold or a placed order redraws that screen - and Stock
  // and Tanks underneath - straight away.

  void _openThreshold(BuildContext from, String stationId) {
    if (!isTopRoute(from)) return;
    Navigator.of(from).push(
      MaterialPageRoute(
        builder: (context) {
          final session = AppSessionScope.of(context);
          return ThresholdScreen(
            stationName: session.stationById(stationId)?.name ?? '',
            tanks: session.tanksFor(stationId),
            onBack: () => Navigator.of(context).pop(),
            // Stays open, so the other tanks can be set too.
            onConfirmThreshold: (tank, litres) {
              if (session.setThreshold(tank.id, litres)) {
                _showSnackBar(context, '${tank.fuelName} threshold set to ${formatThousands(litres)} L');
              }
            },
            onReorder: (_) => _openCreateReorder(context, stationId),
          );
        },
      ),
    );
  }

  void _openCreateReorder(BuildContext from, String stationId) {
    if (!isTopRoute(from)) return;
    Navigator.of(from).push(
      MaterialPageRoute(
        builder: (context) {
          final session = AppSessionScope.of(context);
          final tanks = session.tanksFor(stationId);
          return CreateReorderScreen(
            stationName: session.stationById(stationId)?.name ?? '',
            tanks: tanks,
            // What's already on order shrinks each tank's limit, so the form
            // allows exactly what placeReorder will accept.
            pendingLitres: {for (final t in tanks) t.id: session.pendingLitresFor(t.id)},
            onBack: () => Navigator.of(context).pop(),
            // Stays open, so more tanks can be reordered; the order is at
            // the top of Stock's Recent Purchased Orders.
            onSubmitReorder: (tank, litres) {
              final order = session.placeReorder(stationId: stationId, tank: tank, litres: litres);
              _showSnackBar(
                context,
                order != null
                    ? '${order.poNumber} placed: ${formatThousands(order.litres)} L of ${order.fuelName}'
                    // The form checks the same limit, so this only happens
                    // if the tank changed under it; say so rather than
                    // emptying the field in silence.
                    : 'Order not placed: the ${tank.fuelName} tank has no room for ${formatThousands(litres)} L',
              );
            },
          );
        },
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    final owner = session.owner;
    final station = session.currentStation;
    // Signed out while this route is on its way out (logOut clears the
    // session before Login replaces it): nothing left to show.
    if (owner == null || station == null) return const ColoredBox(color: AppColors.background);

    final id = station.id;
    final tanks = session.tanksFor(id);
    final nozzles = session.nozzlesFor(id);

    final tabs = <Widget>[
      DashboardScreen(
        key: ValueKey('dashboard-$id'),
        stationId: id,
        stationName: station.name,
        userName: owner.name,
        userEmail: owner.email,
        tanks: tanks,
        nozzles: nozzles,
        onNavTap: _goToTab,
        onProfileTap: _openProfile,
        onHelpCenterTap: _openHelpCenter,
        onSettingsTap: _openSettings,
        onLogoutTap: () => logOut(context),
        onLocationTap: _openSelectStation,
      ),
      NozzlesScreen(
        key: ValueKey('nozzles-$id'),
        stationId: id,
        stationName: station.name,
        nozzles: nozzles,
        onNavTap: _goToTab,
        onProfileTap: _openProfile,
      ),
      _TanksTab(
        key: ValueKey('tanks-$id'),
        stationName: station.name,
        tanks: tanks,
        onNavTap: _goToTab,
      ),
      StockScreen(
        key: ValueKey('stock-$id'),
        stationName: station.name,
        userName: owner.name,
        userEmail: owner.email,
        tanks: tanks,
        purchaseOrders: session.purchaseOrdersFor(id),
        onNavTap: _goToTab,
        onStationTap: _openSelectStation,
        onSetThreshold: (_) => _openThreshold(context, id),
        onCreateReorder: (_) => _openCreateReorder(context, id),
        onProfileTap: _openProfile,
        onHelpCenterTap: _openHelpCenter,
        onSettingsTap: _openSettings,
        onLogoutTap: () => logOut(context),
      ),
      LogsScreen(
        key: ValueKey('logs-$id'),
        stationName: station.name,
        entries: session.logsFor(id),
        nozzles: nozzles,
        onNavTap: _goToTab,
      ),
    ];

    return PopScope(
      canPop: _tabIndex == AppTab.dashboard,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBlockedBack();
      },
      child: IndexedStack(
        index: _tabIndex,
        sizing: StackFit.expand,
        children: [
          // Every tab's Scaffold shows the app's SnackBars, and each
          // SnackBar carries a Hero. Only the visible tab's heroes may join
          // a route transition, or Flutter finds several with one tag.
          for (var i = 0; i < tabs.length; i++) HeroMode(enabled: i == _tabIndex, child: tabs[i]),
        ],
      ),
    );
  }
}

/// Tanks tab - a quick-glance read of every tank's fill level and health,
/// from the same session.tanksFor list Stock shows, so the numbers never
/// drift apart, but without Stock's management actions (Set Threshold/
/// Create Reorder/purchase orders) - those stay on Stock, this is just the
/// at-a-glance view the bottom nav's separate "Tanks" icon implies.
/// Private to this file - nothing outside MainTabsFlow ever needs to build
/// one directly.
class _TanksTab extends StatelessWidget {
  final String stationName;
  final List<TankStock> tanks;
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
          if (tanks.isEmpty) const EmptyState('No tanks set up for this station yet.'),
          for (final tank in tanks) ...[
            _TankLevelCard(tank: tank),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: AppTab.tanks, onTap: onNavTap),
    );
  }

  const _TanksTab({
    super.key,
    required this.stationName,
    required this.tanks,
    required this.onNavTap,
  });
}

class _TankLevelCard extends StatelessWidget {
  final TankStock tank;

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
          const SizedBox(height: 6),
          Text(
            '${formatThousands(tank.currentVolume)} L of ${formatThousands(tank.capacity)} L (${(tank.percentFull * 100).round()}%)',
            style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }

  const _TankLevelCard({required this.tank});
}
