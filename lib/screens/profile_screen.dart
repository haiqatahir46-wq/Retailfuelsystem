import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';

/// Station profile screen - opened from the Profile icon in the
/// Dashboard's top bar. Matches the Figma reference (avatar + stat row,
/// owner name/address, Edit Profile, Account Details/Staff Management/
/// Help & Support, Log Out) with ONE deliberate change: the "Staff" stat
/// is dropped from the quick stats row - staff headcount doesn't belong
/// as a summary number here, it gets its own full screen instead (see
/// StaffManagementScreen).
class ProfileScreen extends StatefulWidget {
  final String stationName;
  final String ownerName;
  final String address;
  final int nozzleCount;
  final int yearsActive;
  final Widget? profileImage;
  final int navIndex;
  final ValueChanged<int>? onNavTap;
  final VoidCallback? onBack;
  final VoidCallback? onEditProfile;
  final VoidCallback? onAccountDetailsTap;
  final VoidCallback? onStaffManagementTap;
  final VoidCallback? onHelpSupportTap;
  final VoidCallback? onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();

  const ProfileScreen({
    super.key,
    required this.stationName,
    required this.ownerName,
    required this.address,
    required this.nozzleCount,
    required this.yearsActive,
    this.profileImage,
    this.navIndex = 0,
    this.onNavTap,
    this.onBack,
    this.onEditProfile,
    this.onAccountDetailsTap,
    this.onStaffManagementTap,
    this.onHelpSupportTap,
    this.onLogout,
  });
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _navIndex = widget.navIndex;

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
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderDivider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          // Avatar + stat row, side by side - matches the Figma reference's
          // layout (picture on the left, stat columns to its right on the
          // same line), just without the "Staff" column.
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.redLightSelected,
                child: widget.profileImage ?? const Icon(Icons.person, size: 32, color: AppColors.brandRed),
              ),
              const SizedBox(width: 24),
              _ProfileStat(value: '${widget.nozzleCount}', label: 'Nozzles'),
              const SizedBox(width: 32),
              _ProfileStat(value: '${widget.yearsActive}', label: 'Years'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.ownerName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 4),
          Text(
            widget.address,
            style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ProfileListRow(
            icon: Icons.badge_outlined,
            label: 'Account Details',
            onTap: widget.onAccountDetailsTap,
          ),
          _ProfileListRow(
            icon: Icons.groups_outlined,
            label: 'Staff Management',
            onTap: widget.onStaffManagementTap,
          ),
          _ProfileListRow(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: widget.onHelpSupportTap,
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

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
      ],
    );
  }

  const _ProfileStat({required this.value, required this.label});
}

class _ProfileListRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderDivider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.brandRed),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.primaryText),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  const _ProfileListRow({required this.icon, required this.label, this.onTap});
}
