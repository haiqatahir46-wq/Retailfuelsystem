import 'nozzle.dart';
import 'sales.dart';
import 'tank_stock.dart';

enum StationStatus { active, pending }

/// One of the owner's stations: what it is called, where it is and how it
/// is set up (its tanks and nozzles). The one station model behind Stations
/// Added, Select Station and the main tabs, so a station added or edited on
/// one screen is the same record every other screen shows.
class Station {
  /// Unique across every station. The demo stations are 'station-1' and
  /// 'station-2'; any station created in the app gets a fresh id from
  /// newId (lib/state/ids.dart), so it can never pick up a demo station's
  /// sales, orders or logs.
  final String id;
  final String name;

  /// Street address or area, e.g. from the Places search; '' when not set.
  final String location;

  /// Pending = implied by the signup form's "No. of Stations" but not set
  /// up yet, so it has no tanks or nozzles.
  final StationStatus status;

  /// Each tank's fixed setup. Current volumes are derived from sales by
  /// buildTanks (lib/data/demo_tanks.dart), never stored here.
  final List<TankConfig> tanks;

  /// Each nozzle with its latest pump reading.
  final List<Nozzle> nozzles;

  const Station({
    required this.id,
    required this.name,
    this.location = '',
    this.status = StationStatus.active,
    this.tanks = const [],
    this.nozzles = const [],
  });

  /// The id never changes: everything else about a station is keyed on it.
  Station copyWith({
    String? name,
    String? location,
    StationStatus? status,
    List<TankConfig>? tanks,
    List<Nozzle>? nozzles,
  }) {
    return Station(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      status: status ?? this.status,
      tanks: tanks ?? this.tanks,
      nozzles: nozzles ?? this.nozzles,
    );
  }

  /// The most stations one signup creates. "No. of Stations" is free text,
  /// and an unbounded loop over 999999999 would freeze the app.
  static const maxSignupStations = 20;

  /// The most nozzles of one grade the Add Station form creates, for the
  /// same reason.
  static const maxNozzlesPerGrade = 40;

  /// The largest tank capacity (litres) a form accepts. A retail station's
  /// underground tanks hold tens of thousands of litres each, so 1,000,000 L
  /// is far beyond any real one: it only stops a slip ("250000000") or a
  /// pasted giant number from becoming a tank whose figures overflow every
  /// card. Threshold and reorder limits sit inside a tank's capacity, so
  /// this bounds them too. For the Add Station capacity validators.
  static const maxCapacityLitres = 1000000.0;

  /// A new tank's reorder threshold as a fraction of its capacity, until the
  /// owner sets one on the Threshold screen. A quarter of the tank is a
  /// common reorder point when there is no sales history to size it from.
  /// The demo stations use a higher 18,000 L of 25,000 L because they sell
  /// far more each day.
  static const defaultThresholdFraction = 0.25;

  /// A typed station name, trimmed, or [fallback] when nothing but spaces
  /// was typed. Applied once, when the station is created, so the summary
  /// card, every screen title and the stored record all show the same name.
  static String normaliseName(String typed, {required String fallback}) {
    final trimmed = typed.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  /// The stations a new signup starts with: the named one is active, and
  /// any more implied by "No. of Stations" are pending until set up. The
  /// count is clamped to 1..[maxSignupStations], so 0, negative or huge
  /// input still gives a sensible, bounded list. None of them has tanks or
  /// nozzles yet. [newId] supplies each station's id.
  static List<Station> fromSignup({
    required String stationName,
    required int stationCount,
    required String Function() newId,
  }) {
    final count = stationCount.clamp(1, maxSignupStations);
    return [
      Station(id: newId(), name: normaliseName(stationName, fallback: 'Station 1')),
      for (var i = 2; i <= count; i++) Station(id: newId(), name: 'Station $i', status: StationStatus.pending),
    ];
  }

  /// A station set up through the Add Station form. Each grade with a
  /// usable capacity (finite and above 0) gets one tank, with the default
  /// threshold above. Each grade's nozzle count (clamped to
  /// 0..[maxNozzlesPerGrade]) becomes that many idle nozzles with nothing
  /// dispensed yet, two per pump and one grade per pump, the same layout as
  /// the demo stations. [nozzleCounts] and [capacities] are keyed by the
  /// names in kFuelGrades; [now] stamps the nozzles' first reading.
  factory Station.fromSetup({
    required String id,
    required String name,
    required String location,
    required Map<String, int> nozzleCounts,
    required Map<String, double> capacities,
    required DateTime now,
  }) {
    final tanks = <TankConfig>[];
    final nozzles = <Nozzle>[];
    var pump = 0;
    for (final grade in kFuelGrades) {
      final capacity = capacities[grade] ?? 0;
      if (capacity.isFinite && capacity > 0) {
        tanks.add(TankConfig(
          id: '$id-${grade.toLowerCase()}',
          fuelName: grade,
          capacity: capacity,
          threshold: capacity * defaultThresholdFraction,
        ));
      }
      final count = (nozzleCounts[grade] ?? 0).clamp(0, maxNozzlesPerGrade);
      for (var i = 0; i < count; i++) {
        if (i.isEven) pump++;
        final nozzleNumber = i.isEven ? 1 : 2;
        nozzles.add(Nozzle(
          id: '$id-p${pump}n$nozzleNumber',
          pumpNumber: pump,
          nozzleNumber: nozzleNumber,
          fuelName: grade,
          litres: 0,
          flowRate: 0,
          lastUpdated: now,
          status: NozzleStatus.idle,
        ));
      }
    }
    return Station(
      id: id,
      name: name,
      location: location.trim(),
      tanks: List.unmodifiable(tanks),
      nozzles: List.unmodifiable(nozzles),
    );
  }
}
