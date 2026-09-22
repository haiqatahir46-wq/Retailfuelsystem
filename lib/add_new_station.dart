import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/app_text.dart';

/// Add New Station form. Deliberately plain - no photo/wave header, just a
/// simple app bar, per the Figma reference (station name/location, nozzle
/// counts per grade, storage capacity per grade).
class AddStationScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final void Function({
    required String name,
    required String location,
    required int petrolNozzles,
    required int dieselNozzles,
    required int hiOctaneNozzles,
    required double petrolCapacityL,
    required double dieselCapacityL,
    required double hiOctaneCapacityL,
  }) onAddStation;

  const AddStationScreen({super.key, required this.onAddStation, this.onBack});

  @override
  State<AddStationScreen> createState() => _AddStationScreenState();
}

class _AddStationScreenState extends State<AddStationScreen> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _petrolNozzles = TextEditingController();
  final _dieselNozzles = TextEditingController();
  final _octaneNozzles = TextEditingController();
  final _petrolCapacity = TextEditingController();
  final _dieselCapacity = TextEditingController();
  final _octaneCapacity = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _petrolNozzles.dispose();
    _dieselNozzles.dispose();
    _octaneNozzles.dispose();
    _petrolCapacity.dispose();
    _dieselCapacity.dispose();
    _octaneCapacity.dispose();
    super.dispose();
  }

  int _int(TextEditingController c) => int.tryParse(c.text) ?? 0;
  double _double(TextEditingController c) => double.tryParse(c.text) ?? 0;

  void _submit() {
    widget.onAddStation(
      name: _name.text,
      location: _location.text,
      petrolNozzles: _int(_petrolNozzles),
      dieselNozzles: _int(_dieselNozzles),
      hiOctaneNozzles: _int(_octaneNozzles),
      petrolCapacityL: _double(_petrolCapacity),
      dieselCapacityL: _double(_dieselCapacity),
      hiOctaneCapacityL: _double(_octaneCapacity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        title: const Text(
          'Add New Station',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: widget.onBack,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderDivider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Station Name',
              hint: 'e.g. Amir Filling, Pattoki',
              controller: _name,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Station Location',
              hint: 'Enter address or area',
              controller: _location,
            ),
            const _SectionLabel('Nozzles'),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Petrol',
                    hint: '0',
                    controller: _petrolNozzles,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Diesel',
                    hint: '0',
                    controller: _dieselNozzles,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Hi-Octane',
                    hint: '0',
                    controller: _octaneNozzles,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const _SectionLabel('Storage Capacity'),
            AppTextField(
              label: 'Petrol',
              hint: '0',
              controller: _petrolCapacity,
              keyboardType: TextInputType.number,
              suffixIcon: const _UnitLabel('L'),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Diesel',
              hint: '0',
              controller: _dieselCapacity,
              keyboardType: TextInputType.number,
              suffixIcon: const _UnitLabel('L'),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Hi-Octane',
              hint: '0',
              controller: _octaneCapacity,
              keyboardType: TextInputType.number,
              suffixIcon: const _UnitLabel('L'),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRed,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: AppColors.brandRed.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Add Station',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}

class _UnitLabel extends StatelessWidget {
  final String unit;
  const _UnitLabel(this.unit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        widthFactor: 1,
        child: Text(
          unit,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
        ),
      ),
    );
  }
}
