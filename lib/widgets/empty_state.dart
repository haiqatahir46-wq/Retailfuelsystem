import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A short, muted line shown where a list would be when there's nothing in
/// it (e.g. a newly added station with no tanks or orders yet), so the
/// screen says so instead of leaving a blank gap.
class EmptyState extends StatelessWidget {
  final String message;

  const EmptyState(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
      ),
    );
  }
}
