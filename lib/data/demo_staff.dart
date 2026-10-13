import '../models/staff.dart';

// Demo seed data: AppSession.signInDemo starts the demo account's staff
// list from this. Wire to a real staff backend later, the same way
// salesFor/purchaseOrdersFor/logsFor/nozzlesFor stand in for real data
// elsewhere until one exists.
const demoStaffMembers = [
  StaffMember(id: 's1', name: 'Bilal Ahmed', role: 'Manager', phone: '0300-1234567'),
  StaffMember(id: 's2', name: 'Usman Tariq', role: 'Attendant', phone: '0301-2345678'),
  StaffMember(id: 's3', name: 'Imran Shah', role: 'Cashier', phone: '0302-3456789', status: StaffStatus.onLeave),
];
