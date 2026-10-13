import 'package:flutter/material.dart';
import '../models/tank_stock.dart';
import '../theme/app_colors.dart';
import '../theme/tank_health_style.dart';

/// A tank card's first line: the grade on the left and its health badge on
/// the right. Shared by the Stock cards and the Tanks tab so the two stay
/// identical. A long name is cut short instead of pushing the badge off.
class TankCardHeader extends StatelessWidget {
  final TankStock tank;

  const TankCardHeader({super.key, required this.tank});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            tank.fuelName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
        ),
        const SizedBox(width: 8),
        TankHealthBadge(health: tank.health),
      ],
    );
  }
}

/// The Healthy / Low / Critical pill, colored by [TankHealthStyle].
class TankHealthBadge extends StatelessWidget {
  final TankHealth health;

  const TankHealthBadge({super.key, required this.health});

  @override
  Widget build(BuildContext context) {
    final color = health.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(health.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// One figure on a tank card (Current Volume, Tank Capacity, Threshold):
/// the value over its label, taking an equal share of the row. The value
/// shrinks to fit rather than wrapping when the column is narrow.
class TankStat extends StatelessWidget {
  final String label;
  final String value;

  const TankStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText)),
        ],
      ),
    );
  }
}
