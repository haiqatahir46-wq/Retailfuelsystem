import 'package:flutter/material.dart';
import '../screens/location_search_screen.dart';
import '../screens/select_station_screen.dart';
import '../services/google_places_service.dart';
import '../state/app_session.dart';
import 'add_station_route.dart';
import 'route_guard.dart';
import 'server_action.dart';

/// Station switcher, with its own "+ Add Station" drill-down and an
/// "edit" action that opens the Google Places location search. The
/// stations and the current one live in the session, so picking a station
/// here switches what every main tab shows, and a station added or edited
/// here is still there the next time this opens.
class SelectStationFlow extends StatelessWidget {
  /// The Places service the location search uses; null (the app) lets the
  /// search create its own. Tests pass a fake, so editing a location runs
  /// without the network.
  final GooglePlacesService? placesService;

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
        // A SnackBar still showing is about the old station ("PO-... placed"),
        // so it mustn't carry over onto the new one's tabs.
        if (id != session.currentStationId) ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
        session.selectStation(id);
        Navigator.of(context).pop();
      },
      onEditStation: (station) {
        if (!isTopRoute(context)) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            // The search closes itself after a pick, so the save runs
            // without a spinner (one would be what the search's own pop
            // closed). Only the location changes; the station keeps the
            // name the owner gave it.
            builder: (searchContext) => LocationSearchScreen(
              service: placesService,
              onLocationSelected: (details) => runServerAction(
                context,
                () => session.updateStationLocation(station.id, details.formattedAddress),
                showProgress: false,
              ),
            ),
          ),
        );
      },
      onAddStation: () => openAddStation(context),
    );
  }

  const SelectStationFlow({super.key, this.placesService});
}
