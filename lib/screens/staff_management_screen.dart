import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum StaffStatus { active, onLeave }

class StaffMember {
  final String id;
  final String name;
  final String role; // e.g. 'Manager', 'Attendant', 'Cashier'
  final String phone;
  final StaffStatus status;

  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    this.status = StaffStatus.active,
  });
}

/// Opened from the "Staff Management" row on ProfileScreen - the staff
/// headcount that used to sit in Profile's quick-stats row now has its own
/// full screen instead. No bottom nav (this is a drill-down, not a tab),
/// just a back arrow to return to Profile.
class StaffManagementScreen extends StatelessWidget {
  final List<StaffMember> staff;
  final VoidCallback? onBack;
  final VoidCallback? onAddStaff;
  final ValueChanged<StaffMember>? onStaffTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        title: const Text(
          'Staff Management',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primaryText),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderDivider),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${staff.length} Staff Member${staff.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          Expanded(
            child: staff.isEmpty
                ? const Center(
                    child: Text(
                      'No staff added yet.',
                      style: TextStyle(fontSize: 13.5, color: AppColors.secondaryText),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    itemCount: staff.length,
                    itemBuilder: (context, i) {
                      final member = staff[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StaffCard(member: member, onTap: () => onStaffTap?.call(member)),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onAddStaff,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandRed,
                    side: const BorderSide(color: AppColors.brandRed, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    '+ Add Staff',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  const StaffManagementScreen({
    super.key,
    required this.staff,
    this.onBack,
    this.onAddStaff,
    this.onStaffTap,
  });
}

class _StaffCard extends StatelessWidget {
  final StaffMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = member.status == StaffStatus.active;
    final initial = member.name.isNotEmpty ? member.name[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.redLightSelected,
              child: Text(
                initial,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brandRed),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${member.role} · ${member.phone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? AppColors.statusDispensing.withOpacity(0.12) : AppColors.statusAttention.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Active' : 'On Leave',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.statusDispensing : AppColors.statusAttention,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  const _StaffCard({required this.member, required this.onTap});
}
