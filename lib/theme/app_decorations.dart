import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared box decorations, so the app's cards keep one look instead of
/// each screen re-typing the same shadow.
class AppDecorations {
  AppDecorations._();

  /// The soft drop shadow under every white card: black at 4% alpha,
  /// blur 4, nudged 1px down. Cards with a different corner radius use
  /// this directly in their own BoxDecoration.
  static const cardShadow = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// A white card with 16px corners and [cardShadow] - the tank cards on
  /// Stock, the Tanks tab, Threshold and Create Reorder.
  static const card = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: cardShadow,
  );
}
