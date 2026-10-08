import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Opened from the drawer/Profile "Settings" entry. Kept small and
/// honest about what the app can actually do right now - a notifications
/// toggle (held in local state; wire to real push-notification
/// preferences once a backend exists) and Log Out, rather than switches
/// for features (like a dark theme) that don't exist elsewhere in the app.
class SettingsScreen extends StatefulWidget {
  final String appVersion;
  final VoidCallback? onBack;
  final VoidCallback? onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

  const SettingsScreen({
    super.key,
    this.appVersion = '1.0.0',
    this.onBack,
    this.onLogout,
  });
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _lowStockAlerts = true;
  bool _dailySummary = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primaryText),
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
            'NOTIFICATIONS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _SwitchRow(
                label: 'Low-stock alerts',
                value: _lowStockAlerts,
                onChanged: (v) => setState(() => _lowStockAlerts = v),
              ),
              const Divider(height: 1, color: AppColors.borderDivider),
              _SwitchRow(
                label: 'Daily sales summary',
                value: _dailySummary,
                onChanged: (v) => setState(() => _dailySummary = v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'ABOUT',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _InfoRow(label: 'App version', value: widget.appVersion),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusFault,
                side: const BorderSide(color: AppColors.statusFault, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(children: children),
    );
  }

  const _SettingsCard({required this.children});
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.primaryText),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.brandRed),
        ],
      ),
    );
  }

  const _SwitchRow({required this.label, required this.value, required this.onChanged});
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.primaryText),
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
        ],
      ),
    );
  }

  const _InfoRow({required this.label, required this.value});
}
