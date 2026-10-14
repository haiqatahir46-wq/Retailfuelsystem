import 'package:flutter/material.dart';
import '../models/delivery_vehicle.dart';
import '../models/log_entry.dart';
import '../models/nozzle.dart';
import '../models/sales.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../utils/validators.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state.dart';

/// Opened from the "Logs" tab in the bottom nav. Same UX as the Figma
/// reference (Manual Vehicle Log form: Vehicle/Fuel Type/Pump-Nozzle/
/// Litres Dispensed/Total Amount/Transaction Status, Save Log + Clear,
/// then a Recent Entries list) - only the visual styling changed, from
/// the gray wireframe to PARCO's brand colors. Keeps the bottom nav,
/// since this is a tab, not a drill-down.
///
/// [entries] and [nozzles] are ONE station's, from the session
/// (MainTabsFlow passes session.logsFor / session.nozzlesFor): the Recent
/// Entries and the Pump / Nozzle options never come from another station.
///
/// Pump / Nozzle lists only the nozzles of the chosen Fuel Type (a nozzle
/// pumps one grade), so the nozzle and the price behind Total Amount always
/// agree; changing the fuel clears a nozzle of the old grade. With no
/// nozzle to pick (none for that grade, or none at all) a message stands
/// in for the dropdown and the form can't be saved.
///
/// Save Log checks the form (vehicle, fuel, nozzle, and litres above 0 and
/// up to [VehicleLogEntry.maxLitres] are required) but can't store anything
/// yet, so a valid form only says so.
class LogsScreen extends StatefulWidget {
  final String stationName;
  final List<VehicleLogEntry> entries;
  final List<Nozzle> nozzles;
  final ValueChanged<int> onNavTap;

  @override
  State<LogsScreen> createState() => _LogsScreenState();

  const LogsScreen({
    super.key,
    required this.stationName,
    required this.entries,
    required this.nozzles,
    required this.onNavTap,
  });
}

class _LogsScreenState extends State<LogsScreen> {
  DeliveryVehicle? _vehicle;
  String? _fuelType;

  /// The chosen nozzle's id. An id rather than the Nozzle: the session
  /// hands out fresh Nozzle objects on every read, and the dropdown matches
  /// its value by ==.
  String? _nozzleId;
  String? _transactionStatus;
  final _litresController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// Off until the first Save Log, then on, so errors only appear once the
  /// owner has tried to save and then clear as each field is fixed.
  var _autovalidate = AutovalidateMode.disabled;

  // Bumped by Clear. Each field's key includes it, so Clear swaps in fresh
  // fields built from the (now empty) values above, with no error showing -
  // a form field only reads its initialValue when it's first created.
  int _formGeneration = 0;

  static const _statusOptions = ['Completed', 'Pending'];

  @override
  void initState() {
    super.initState();
    // Total Amount is derived from the litres typed, so redraw on every
    // keystroke (and when Clear empties the field).
    _litresController.addListener(_onLitresChanged);
  }

  @override
  void dispose() {
    _litresController.removeListener(_onLitresChanged);
    _litresController.dispose();
    super.dispose();
  }

  void _onLitresChanged() => setState(() {});

  /// The litres typed, or null if the field is empty or isn't a usable
  /// number. Commas are allowed, since that's how the app displays litres.
  double? get _litres => parseNumber(_litresController.text);

  /// Litres × the selected grade's price - never typed in by hand, so it
  /// can't disagree with the litres next to it. 0 until both are chosen.
  double get _totalAmount {
    final litres = _litres;
    final fuel = _fuelType;
    if (litres == null || fuel == null) return 0;
    return litres * pricePerLitre(fuel);
  }

  void _clear() {
    // Not _formKey.currentState.reset(): with a controller, that can leave
    // the field's value out of step with its text. Emptying the controller
    // and rebuilding every field (the generation below) drops the errors.
    _litresController.clear();
    setState(() {
      _vehicle = null;
      _fuelType = null;
      _nozzleId = null;
      _transactionStatus = null;
      _autovalidate = AutovalidateMode.disabled;
      _formGeneration++;
    });
  }

  void _saveLog() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    // TODO: Save Log isn't built yet - hand a new VehicleLogEntry built
    // from the current form values to the flow (an onSaveLog callback), to
    // keep in the session's logs and later the backend.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text("Saving logs isn't available yet.")));
  }

  /// Fuel Type changed. A nozzle pumps one grade, so one picked for the
  /// old grade no longer fits and is cleared.
  void _onFuelChanged(String? fuel) {
    setState(() {
      if (fuel != _fuelType) _nozzleId = null;
      _fuelType = fuel;
    });
  }

  /// The Pump / Nozzle field: a dropdown of the chosen grade's nozzles
  /// (disabled until a grade is chosen), or, when there is no nozzle to
  /// pick, a message saying why. That message is a form field that never
  /// validates, so Save Log can't go ahead without a nozzle.
  Widget _buildNozzleField() {
    const label = 'Pump / Nozzle';
    final fuel = _fuelType;
    final options = [
      for (final n in widget.nozzles)
        if (n.fuelName == fuel) n,
    ];
    final String? unavailable;
    if (widget.nozzles.isEmpty) {
      unavailable = 'No nozzles set up for this station yet, so there is nothing to log.';
    } else if (fuel != null && options.isEmpty) {
      unavailable = 'No $fuel nozzles at this station. Choose another fuel type.';
    } else {
      unavailable = null;
    }

    if (unavailable != null) {
      return FormField<String>(
        key: ValueKey('nozzle-none-$_formGeneration'),
        validator: (_) => unavailable,
        // The notice already says what's wrong, so the error isn't shown
        // a second time under it.
        builder: (_) => _FieldNotice(label: label, message: unavailable!),
      );
    }
    return _AppDropdown<String>(
      key: ValueKey('nozzle-$_formGeneration'),
      label: label,
      value: _nozzleId,
      options: [for (final n in options) n.id],
      optionLabel: (id) => options.firstWhere((n) => n.id == id).name,
      disabledHint: 'Choose the fuel type first',
      onChanged: (v) => setState(() => _nozzleId = v),
      validator: (v) => v == null ? 'Choose the pump and nozzle' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        title: Text(
          widget.stationName,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderDivider),
        ),
      ),
      // A Column in a scroll view rather than a ListView: a ListView only
      // builds the rows on screen, and Form.validate can't check a field
      // that has been scrolled away and disposed.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Manual Vehicle Log',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
              ),
              const SizedBox(height: 16),
              _AppDropdown<DeliveryVehicle>(
                key: ValueKey('vehicle-$_formGeneration'),
                label: 'Vehicle',
                value: _vehicle,
                options: DeliveryVehicle.values,
                optionLabel: (v) => v.label,
                onChanged: (v) => setState(() => _vehicle = v),
                validator: (v) => v == null ? 'Choose the vehicle' : null,
              ),
              const SizedBox(height: 14),
              _AppDropdown<String>(
                key: ValueKey('fuel-$_formGeneration'),
                label: 'Fuel Type',
                value: _fuelType,
                options: kFuelGrades,
                optionLabel: (v) => v,
                onChanged: _onFuelChanged,
                validator: (v) => v == null ? 'Choose the fuel type' : null,
              ),
              const SizedBox(height: 14),
              _buildNozzleField(),
              const SizedBox(height: 14),
              AppTextField(
                key: ValueKey('litres-$_formGeneration'),
                label: 'Litres Dispensed (L)',
                hint: '',
                controller: _litresController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.positiveNumber(
                  max: VehicleLogEntry.maxLitres,
                  maxMessage: 'Too large (max ${formatLimit(VehicleLogEntry.maxLitres)} L in one log)',
                ),
              ),
              const SizedBox(height: 14),
              _ReadOnlyField(label: 'Total Amount', value: 'PKR ${formatThousands(_totalAmount)}'),
              const SizedBox(height: 14),
              _AppDropdown<String>(
                key: ValueKey('status-$_formGeneration'),
                label: 'Transaction Status',
                value: _transactionStatus,
                options: _statusOptions,
                optionLabel: (v) => v,
                onChanged: (v) => setState(() => _transactionStatus = v),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveLog,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.brandRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Save Log'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.secondaryText,
                        side: const BorderSide(color: AppColors.borderDivider, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Recent Entries',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const EmptyState('No vehicle log entries for this station yet.')
              else
                _EntriesTable(entries: entries),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: AppTab.logs, onTap: widget.onNavTap),
    );
  }
}

/// Dropdown styled to match AppTextField exactly (label above, rounded
/// bordered box, off-white fill, brand-red focus ring) so it fits the
/// same form as the plain text fields around it.
///
/// [value] seeds the field when it's created (and the field follows it when
/// it changes); to reset a filled-in dropdown, the parent gives it a new key.
/// A surrounding Form checks it with [validator]; like AppTextField it has
/// no fixed height, so an error line or larger text isn't clipped. With no
/// [options] it is disabled and shows [disabledHint].
class _AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> options;
  final String Function(T option) optionLabel;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          // Expanded, with each option cut short if need be, so a long
          // option like "Pump 1 · Nozzle 2" can't overflow a narrow form.
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryText),
          style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
          items: options
              .map(
                (o) => DropdownMenuItem<T>(
                  value: o,
                  child: Text(optionLabel(o), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator,
          disabledHint: disabledHint == null
              ? null
              : Text(
                  disabledHint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
                ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            isDense: true,
            // About the 48dp of AppTextField at normal text size.
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.brandRed, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.statusFault),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.statusFault, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  const _AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
    this.validator,
    this.disabledHint,
  });
}

/// A message in place of a form field, laid out like one (label above, a
/// rounded box at least 48dp tall): for a field that has nothing to offer,
/// such as Pump / Nozzle at a station with no nozzles of the chosen grade.
class _FieldNotice extends StatelessWidget {
  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.statusAttention.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.statusAttention.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.statusAttention),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  const _FieldNotice({required this.label, required this.message});
}

/// A computed, non-editable value laid out like AppTextField (label above,
/// a rounded box at least 48dp tall) so it sits naturally in the form - but
/// with no text cursor, since there's nothing to type.
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDivider),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText),
          ),
        ),
      ],
    );
  }

  const _ReadOnlyField({required this.label, required this.value});
}

class _EntriesTable extends StatelessWidget {
  final List<VehicleLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Vehicle',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Fuel',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Litres',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Status',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderDivider),
          for (var i = 0; i < entries.length; i++) ...[
            _EntryRow(entry: entries[i]),
            if (i != entries.length - 1) const Divider(height: 1, color: AppColors.borderDivider),
          ],
        ],
      ),
    );
  }

  const _EntriesTable({required this.entries});
}

class _EntryRow extends StatelessWidget {
  final VehicleLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final isCompleted = entry.status == LogStatus.completed;
    final statusColor = isCompleted ? AppColors.statusDispensing : AppColors.statusAttention;
    final litres = entry.litres;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              entry.vehicle.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryText),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(entry.fuelType, style: const TextStyle(fontSize: 13, color: AppColors.primaryText)),
          ),
          Expanded(
            flex: 3,
            // '-' while nothing has been dispensed yet (a pending entry).
            child: Text(
              litres == null ? '-' : '${formatThousands(litres)} L',
              style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
            ),
          ),
          Expanded(
            flex: 3,
            // The pill shrinks to fit its quarter of the row rather than
            // overflowing it on a narrow screen or with larger text.
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'Pending',
                    maxLines: 1,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  const _EntryRow({required this.entry});
}
