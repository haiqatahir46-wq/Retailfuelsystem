import 'package:flutter/material.dart';
import '../screens/add_station_screen.dart';
import '../state/app_session.dart';
import 'route_guard.dart';

/// Opens Add Station on top of [context]'s route. A submitted form becomes
/// a new station in the session (AppSession.addStation) and the form
/// closes. Shared by Stations Added and Select Station, which both list
/// session.stations, so the new station shows up in whichever opened it.
void openAddStation(BuildContext context) {
  if (!isTopRoute(context)) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => AddStationScreen(
        onBack: () => Navigator.of(context).pop(),
        onAddStation: ({
          required name,
          required location,
          required petrolNozzles,
          required dieselNozzles,
          required hiOctaneNozzles,
          required petrolCapacityL,
          required dieselCapacityL,
          required hiOctaneCapacityL,
        }) {
          if (!isTopRoute(context)) return;
          AppSessionScope.read(context).addStation(
            name: name,
            location: location,
            nozzleCounts: {'Petrol': petrolNozzles, 'Diesel': dieselNozzles, 'Hi-Octane': hiOctaneNozzles},
            capacities: {'Petrol': petrolCapacityL, 'Diesel': dieselCapacityL, 'Hi-Octane': hiOctaneCapacityL},
          );
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}
