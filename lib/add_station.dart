import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/wave_clipper.dart';
import 'package:petrolpump_flutter/add_new_station.dart';

enum StationStatus { active, pending }

class StationSummary {
  final String name;
  final String subtitle;
  final StationStatus status;

  const StationSummary({
    required this.name,
    required this.subtitle,
    this.status = StationStatus.active,
  });

  /// Builds the list shown on this screen from what was entered on the
  /// signup screen: the named station is active, any additional stations
  /// implied by "No. of Stations" show as pending until set up.
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

/// Shown right after signup: confirms the station(s) tied to the new
/// account before continuing into the Dashboard. Same wave-photo header
/// family as the other auth screens (shortest yet - it's just a summary,
/// not a form).
class StationsAddedScreen extends StatelessWidget {
  final Widget? stationImage;
  final List<StationSummary> stations;
  final VoidCallback onContinue;
  final VoidCallback? onAddAnotherStation;
  final ValueChanged<StationSummary>? onEditStation;

  const StationsAddedScreen({
    super.key,
    required this.stations,
    required this.onContinue,
    this.stationImage,
    this.onAddAnotherStation,
    this.onEditStation,
  });

  // Shortest scene yet - this screen is a summary, not a form.
  static const double _sceneHeightFactor = 0.2790;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: _sceneHeightFactor,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: AppColors.cardBackground),
                child: ClipPath(
                  clipper: const WaveClipper(),
                  child: SizedBox.expand(
                    child: stationImage ?? const _StationPlaceholder(),
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 1 - _sceneHeightFactor,
              widthFactor: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.only(bottom: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F6EF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.statusDispensing,
                        size: 30,
                      ),
                    ),
                    const Text(
                      'Station Added',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your account is set up and ready to go',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'YOUR STATIONS (${stations.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...stations.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StationCard(
                          station: s,
                          onEdit: onEditStation == null ? null : () => onEditStation!(s),
                        ),
                      ),
                    ),
                    if (onAddAnotherStation != null) ...[
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: onAddAnotherStation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondaryText,
                            side: const BorderSide(
                              color: AppColors.borderDivider,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '+ Add Another Station',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandRed,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: AppColors.brandRed.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Continue to Dashboard',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final StationSummary station;
  final VoidCallback? onEdit;
  const _StationCard({required this.station, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.borderDivider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.redLightSelected,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_gas_station_outlined,
              color: AppColors.brandRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  station.subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.cardBackground,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.edit_outlined, color: AppColors.secondaryText, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationPlaceholder extends StatelessWidget {
  const _StationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB0141A), AppColors.brandRed],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_gas_station,
          size: 56,
          color: Colors.white.withOpacity(0.25),
        ),
      ),
    );
  }
}
