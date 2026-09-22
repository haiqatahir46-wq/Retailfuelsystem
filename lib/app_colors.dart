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
}
