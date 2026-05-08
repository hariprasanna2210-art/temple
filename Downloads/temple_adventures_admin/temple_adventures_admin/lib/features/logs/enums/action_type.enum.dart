import 'package:dart_mappable/dart_mappable.dart';

part 'action_type.enum.mapper.dart';

@MappableEnum()
enum ActionType {
  signedIn,
  signedOut,
  bookingCreated,
  bookingDeleted,
  bookingPaxDeleted,
  bookingEdited,
  quickBookingCreated,
  quickBookingEdited,
  quickBookingDeleted,
  eventCreated,
  eventEdited,
  eventDeleted,
  addActivity,
  editActivity,
  deleteActivity,
  editEmployee,
  addEmployee,
  deleteEmployee,
}
