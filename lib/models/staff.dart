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
