import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/app_text.dart';
import 'stock_screen.dart' show TankStock;

/// Opened from the "Set Threshold" button on any tank card in
/// StockScreen - a SEPARATE screen from CreateReorderScreen, reached
/// independently. Lists every tank (reusing the same TankStock data
/// StockScreen already shows, so the numbers never drift apart) with an
/// editable threshold field per tank. No bottom nav (this is a
/// drill-down, not a tab), just a back arrow to return to Stock.
class ThresholdScreen extends StatefulWidget {
  final String stationName;
  final List<TankStock> tanks;
  final VoidCallback? onBack;
  final void Function(TankStock tank, double newThreshold)? onConfirmThreshold;
  final void Function(TankStock tank)? onReorder;

  const ThresholdScreen({
    super.key,
    required this.stationName,
    required this.tanks,
    this.onBack,
    this.onConfirmThreshold,
    this.onReorder,
  });

  @override
  State<ThresholdScreen> createState() => _ThresholdScreenState();
}

class _ThresholdScreenState extends State<ThresholdScreen> {
  late final Map<String, TextEditingController> _controllers = {
    for (final tank in widget.tanks) tank.fuelName: TextEditingController(text: tank.threshold.toStringAsFixed(0)),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _confirm(TankStock tank) {
    final text = _controllers[tank.fuelName]!.text.trim();
    final value = double.tryParse(text);
    if (value != null) widget.onConfirmThreshold?.call(tank, value);
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
            'Reorder Threshold',
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Threshold (L)',
                    hint: '',
                    controller: _controllers[tank.fuelName]!,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: () => widget.onReorder?.call(tank),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondaryText,
                              side: const BorderSide(color: AppColors.borderDivider, width: 1.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            child: const Text('Reorder'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () => _confirm(tank),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            child: const Text('Confirm'),
                          ),
                        ),
                      ),
                    ],
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
