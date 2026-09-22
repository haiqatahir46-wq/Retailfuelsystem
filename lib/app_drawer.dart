import 'package:flutter/material.dart';
import 'package:petrolpump_flutter/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback? onProfileTap;
  final VoidCallback? onHelpCenterTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    this.onProfileTap,
    this.onHelpCenterTap,
    this.onSettingsTap,
    this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.cardBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.redLightSelected,
                    child: Icon(Icons.person, color: AppColors.brandRed),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                        ),
                        Text(
                          userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderDivider),
            const SizedBox(height: 8),
            _DrawerItem(icon: Icons.person_outline, label: 'Profile', onTap: onProfileTap),
            _DrawerItem(icon: Icons.settings_outlined, label: 'Settings', onTap: onSettingsTap),
            _DrawerItem(icon: Icons.help_outline, label: 'Help Center', onTap: onHelpCenterTap),
            const Spacer(),
            const Divider(height: 1, color: AppColors.borderDivider),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Log Out',
              color: AppColors.statusFault,
              onTap: onLogoutTap,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _DrawerItem({required this.icon, required this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryText;
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.secondaryText, size: 22),
      title: Text(
        label,
        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c),
      ),
      onTap: onTap,
    );
  }
}
