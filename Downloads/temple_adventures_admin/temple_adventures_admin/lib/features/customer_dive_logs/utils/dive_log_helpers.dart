import '../../bookings/models/customer.model.dart';
import '../models/customer_dive_log.model.dart';

class DiveLogHelpers {
  /// Filters dive logs by date range and optionally by customer ID
  /// 
  /// If [customerId] is provided, filters by both customer and date range.
  /// If [customerId] is null, filters by date range only.
  static List<CustomerDiveLog> filterLogsByDateRange({
    required List<CustomerDiveLog> logs,
    int? customerId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return logs.where((log) {
      // Filter by customer if customerId is provided
      if (customerId != null && log.customer.id != customerId) {
        return false;
      }

      // Compare dates only (ignore time)
      final logDate = DateTime(log.diveDate.year, log.diveDate.month, log.diveDate.day);
      final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

      final isInDateRange =
          (logDate.isAtSameMomentAs(startDateOnly) || logDate.isAfter(startDateOnly)) &&
          (logDate.isAtSameMomentAs(endDateOnly) || logDate.isBefore(endDateOnly));

      return isInDateRange;
    }).toList();
  }

  /// Sorts dive logs by date (newest first or oldest first)
  static void sortByDate(List<CustomerDiveLog> logs, {bool newestFirst = true}) {
    if (newestFirst) {
      logs.sort((a, b) => b.diveDate.compareTo(a.diveDate));
    } else {
      logs.sort((a, b) => a.diveDate.compareTo(b.diveDate));
    }
  }

  /// Creates a copy of a log with a different customer
  static CustomerDiveLog createCopiedLog(CustomerDiveLog originalLog, Customer newCustomer) {
    return CustomerDiveLog(
      id: null, // New log, no ID
      customer: newCustomer,
      diveDate: originalLog.diveDate,
      instructor: originalLog.instructor,
      diveSite: originalLog.diveSite,
      tankType: originalLog.tankType,
      tankNo: originalLog.tankNo,
      bottomTime: originalLog.bottomTime,
      pressure: originalLog.pressure,
      maxDepth: originalLog.maxDepth,
      rentalEquipment: originalLog.rentalEquipment,
    );
  }
}

