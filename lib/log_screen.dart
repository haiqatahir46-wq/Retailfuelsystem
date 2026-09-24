import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';
import 'package:petrolpump_flutter/bottom_nav.dart';
import 'package:petrolpump_flutter/app_text.dart';

enum LogStatus { completed, pending }

class VehicleLogEntry {
  final String vehicleType; // 'Self' or 'Carriage'
  final String fuelType;
  final String litres; // display value, e.g. '13,000L' - '-' if not dispensed yet
  final LogStatus status;

  const VehicleLogEntry({
    required this.vehicleType,
    required this.fuelType,
    required this.litres,
    required this.status,
  });
}

const demoLogEntries = [
  VehicleLogEntry(vehicleType: 'Self', fuelType: 'Petrol', litres: '13,000L', status: LogStatus.completed),
  VehicleLogEntry(vehicleType: 'Carriage', fuelType: 'Diesel', litres: '5,000L', status: LogStatus.completed),
  VehicleLogEntry(vehicleType: 'Self', fuelType: 'Hi-Octane', litres: '-', status: LogStatus.pending),
  VehicleLogEntry(vehicleType: 'Carriage', fuelType: 'Diesel', litres: '5,000L', status: LogStatus.completed),
  VehicleLogEntry(vehicleType: 'Carriage', fuelType: 'Diesel', litres: '5,000L', status: LogStatus.completed),
];

/// Opened from the "Logs" tab in the bottom nav. Same UX as the Figma
/// reference (Manual Vehicle Log form: Vehicle/Fuel Type/Pump-Nozzle/
/// Litres Dispensed/Total Amount/Transaction Status, Save Log + Clear,
/// then a Recent Entries list) - only the visual styling changed, from
/// the gray wireframe to PARCO's brand colors. Keeps the bottom nav,
/// since this is a tab, not a drill-down.
class LogsScreen extends StatefulWidget {
  final String stationName;
  final List<VehicleLogEntry> entries;
  final ValueChanged<int>? onNavTap;

  const LogsScreen({
    super.key,
    this.stationName = 'Amir Filling Station',
    this.entries = demoLogEntries,
    this.onNavTap,
  });

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  int _navIndex = 4; // Logs tab active

  String? _vehicle;
  String? _fuelType;
  String? _nozzle;
  String? _transactionStatus;
  final _litresController = TextEditingController();
  final _totalAmountController = TextEditingController();

  static const _vehicleOptions = ['Self', 'Carriage'];
  static const _fuelOptions = ['Petrol', 'Diesel', 'Hi-Octane'];
  static const _nozzleOptions = [
    'Nozzle 1', 'Nozzle 2', 'Nozzle 3', 'Nozzle 4', 'Nozzle 5',
    'Nozzle 6', 'Nozzle 7', 'Nozzle 8', 'Nozzle 9', 'Nozzle 10',
  ];
  static const _statusOptions = ['Completed', 'Pending'];

  @override
  void dispose() {
    _litresController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _vehicle = null;
      _fuelType = null;
      _nozzle = null;
      _transactionStatus = null;
      _litresController.clear();
      _totalAmountController.clear();
    });
  }

  void _saveLog() {
    // TODO: append a new VehicleLogEntry built from the current form
    // values to the real entries source once a backend/store exists.
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          const Text(
            'Manual Vehicle Log',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 16),
          _AppDropdown(
            label: 'Vehicle',
            value: _vehicle,
            options: _vehicleOptions,
            onChanged: (v) => setState(() => _vehicle = v),
          ),
          const SizedBox(height: 14),
          _AppDropdown(
            label: 'Fuel Type',
            value: _fuelType,
            options: _fuelOptions,
            onChanged: (v) => setState(() => _fuelType = v),
          ),
          const SizedBox(height: 14),
          _AppDropdown(
            label: 'Pump / Nozzle',
            value: _nozzle,
            options: _nozzleOptions,
            onChanged: (v) => setState(() => _nozzle = v),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Litres Dispensed (L)',
            hint: '',
            controller: _litresController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Total Amount',
            hint: '',
            controller: _totalAmountController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          _AppDropdown(
            label: 'Transaction Status',
            value: _transactionStatus,
            options: _statusOptions,
            onChanged: (v) => setState(() => _transactionStatus = v),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Save Log'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _clear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryText,
                      side: const BorderSide(color: AppColors.borderDivider, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Clear'),
                  ),
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
          _EntriesTable(entries: widget.entries),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          widget.onNavTap?.call(i);
        },
      ),
    );
  }
}

/// Dropdown styled to match AppTextField exactly (label above, rounded
/// bordered box, off-white fill, brand-red focus ring) so it fits the
/// same form as the plain text fields around it.
class _AppDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _AppDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

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
        SizedBox(
          height: 48,
          child: DropdownButtonFormField<String>(
            value: value,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryText),
            style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
            ),
          ),
        ),
      ],
    );
  }
}

class _EntriesTable extends StatelessWidget {
  final List<VehicleLogEntry> entries;
  const _EntriesTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Vehicle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText))),
                Expanded(flex: 3, child: Text('Fuel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText))),
                Expanded(flex: 3, child: Text('Litres', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText))),
                Expanded(
                  flex: 3,
                  child: Text('Status', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
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
}

class _EntryRow extends StatelessWidget {
  final VehicleLogEntry entry;
  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isCompleted = entry.status == LogStatus.completed;
    final statusColor = isCompleted ? AppColors.statusDispensing : AppColors.statusAttention;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(entry.vehicleType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
          ),
          Expanded(flex: 3, child: Text(entry.fuelType, style: const TextStyle(fontSize: 13, color: AppColors.primaryText))),
          Expanded(flex: 3, child: Text(entry.litres, style: const TextStyle(fontSize: 13, color: AppColors.primaryText))),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
