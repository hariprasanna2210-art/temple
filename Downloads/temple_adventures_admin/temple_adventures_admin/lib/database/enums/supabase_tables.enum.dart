import 'package:dart_mappable/dart_mappable.dart';
part 'supabase_tables.enum.mapper.dart';

@MappableEnum(caseStyle: CaseStyle.snakeCase)
enum SupabaseTable {
  users,
  activityColors,
  activities,
  bookings,
  customers,
  customersBookings,
  payments,
  bookingStatus,
  equipmentItems,
  equipmentCategories,
  equipmentLogs,
  equipmentLogsItems,
  diveSitesNavigation,
  surfaceConditions,
  waterConditions,
  userTanks,
  boats,
  events,
  logs,
  generalInfo,
  templates,
  templateItems,
  roster,
  customerFeedback,
  offers,
  customerDiveLogs,
}
