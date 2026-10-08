import 'dart:async';
import 'package:flutter/material.dart';
import '../services/google_places_service.dart';
import '../theme/app_colors.dart';

/// Search screen for picking a station's real-world location, backed by
/// the Google Places Autocomplete API (see google_places_service.dart for
/// the API key you need to set up first).
class LocationSearchScreen extends StatefulWidget {
  final ValueChanged<PlaceDetails> onLocationSelected;

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();

  const LocationSearchScreen({super.key, required this.onLocationSelected});
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _service = GooglePlacesService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<PlacePrediction> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String value) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _service.autocomplete(value);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _select(PlacePrediction prediction) async {
    setState(() => _loading = true);
    try {
      final details = await _service.getPlaceDetails(prediction.placeId);
      widget.onLocationSelected(details);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
          'Set Station Location',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderDivider),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
              decoration: InputDecoration(
                hintText: 'Search for the station\'s address...',
                hintStyle: const TextStyle(color: Color(0xFF9AA5B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.cardBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
          if (_loading) const LinearProgressIndicator(color: AppColors.brandRed, minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.statusFault, fontSize: 12.5),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderDivider),
              itemBuilder: (context, index) {
                final r = _results[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppColors.brandRed),
                  title: Text(
                    r.description,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.primaryText),
                  ),
                  onTap: () => _select(r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
