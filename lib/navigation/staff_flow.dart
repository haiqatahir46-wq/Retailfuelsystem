import 'package:flutter/material.dart';
import '../data/demo_staff.dart';
import '../models/staff.dart';
import '../screens/staff_form_screen.dart';
import '../screens/staff_management_screen.dart';

/// Staff list, with its own "+ Add Staff" drill-down into the form.
/// Stateful so it owns the staff list itself: a new hire added via the
/// form needs to show up in THIS list without the whole screen being
/// rebuilt from scratch - same reasoning as StationsAddedFlow.
class StaffFlow extends StatefulWidget {
  final String stationName;

  @override
  State<StaffFlow> createState() => _StaffFlowState();

  const StaffFlow({super.key, required this.stationName});
}

class _StaffFlowState extends State<StaffFlow> {
  List<StaffMember> _staff = demoStaffMembers;

  @override
  Widget build(BuildContext context) {
    return StaffManagementScreen(
      staff: _staff,
      onBack: () => Navigator.of(context).pop(),
      onAddStaff: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StaffFormScreen(
              stationName: widget.stationName,
              onBack: () => Navigator.of(context).pop(),
              onSave: (values) {
                setState(() {
                  _staff = [
                    ..._staff,
                    StaffMember(
                      id: 's${_staff.length + 1}',
                      name: values.fullName,
                      role: 'Attendant',
                      phone: values.contactNumber,
                    ),
                  ];
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
      // TODO: no staff-edit screen exists yet - tapping a card does nothing.
      onStaffTap: null,
    );
  }
}
