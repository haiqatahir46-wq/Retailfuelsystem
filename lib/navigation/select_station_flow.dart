import 'package:flutter/material.dart';
import '../screens/location_search_screen.dart';
import '../screens/select_station_screen.dart';
import '../state/app_session.dart';
import 'add_station_route.dart';
import 'route_guard.dart';

/// Station switcher, with its own "+ Add Station" drill-down and an
/// "edit" action that opens the Google Places location search. The
/// stations and the current one live in the session, so picking a station
/// here switches what every main tab shows, and a station added or edited
/// here is still there the next time this opens.
class SelectStationFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    return SelectStationScreen(
      stations: session.stations,
      selectedStationId: session.currentStationId ?? '',
      onBack: () => Navigator.of(context).pop(),
      onStationSelected: (id) {
        // Guarded like a push: a double tap must not pop the main tabs too.
        if (!isTopRoute(context)) return;
        session.selectStation(id);
        Navigator.of(context).pop();
      },
      onEditStation: (station) {
        if (!isTopRoute(context)) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            // The search closes itself after a pick. Only the location
            // changes; the station keeps the name the owner gave it.
            builder: (context) => LocationSearchScreen(
              onLocationSelected: (details) => session.updateStationLocation(station.id, details.formattedAddress),
            ),
          ),
        );
      },
      onAddStation: () => openAddStation(context),
    );
  }

  const SelectStationFlow({super.key});
}
