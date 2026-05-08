import 'package:dart_mappable/dart_mappable.dart';

part 'access_levels.enum.mapper.dart';

@MappableEnum()
enum AccessLevels {
  viewUsers,
  addUser,
  editUser,
  viewBookings,
  addBooking,
  editBooking,
  boatPlan,
  conditions,
  generalInfo,
  addEquipment,
  viewEquipment,
  approveEquipment,
  roster,
  coastGuardSlip,
  customerDiveLogs,
  offers,
  upcomingEvents,
  viewActivities,
  addActivity,
  editActivity,
  viewAllBookings,
  logs,
  notifications,
}

extension AccessLevelsX on AccessLevels {
  String get label => switch (this) {
    AccessLevels.viewUsers => 'View Users',
    AccessLevels.addUser => 'Add User',
    AccessLevels.editUser => 'Edit User',
    AccessLevels.viewBookings => 'View Bookings',
    AccessLevels.addBooking => 'Add Booking',
    AccessLevels.editBooking => 'Edit Booking',
    AccessLevels.boatPlan => 'Boat Plan',
    AccessLevels.conditions => 'Conditions',
    AccessLevels.generalInfo => 'General Info',
    AccessLevels.addEquipment => 'Add Equipment',
    AccessLevels.viewEquipment => 'View Equipment',
    AccessLevels.approveEquipment => 'Approve Equipment',
    AccessLevels.roster => 'Roster',
    AccessLevels.coastGuardSlip => 'Coast Guard Slip',
    AccessLevels.customerDiveLogs => 'Customer Dive Logs',
    AccessLevels.offers => 'Offers',
    AccessLevels.upcomingEvents => 'Upcoming Events',
    AccessLevels.viewActivities => 'View Activities',
    AccessLevels.addActivity => 'Add Activity',
    AccessLevels.editActivity => 'Edit Activity',
    AccessLevels.viewAllBookings => 'View All Bookings',
    AccessLevels.logs => 'Logs',
    AccessLevels.notifications => 'Notifications',
  };
}
