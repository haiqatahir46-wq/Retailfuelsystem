import 'package:flutter/material.dart';
import '../screens/staff_form_screen.dart';
import '../screens/staff_management_screen.dart';
import '../state/app_session.dart';
import 'route_guard.dart';
import 'server_action.dart';

/// Staff list, with its own "+ Add Staff" drill-down into the form. The
/// list lives in the session, so a new hire saved on the pushed form shows
/// up here straight away and is still there the next time Staff opens.
class StaffFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    return StaffManagementScreen(
      staff: session.staff,
      onBack: () => Navigator.of(context).pop(),
      onAddStaff: () {
        if (!isTopRoute(context)) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StaffFormScreen(
              stationName: session.currentStation?.name ?? '',
              onBack: () => Navigator.of(context).pop(),
              onSave: (values) async {
                // Guarded so a double tap on Save adds one person, not two
                // (with the server, the spinner covers the form meanwhile).
                if (!isTopRoute(context)) return;
                final saved = await runServerAction(
                  context,
                  () => session.addStaff(name: values.fullName, role: 'Attendant', phone: values.contactNumber),
                );
                if (saved && context.mounted) Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
      // TODO: no staff-edit screen exists yet - tapping a card does nothing.
      onStaffTap: null,
    );
  }

  const StaffFlow({super.key});
}
