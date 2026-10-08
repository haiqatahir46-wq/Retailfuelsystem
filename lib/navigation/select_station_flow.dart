import 'package:flutter/material.dart';
import '../screens/add_station_screen.dart';
import '../screens/location_search_screen.dart';
import '../screens/select_station_screen.dart';

/// Station switcher, with its own "+ Add Station" drill-down and an
/// "edit" action that opens the real Google Places location search -
/// LocationSearchScreen existed in the codebase but had nothing calling
/// it until this was wired up. Stateful: owns the stations list itself,
/// same reasoning as StaffFlow.
///
/// TODO: switching the selected station here only updates this flow's own
/// local state - it doesn't change which station's data Dashboard/Stock/
/// Logs show, since there's no app-wide "current station" state store yet
/// (would need something like Provider/Riverpod). Wire that up before
/// relying on this for real multi-station switching.
class SelectStationFlow extends StatefulWidget {
  final String stationId;
  final String stationName;

  @override
  State<SelectStationFlow> createState() => _SelectStationFlowState();

  const SelectStationFlow({super.key, required this.stationId, required this.stationName});
}

class _SelectStationFlowState extends State<SelectStationFlow> {
  late List<StationListItem> _stations = [StationListItem(id: widget.stationId, name: widget.stationName)];
  late String _selectedId = widget.stationId;

  @override
  Widget build(BuildContext context) {
    return SelectStationScreen(
      stations: _stations,
      selectedStationId: _selectedId,
      onStationSelected: (id) {
        setState(() => _selectedId = id);
        Navigator.of(context).pop();
      },
      onEditStation: (station) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LocationSearchScreen(
              onLocationSelected: (details) {
                setState(() {
                  _stations = [
                    for (final s in _stations)
                      if (s.id == station.id) StationListItem(id: s.id, name: details.formattedAddress) else s,
                  ];
                });
              },
            ),
          ),
        );
      },
      onAddStation: () {
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
                  _stations = [..._stations, StationListItem(id: 'station-${_stations.length + 1}', name: name)];
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }
}
