import 'package:flutter/material.dart';
import '../models/tank_stock.dart';
import 'app_colors.dart';

/// The one place a tank's health turns into a colour and a label, so the
/// Stock cards, the Tanks tab and anything else showing a tank badge stay
/// identical.
extension TankHealthStyle on TankHealth {
  Color get color {
    switch (this) {
      case TankHealth.healthy:
        return AppColors.statusDispensing;
      case TankHealth.low:
        return AppColors.statusAttention;
      case TankHealth.critical:
        return AppColors.statusFault;
    }
  }

  String get label {
    switch (this) {
      case TankHealth.healthy:
        return 'Healthy';
      case TankHealth.low:
        return 'Low';
      case TankHealth.critical:
        return 'Critical';
    }
  }
}
