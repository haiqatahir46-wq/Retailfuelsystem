import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/app_text.dart';
import 'stock_screen.dart' show TankStock;

/// Opened from the "Create Reorder" button on any tank card in
/// StockScreen - a SEPARATE screen from ThresholdScreen, reached
/// independently. Lists every tank (reusing the same TankStock data
/// StockScreen already shows, so the numbers never drift apart) with a
/// blank reorder-quantity field per tank - nothing pre-filled, the owner
/// enters how much they actually want to order. No bottom nav (this is a
/// drill-down, not a tab), just a back arrow to return to Stock.
class CreateReorderScreen extends StatefulWidget {
  final String stationName;
  final List<TankStock> tanks;
  final VoidCallback? onBack;
  final void Function(TankStock tank, double quantity)? onSubmitReorder;

  const CreateReorderScreen({
    super.key,
    required this.stationName,
    required this.tanks,
    this.onBack,
    this.onSubmitReorder,
  });

  @override
  State<CreateReorderScreen> createState() => _CreateReorderScreenState();
}

class _CreateReorderScreenState extends State<CreateReorderScreen> {
  late final Map<String, TextEditingController> _controllers = {
    for (final tank in widget.tanks) tank.fuelName: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit(TankStock tank) {
    final text = _controllers[tank.fuelName]!.text.trim();
    final value = double.tryParse(text);
    if (value != null) widget.onSubmitReorder?.call(tank, value);
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => ',',
      );

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
          for (final tank in widget.tanks) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
              ),
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
                      _Stat(label: 'Tank Capacity', value: '${_fmt(tank.capacity)} L'),
                      _Stat(label: 'Current Volume', value: '${_fmt(tank.currentVolume)} L'),
                      _Stat(label: 'Threshold', value: '${_fmt(tank.threshold)} L'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Reorder Quantity (L)',
                    hint: 'Enter litres to order',
                    controller: _controllers[tank.fuelName]!,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submit(tank),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText)),
        ],
      ),
    );
  }
}
