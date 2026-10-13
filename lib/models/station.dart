enum StationStatus { active, pending }

/// Brief summary of one station (name, status) - used on the Stations
/// Added confirmation screen. Not the full station record (that's the
/// Add Station form's job); just enough to render a card.
class StationSummary {
  final String name;
  final String subtitle;
  final StationStatus status;

  const StationSummary({
    required this.name,
    required this.subtitle,
    this.status = StationStatus.active,
  });

  /// Builds the list shown on the Stations Added screen from what was
  /// entered on the signup screen: the named station is active, any
  /// additional stations implied by "No. of Stations" show as pending
  /// until set up.
  static List<StationSummary> fromSignup({
    required String stationName,
    required int stationCount,
  }) {
    final list = [
      StationSummary(
        name: stationName.isEmpty ? 'Station 1' : stationName,
        subtitle: 'Primary station',
        status: StationStatus.active,
      ),
    ];
    for (var i = 2; i <= stationCount; i++) {
      list.add(
        StationSummary(
          name: 'Station $i',
          subtitle: 'Setup pending',
          status: StationStatus.pending,
        ),
      );
    }
    return list;
  }
}

/// A station as it appears in the Select Station switcher - just id+name,
/// nothing else.
class StationListItem {
  final String id;
  final String name;

  const StationListItem({required this.id, required this.name});
}
