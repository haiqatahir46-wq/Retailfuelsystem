import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The TOTAL PARCO station photo used by every photo banner (Splash, Login,
/// Signup, Stations Added, Dashboard and Stock). Fills
/// whatever box it's given; the parent decides the height and any wave
/// clip. The alignment keeps the canopy and signage in frame rather than
/// the sky.
///
/// If the asset can't be loaded (e.g. it was removed from pubspec.yaml's
/// assets), it falls back to the brand placeholder - a pale red panel with
/// a fuel-pump icon - instead of Flutter's error box.
class StationPhoto extends StatelessWidget {
  const StationPhoto({super.key});

  static const assetPath = 'assets/images/station.webp';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      alignment: const Alignment(0, 0.2),
      errorBuilder: (context, error, stackTrace) => const _BrandPlaceholder(),
    );
  }
}

class _BrandPlaceholder extends StatelessWidget {
  const _BrandPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.redLightSelected,
      alignment: Alignment.center,
      child: const Icon(Icons.local_gas_station, size: 40, color: AppColors.brandRed),
    );
  }
}
