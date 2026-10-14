import 'package:flutter/material.dart';
import '../models/station.dart';
import '../theme/app_colors.dart';
import '../widgets/station_photo.dart';
import '../widgets/wave_clipper.dart';

/// Shown right after signup: confirms the station(s) tied to the new
/// account before continuing into the Dashboard. Same wave-photo header
/// family as the other auth screens (shortest yet - it's just a summary,
/// not a form).
class StationsAddedScreen extends StatelessWidget {
  final Widget? stationImage;
  final List<Station> stations;
  final VoidCallback onContinue;
  final VoidCallback? onAddAnotherStation;
  final ValueChanged<Station>? onEditStation;

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
                    child: stationImage ?? const StationPhoto(),
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
                        color: AppColors.statusDispensing.withValues(alpha: 0.12),
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
                    for (final (i, s) in stations.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StationCard(
                          station: s,
                          isPrimary: i == 0,
                          onEdit: onEditStation == null ? null : () => onEditStation!(s),
                        ),
                      ),
                    if (onAddAnotherStation != null) ...[
                      const SizedBox(height: 2),
                      OutlinedButton(
                        onPressed: onAddAnotherStation,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
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
                    ],
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.brandRed,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: AppColors.brandRed.withValues(alpha: 0.4),
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
  final Station station;

  /// The station named on the signup form (the first one).
  final bool isPrimary;
  final VoidCallback? onEdit;
  const _StationCard({required this.station, required this.isPrimary, this.onEdit});

  bool get _pending => station.status == StationStatus.pending;

  /// Pending stations say so; otherwise the location, if one was entered.
  String get _subtitle {
    if (_pending) return 'Setup pending';
    if (station.location.isNotEmpty) return station.location;
    return isPrimary ? 'Primary station' : 'Active';
  }

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
          // A pending station (not set up yet) gets a muted icon and an
          // amber "Setup pending", so it reads differently from the active
          // ones at a glance.
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _pending ? AppColors.statusAttention.withValues(alpha: 0.12) : AppColors.redLightSelected,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _pending ? Icons.hourglass_empty : Icons.local_gas_station_outlined,
              color: _pending ? AppColors.statusAttention : AppColors.brandRed,
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
                  _subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _pending ? FontWeight.w600 : FontWeight.w400,
                    color: _pending ? AppColors.statusAttention : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          // The same 36dp circle as before, inside a 48dp tap target (the
          // recommended minimum); the tooltip names it for a screen reader
          // too.
          Tooltip(
            message: 'Edit station',
            child: Material(
              type: MaterialType.transparency,
              child: InkResponse(
                onTap: onEdit,
                radius: 24,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: Ink(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(color: AppColors.cardBackground, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_outlined, color: AppColors.secondaryText, size: 18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
