import 'package:flutter/material.dart';
import '../screens/staff_form_screen.dart';
import '../screens/staff_management_screen.dart';

// Demo seed data - wire to a real staff backend later, the same way
// demoTankStock/demoPurchaseOrders/demoLogEntries stand in for real data
// elsewhere until one exists.
const _demoStaffMembers = [
  StaffMember(id: 's1', name: 'Bilal Ahmed', role: 'Manager', phone: '0300-1234567'),
  StaffMember(id: 's2', name: 'Usman Tariq', role: 'Attendant', phone: '0301-2345678'),
  StaffMember(id: 's3', name: 'Imran Shah', role: 'Cashier', phone: '0302-3456789', status: StaffStatus.onLeave),
];

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
  List<StaffMember> _staff = _demoStaffMembers;

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
