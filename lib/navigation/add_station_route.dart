import 'package:flutter/material.dart';
import '../screens/add_station_screen.dart';
import '../state/app_session.dart';
import 'route_guard.dart';
import 'server_action.dart';

/// Opens Add Station on top of [context]'s route. A submitted form becomes
/// a new station through the session (AppSession.addStation; with the
/// server, created in the database) and the form closes; a refusal shows
/// the server's message and keeps the form open. Shared by Stations Added
/// and Select Station, which both list session.stations, so the new
/// station shows up in whichever opened it.
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
        }) async {
          if (!isTopRoute(context)) return;
          final session = AppSessionScope.read(context);
          final added = await runServerAction(
            context,
            () => session.addStation(
              name: name,
              location: location,
              nozzleCounts: {'Petrol': petrolNozzles, 'Diesel': dieselNozzles, 'Hi-Octane': hiOctaneNozzles},
              capacities: {'Petrol': petrolCapacityL, 'Diesel': dieselCapacityL, 'Hi-Octane': hiOctaneCapacityL},
            ),
          );
          if (added && context.mounted) Navigator.of(context).pop();
        },
      ),
    ),
  );
}
