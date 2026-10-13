import 'package:flutter/material.dart';
import '../models/sales.dart';
import '../models/tank_stock.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/tank_widgets.dart';

/// Opened from the "Set Threshold" button on any tank card in
/// StockScreen - a SEPARATE screen from CreateReorderScreen, reached
/// independently. Lists every tank (reusing the same TankStock data
/// StockScreen already shows, so the numbers never drift apart) with its
/// current threshold and a field for a new one. No bottom nav (this is a
/// drill-down, not a tab), just a back arrow to return to Stock.
///
/// A new threshold must be above 0 and no more than the tank holds
/// (commas allowed); the error shows under the field. After a valid
/// Confirm the field empties, and the card's Threshold figure shows the
/// new value once the flow has saved it.
class ThresholdScreen extends StatefulWidget {
  final String stationName;
  final List<TankStock> tanks;
  final VoidCallback? onBack;
  final void Function(TankStock tank, double newThreshold)? onConfirmThreshold;
  final void Function(TankStock tank)? onReorder;

  @override
  State<ThresholdScreen> createState() => _ThresholdScreenState();

  const ThresholdScreen({
    super.key,
    required this.stationName,
    required this.tanks,
    this.onBack,
    this.onConfirmThreshold,
    this.onReorder,
  });
}

class _ThresholdScreenState extends State<ThresholdScreen> {
  // All keyed by tank id, not fuel name, so two tanks of the same grade each
  // keep their own field. Created on first use, so a tank that appears
  // while the screen is open gets one too.
  final _controllers = <String, TextEditingController>{};
  final _formKeys = <String, GlobalKey<FormState>>{};

  /// Tanks whose Confirm has been tried: their field re-checks as it is
  /// edited, so an error clears as soon as it is fixed.
  final _tried = <String>{};

  TextEditingController _controllerFor(String id) => _controllers.putIfAbsent(id, TextEditingController.new);
  GlobalKey<FormState> _formKeyFor(String id) => _formKeys.putIfAbsent(id, GlobalKey<FormState>.new);

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _confirm(TankStock tank) {
    final form = _formKeyFor(tank.id).currentState!;
    if (!form.validate()) {
      setState(() => _tried.add(tank.id));
      return;
    }
    widget.onConfirmThreshold?.call(tank, parseNumber(_controllerFor(tank.id).text)!);
    // Empty the field for the next value without flagging it: back to
    // checking only on the next Confirm. (Not form.reset(): with a
    // controller, that can restore an older value behind the field.)
    setState(() => _tried.remove(tank.id));
    _controllerFor(tank.id).clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: Text(
          widget.stationName,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderDivider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'Reorder Threshold',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 18),
          if (widget.tanks.isEmpty) const EmptyState('No tanks set up for this station yet.'),
          for (final tank in widget.tanks)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: AppDecorations.card,
              child: Form(
                key: _formKeyFor(tank.id),
                autovalidateMode: _tried.contains(tank.id) ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tank.fuelName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TankStat(label: 'Tank Capacity', value: '${formatThousands(tank.capacity)} L'),
                        TankStat(label: 'Current Volume', value: '${formatThousands(tank.currentVolume)} L'),
                        TankStat(label: 'Threshold', value: '${formatThousands(tank.threshold)} L'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Threshold (L)',
                      hint: 'New threshold, up to ${formatThousands(tank.capacity)}',
                      controller: _controllerFor(tank.id),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      validator: Validators.positiveNumber(
                        max: tank.capacity,
                        maxMessage: "Can't be more than the tank holds (${formatThousands(tank.capacity)} L)",
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Minimum heights, not fixed ones, so larger text
                        // makes the buttons taller instead of clipping.
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => widget.onReorder?.call(tank),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              foregroundColor: AppColors.secondaryText,
                              side: const BorderSide(color: AppColors.borderDivider, width: 1.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            child: const Text('Reorder'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _confirm(tank),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              backgroundColor: AppColors.brandRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            child: const Text('Confirm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
