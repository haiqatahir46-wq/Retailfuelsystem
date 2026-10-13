import 'package:flutter/material.dart';
import '../models/sales.dart';
import '../models/tank_stock.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/tank_widgets.dart';

/// Opened from the "Create Reorder" button on any tank card in
/// StockScreen - a SEPARATE screen from ThresholdScreen, reached
/// independently. Lists every tank (reusing the same TankStock data
/// StockScreen already shows, so the numbers never drift apart) with a
/// blank reorder-quantity field per tank - nothing pre-filled, the owner
/// enters how much they actually want to order. No bottom nav (this is a
/// drill-down, not a tab), just a back arrow to return to Stock.
///
/// A quantity must be above 0 and fit in the space left in the tank
/// (capacity minus current volume; commas allowed). A full tank can't be
/// reordered: its field and Submit are disabled. After a valid Submit the
/// field empties for the next order.
class CreateReorderScreen extends StatefulWidget {
  final String stationName;
  final List<TankStock> tanks;
  final VoidCallback? onBack;
  final void Function(TankStock tank, double quantity)? onSubmitReorder;

  @override
  State<CreateReorderScreen> createState() => _CreateReorderScreenState();

  const CreateReorderScreen({
    super.key,
    required this.stationName,
    required this.tanks,
    this.onBack,
    this.onSubmitReorder,
  });
}

class _CreateReorderScreenState extends State<CreateReorderScreen> {
  // All keyed by tank id, not fuel name, so two tanks of the same grade each
  // keep their own field. Created on first use, so a tank that appears
  // while the screen is open gets one too.
  final _controllers = <String, TextEditingController>{};
  final _formKeys = <String, GlobalKey<FormState>>{};

  /// Tanks whose Submit has been tried: their field re-checks as it is
  /// edited, so an error clears as soon as it is fixed.
  final _tried = <String>{};

  TextEditingController _controllerFor(String id) => _controllers.putIfAbsent(id, TextEditingController.new);
  GlobalKey<FormState> _formKeyFor(String id) => _formKeys.putIfAbsent(id, GlobalKey<FormState>.new);

  /// Litres the tank can still take.
  static double _spaceLeft(TankStock tank) => (tank.capacity - tank.currentVolume).clamp(0.0, double.infinity);

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit(TankStock tank) {
    final form = _formKeyFor(tank.id).currentState!;
    if (!form.validate()) {
      setState(() => _tried.add(tank.id));
      return;
    }
    widget.onSubmitReorder?.call(tank, parseNumber(_controllerFor(tank.id).text)!);
    // Empty the field for the next order without flagging it: back to
    // checking only on the next Submit. (Not form.reset(): with a
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
            'Create Reorder',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 18),
          if (widget.tanks.isEmpty) const EmptyState('No tanks set up for this station yet.'),
          for (final tank in widget.tanks) _buildTankCard(tank),
        ],
      ),
    );
  }

  Widget _buildTankCard(TankStock tank) {
    final space = _spaceLeft(tank);
    final full = space <= 0;

    return Container(
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
              label: 'Reorder Quantity (L)',
              hint: full ? '' : 'Up to ${formatThousands(space)} L',
              controller: _controllerFor(tank.id),
              enabled: !full,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              validator: Validators.positiveNumber(
                max: space,
                maxMessage: 'Only ${formatThousands(space)} L of space left in this tank',
              ),
            ),
            if (full) ...[
              const SizedBox(height: 8),
              const Text(
                'Tank is full',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.statusDispensing),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: full ? null : () => _submit(tank),
              style: ElevatedButton.styleFrom(
                // A minimum height, not a fixed one, so larger text makes
                // the button taller instead of clipping its label.
                minimumSize: const Size.fromHeight(42),
                backgroundColor: AppColors.brandRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
