import 'package:flutter/material.dart';
import '../screens/add_station_screen.dart';
import '../screens/stations_added_screen.dart';
import 'main_tabs_flow.dart';

/// Stations Added summary, plus the "Add Another Station" form it can
/// open. Stateful: it owns the stations list itself, since Navigator.push
/// captures a route's widget tree once when it's built, so setState on
/// some OTHER widget after popping back here would never update what's
/// on screen.
class StationsAddedFlow extends StatefulWidget {
  final String stationName;
  final int stationCount;

  @override
  State<StationsAddedFlow> createState() => _StationsAddedFlowState();

  const StationsAddedFlow({super.key, required this.stationName, required this.stationCount});
}

class _StationsAddedFlowState extends State<StationsAddedFlow> {
  late List<StationSummary> _stations = StationSummary.fromSignup(
    stationName: widget.stationName,
    stationCount: widget.stationCount,
  );

  @override
  Widget build(BuildContext context) {
    return StationsAddedScreen(
      stations: _stations,
      onContinue: () {
        // pushAndRemoveUntil clears Login/Signup/StationsAdded from the
        // back stack - once on the main tabs, back shouldn't step through
        // the signup flow.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainTabsFlow(
              stationId: 'station-1', // TODO: same placeholder as LoginFlow
              stationName: widget.stationName,
            ),
          ),
          (route) => false,
        );
      },
      onAddAnotherStation: () {
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
                setState(() {
                  _stations = [..._stations, StationSummary(name: name, subtitle: location)];
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
      // TODO: no "edit station" screen exists yet.
      onEditStation: null,
    );
  }
}
