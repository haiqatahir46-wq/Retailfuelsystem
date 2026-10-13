import 'package:flutter/material.dart';

/// Colors pulled directly from the PARCO / TotalEnergies app palette.
class AppColors {
  AppColors._();

  static const brandRed = Color(0xFFD71920); // Brand Red (Primary)
  static const redLightSelected = Color(0xFFFFF1F2); // Red Light (Selected)
  static const primaryText = Color(0xFF172B4D);
  static const secondaryText = Color(0xFF5E6C84);
  static const background = Color(0xFFF6F8FB); // off-white app background
  static const cardBackground = Color(0xFFFFFFFF);
  static const borderDivider = Color(0xFFE2E8F0);

  // Status colors
  static const statusDispensing = Color(0xFF22A06B);
  static const statusIdle = Color(0xFF8A94A6);
  static const statusAttention = Color(0xFFE08E0B);
  static const statusFault = Color(0xFFD64545);

  // Fuel grade colors: the dot, bar or line for each grade, the same on the
  // Dashboard's fuel breakdown, the report cards and every sales chart.
  static const fuelPetrol = brandRed;
  static const fuelDiesel = primaryText;
  static const fuelHiOctane = statusDispensing;

  /// The color for one of kFuelGrades (lib/models/sales.dart), matched by
  /// name like prices are; [secondaryText] for any other name.
  static Color fuel(String fuelName) {
    switch (fuelName) {
      case 'Petrol':
        return fuelPetrol;
      case 'Diesel':
        return fuelDiesel;
      case 'Hi-Octane':
        return fuelHiOctane;
      default:
        return secondaryText;
    }
  }
}
