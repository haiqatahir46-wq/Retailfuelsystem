import 'package:flutter/material.dart';
import '../screens/stations_added_screen.dart';
import '../state/app_session.dart';
import 'add_station_route.dart';
import 'main_tabs_flow.dart';
import 'route_guard.dart';

/// Stations Added summary, plus the "Add Another Station" form it can
/// open. The stations live in the session (put there by SignupFlow's
/// AppSession.signUp), so a station added on the pushed form shows up here
/// as soon as the session changes, and every one of them is still there
/// on the Dashboard's station switcher after Continue.
class StationsAddedFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    return StationsAddedScreen(
      stations: session.stations,
      onContinue: () {
        if (!isTopRoute(context)) return;
        // pushAndRemoveUntil clears Login/Signup/StationsAdded from the
        // back stack - once on the main tabs, back shouldn't step through
        // the signup flow. The first (named) station is already current.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainTabsFlow()),
          (route) => false,
        );
      },
      onAddAnotherStation: () => openAddStation(context),
      // TODO: no "edit station" screen exists yet.
      onEditStation: null,
    );
  }

  const StationsAddedFlow({super.key});
}
