import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StationListItem {
  final String id;
  final String name;

  const StationListItem({required this.id, required this.name});
}

/// Station list/selector. Plain - no photo/wave header. Each row shows the
/// station name and an edit (pencil) action, not a status pill - the
/// selected station is filled brand-red, others sit on plain cards.
class SelectStationScreen extends StatefulWidget {
  final List<StationListItem> stations;
  final String selectedStationId;
  final ValueChanged<String> onStationSelected;
  final ValueChanged<StationListItem> onEditStation;
  final VoidCallback onAddStation;

  @override
  State<SelectStationScreen> createState() => _SelectStationScreenState();

  const SelectStationScreen({
    super.key,
    required this.stations,
    required this.selectedStationId,
    required this.onStationSelected,
    required this.onEditStation,
    required this.onAddStation,
  });
}

class _SelectStationScreenState extends State<SelectStationScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.stations
        : widget.stations
            .where((s) => s.name.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(bottom: BorderSide(color: AppColors.borderDivider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Station',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 46,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Select station......',
                      hintStyle: const TextStyle(color: Color(0xFF9AA5B8), fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final station = visible[i];
                final selected = station.id == widget.selectedStationId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StationRow(
                    station: station,
                    selected: selected,
                    onTap: () => widget.onStationSelected(station.id),
                    onEdit: () => widget.onEditStation(station),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(top: BorderSide(color: AppColors.borderDivider)),
          ),
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: widget.onAddStation,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandRed,
                side: const BorderSide(color: AppColors.brandRed, width: 1.5, style: BorderStyle.solid),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                '+ Add Station',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  final StationListItem station;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primaryText;
    final iconBg = selected ? Colors.white.withOpacity(0.18) : AppColors.redLightSelected;
    final iconColor = selected ? Colors.white : AppColors.brandRed;
    final actionBg = selected ? Colors.white.withOpacity(0.18) : AppColors.background;
    final actionColor = selected ? Colors.white : AppColors.secondaryText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandRed : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.brandRed : AppColors.borderDivider),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.local_gas_station_outlined, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected ? 'Currently selected' : 'Tap to switch',
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white.withOpacity(0.8) : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: actionBg,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(Icons.edit_outlined, color: actionColor, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  const _StationRow({
    required this.station,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });
}
