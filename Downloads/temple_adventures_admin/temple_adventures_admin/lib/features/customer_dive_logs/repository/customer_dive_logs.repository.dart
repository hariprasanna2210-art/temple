import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/models/customer_dive_log.model.dart';

import '../../../database/enums/supabase_tables.enum.dart';
import '../../../services/logging.dart';

/// Repository for managing customer dive logs.
/// 
/// This repository handles CRUD operations for customer dive logs, which track
/// individual diving experiences for customers. Each dive log is associated with
/// a customer and an instructor, and includes details like dive date, location,
/// depth, duration, and other dive-specific information.
/// 
/// **Key Relationships:**
/// - Each dive log belongs to a customer (`customer_id` foreign key)
/// - Each dive log is associated with an instructor (`instructor_id` foreign key)
/// - Dive logs can be fetched by customer ID or customer email
class CustomerDiveLogsRepository {
  CustomerDiveLogsRepository();

  final SupabaseClient supabase = Supabase.instance.client;

  /// Adds a new dive log or updates an existing one.
  /// 
  /// **Flow:**
  /// 1. Checks if `diveLog.id` is present to determine add vs. update
  /// 2. If `id` exists: Updates the existing dive log record
  /// 3. If `id` is null: Inserts a new dive log record
  /// 4. Fetches the complete record with related customer and instructor data
  /// 5. Maps the response to a `CustomerDiveLog` model
  /// 
  /// **Query Details:**
  /// - Uses foreign key relationships to fetch related `customer` and `instructor` data
  /// - `customer_dive_logs_customer_id_fkey`: Links to `customers` table
  /// - `customer_dive_logs_instructor_id_fkey`: Links to `users` table (instructors)
  /// 
  /// **Parameters:**
  /// - `diveLog`: The dive log object to add or update. If `id` is null, it's treated as a new record.
  /// 
  /// **Returns**: The saved dive log with populated customer and instructor relationships.
  /// 
  /// **Use Case**: Creating new dive log entries or updating existing ones (e.g., correcting dive details,
  /// updating dive statistics, or modifying instructor assignments).
  Future<CustomerDiveLog> addUpdateCustomerDiveLog({required CustomerDiveLog diveLog}) async {
    final Map<String, dynamic> response;

    if (diveLog.id != null) {
      // Update existing diveLog
      response =
          await supabase
              .from(SupabaseTable.customerDiveLogs.toValue())
              .update(diveLog.toRow(removeId: false))
              .eq('id', diveLog.id!)
              .select('''
            *,
            customer:customers!customer_dive_logs_customer_id_fkey (*),
            instructor:users!customer_dive_logs_instructor_id_fkey (*)
          ''')
              .single();
    } else {
      // Insert new diveLog
      response =
          await supabase.from(SupabaseTable.customerDiveLogs.toValue()).insert(diveLog.toRow()).select('''
            *,
            customer:customers!customer_dive_logs_customer_id_fkey (*),
            instructor:users!customer_dive_logs_instructor_id_fkey (*)
          ''').single();
    }

    return CustomerDiveLogMapper.fromMap(response);
  }

  /// Fetches all dive logs for a specific customer by their customer ID.
  /// 
  /// **Query Details:**
  /// - Filters dive logs by `customer_id`
  /// - Includes related `customer` and `instructor` data via foreign key relationships
  /// - Orders results by `created_at` in ascending order (oldest first)
  /// 
  /// **Parameters:**
  /// - `customerId`: The ID of the customer whose dive logs should be fetched
  /// 
  /// **Returns**: A list of dive logs for the specified customer, ordered chronologically.
  /// 
  /// **Use Case**: Displaying a customer's complete dive history, showing their progression
  /// over time, or generating dive log reports for a specific customer.
  Future<List<CustomerDiveLog>> fetchCustomerDiveLogsById(int customerId) async {
    final response = await supabase
        .from(SupabaseTable.customerDiveLogs.toValue())
        .select('''
          *,
          customer:customers!customer_dive_logs_customer_id_fkey (*),
          instructor:users!customer_dive_logs_instructor_id_fkey (*)
        ''')
        .eq('customer_id', customerId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((item) => CustomerDiveLogMapper.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a dive log from the database.
  /// 
  /// **Process:**
  /// - Performs a hard delete (permanently removes the dive log record)
  /// 
  /// **Parameters:**
  /// - `diveLogId`: The ID of the dive log to delete
  /// 
  /// **Use Case**: Removing incorrect dive log entries, cleaning up test data, or
  /// allowing customers to delete their own dive logs.
  Future<void> deleteDiveLog(int diveLogId) async {
    try {
      await supabase.from(SupabaseTable.customerDiveLogs.toValue()).delete().eq('id', diveLogId);
    } catch (e, stack) {
      Log.e('Error deleting diveLog', error: e, stackTrace: stack);
    }
  }

  /// Fetches all dive logs for a customer by their email address.
  /// 
  /// **Flow:**
  /// 1. First queries the `customers` table to find the customer by email
  /// 2. If no customer is found, throws an exception
  /// 3. Extracts the customer ID from the customer record
  /// 4. Fetches all dive logs for that customer ID
  /// 5. Includes related `customer` and `instructor` data via foreign key relationships
  /// 6. Orders results by `dive_date` in descending order (most recent first)
  /// 
  /// **Query Details:**
  /// - Uses `maybeSingle()` for customer lookup to handle cases where customer doesn't exist
  /// - Includes related `customer` and `instructor` data via foreign key relationships
  /// - Orders by `dive_date` (descending) instead of `created_at` to show most recent dives first
  /// 
  /// **Parameters:**
  /// - `email`: The email address of the customer whose dive logs should be fetched
  /// 
  /// **Returns**: A list of dive logs for the customer with the specified email,
  /// ordered by dive date (most recent first).
  /// 
  /// **Throws**: `Exception` if no customer is found with the provided email address.
  /// 
  /// **Use Case**: Looking up a customer's dive history when only their email is known

  Future<List<CustomerDiveLog>> fetchCustomerDiveLogsByEmail({required String email}) async {
    try {
      // First, find the customer by email
      final customerResponse = await supabase
          .from(SupabaseTable.customers.toValue())
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (customerResponse == null) {
        throw Exception('No customer found with email "$email"');
      }

      final customerId = customerResponse['id'] as int;

      // Then fetch their dive logs
      final response = await supabase
          .from(SupabaseTable.customerDiveLogs.toValue())
          .select('''
            *,
            customer:customers!customer_dive_logs_customer_id_fkey (*),
            instructor:users!customer_dive_logs_instructor_id_fkey (*)
          ''')
          .eq('customer_id', customerId)
          .order('dive_date', ascending: false);

      return (response as List<dynamic>)
          .map((item) => CustomerDiveLogMapper.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      Log.e('Error fetching dive logs by email', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
