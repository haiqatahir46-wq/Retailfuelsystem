import 'package:flutter/material.dart';
import '../models/station.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';

/// Add New Station form. Deliberately plain - no photo/wave header, just a
/// simple app bar, per the Figma reference (station name/location, nozzle
/// counts per grade, storage capacity per grade).
///
/// Add Station only goes ahead once the form is valid: a name and a
/// location; each nozzle count a whole number from 0 to
/// [Station.maxNozzlesPerGrade] (blank = 0) with at least one nozzle in
/// all; and a capacity above 0 for every grade that has nozzles. Numbers
/// may be typed with commas ("20,000").
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

  @override
  State<AddStationScreen> createState() => _AddStationScreenState();

  const AddStationScreen({super.key, required this.onAddStation, this.onBack});
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
  final _formKey = GlobalKey<FormState>();

  /// Off until the first Add Station, then on, so errors only appear once
  /// the owner has tried to submit and then clear as each is fixed.
  var _autovalidate = AutovalidateMode.disabled;

  /// Shown under the nozzle counts when they add up to 0 - a station with
  /// no nozzles can't sell anything.
  String? _noNozzlesError;

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

  /// A validated field's value; blank means 0.
  int _int(TextEditingController c) => parseWholeNumber(c.text) ?? 0;
  double _double(TextEditingController c) => parseNumber(c.text) ?? 0;

  int get _totalNozzles => _int(_petrolNozzles) + _int(_dieselNozzles) + _int(_octaneNozzles);

  static final _nozzleCount = Validators.intInRange(0, Station.maxNozzlesPerGrade, required: false);

  /// A grade's capacity: required (above 0) once that grade has nozzles,
  /// otherwise optional, but a number from 0 up if typed.
  FormFieldValidator<String> _capacityValidator(TextEditingController nozzles) {
    final required = Validators.positiveNumber();
    return (value) {
      final text = (value ?? '').trim();
      if (_int(nozzles) > 0) return required(text) == null ? null : 'Enter a capacity above 0 for these nozzles';
      if (text.isEmpty) return null;
      return parseNumber(text) == null ? 'Enter a number, e.g. 20,000' : null;
    };
  }

  void _submit() {
    final fieldsValid = _formKey.currentState!.validate();
    final enoughNozzles = _totalNozzles > 0;
    setState(() {
      _autovalidate = AutovalidateMode.onUserInteraction;
      _noNozzlesError = enoughNozzles ? null : 'Add at least one nozzle';
    });
    if (!fieldsValid || !enoughNozzles) return;
    widget.onAddStation(
      name: _name.text.trim(),
      location: _location.text.trim(),
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
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Station Name',
                hint: 'e.g. Amir Filling, Pattoki',
                controller: _name,
                textInputAction: TextInputAction.next,
                validator: Validators.requiredText('Enter the station name'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Station Location',
                hint: 'Enter address or area',
                controller: _location,
                textInputAction: TextInputAction.next,
                validator: Validators.requiredText('Enter the location'),
              ),
              const _SectionLabel('Nozzles'),
              Row(
                // Top-aligned, so one field's error line doesn't shift the
                // other two boxes down.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, (label, controller)) in [
                    ('Petrol', _petrolNozzles),
                    ('Diesel', _dieselNozzles),
                    ('Hi-Octane', _octaneNozzles),
                  ].indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: label,
                        hint: '0',
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: _nozzleCount,
                        // The total-nozzles message goes once there are some.
                        onChanged: (_) {
                          if (_noNozzlesError != null && _totalNozzles > 0) setState(() => _noNozzlesError = null);
                        },
                      ),
                    ),
                  ],
                ],
              ),
              if (_noNozzlesError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _noNozzlesError!,
                    style: const TextStyle(fontSize: 12, color: AppColors.statusFault),
                  ),
                ),
              const _SectionLabel('Storage Capacity'),
              AppTextField(
                label: 'Petrol',
                hint: '0',
                controller: _petrolCapacity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                suffixIcon: const _UnitLabel('L'),
                validator: _capacityValidator(_petrolNozzles),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Diesel',
                hint: '0',
                controller: _dieselCapacity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                suffixIcon: const _UnitLabel('L'),
                validator: _capacityValidator(_dieselNozzles),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Hi-Octane',
                hint: '0',
                controller: _octaneCapacity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                suffixIcon: const _UnitLabel('L'),
                validator: _capacityValidator(_octaneNozzles),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.brandRed,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: AppColors.brandRed.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Add Station',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
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
