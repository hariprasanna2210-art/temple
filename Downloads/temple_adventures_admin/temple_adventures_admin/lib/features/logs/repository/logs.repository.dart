import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temple_adventures_admin/database/enums/supabase_tables.enum.dart';

import '../../../main.dart';
import '../../user/bloc/user.cubit.dart';
import '../enums/action_type.enum.dart';
import '../models/log.model.dart';

/// Repository for managing application activity logs.
/// 
/// This repository handles logging of user actions and system events throughout the application.
/// Logs track who performed what action, when it was performed, and any additional context
/// information. This is useful for auditing, debugging, and tracking user activity.
/// 
/// **Key Features:**
/// - Automatic user tracking (uses current user from `UserCubit`)
/// - Flexible additional information storage (JSON format)
/// - Paginated log retrieval for efficient data loading
/// - Action type categorization for different types of operations
class LogsRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  LogsRepository();

  /// Creates and inserts a new log entry into Supabase using the current user from UserCubit.
  /// 
  /// **Flow:**
  /// 1. Validates that at least one of `name`, `referenceId`, or `additionalInformation` is provided
  /// 2. Retrieves the current `BuildContext` from the global navigator key
  /// 3. Gets the current authenticated user from `UserCubit`
  /// 4. Merges `referenceId` and `name` into `additionalInformation` if provided
  /// 5. Creates a `LogModel` with the action type, current user, and additional information
  /// 6. Transforms the model to a map, removing `id` and `created_by`, and adding `created_by_id`
  /// 7. Inserts the log entry into Supabase
  /// 8. Fetches the created log with populated `created_by` relationship
  /// 
  /// **Data Transformation:**
  /// - `created_by` (User object) is removed from the map
  /// - `created_by_id` (user ID) is added to the map for database insertion
  /// - After insertion, the `created_by` relationship is manually populated from the original user object
  /// 
  /// **Parameters:**
  /// - `actionType`: The type of action being logged (e.g., CREATE, UPDATE, DELETE)
  /// - `additionalInformation`: (Optional) Additional context data as key-value pairs
  /// - `name`: (Optional) Name or identifier related to the action
  /// - `referenceId`: (Optional) ID of a related entity (e.g., booking ID, user ID)
  /// 
  /// **Validation:**
  /// - At least one of `name`, `referenceId`, or `additionalInformation` must be provided
  /// - User must be authenticated (throws exception if not)
  /// - Context must be available and mounted (returns `null` if not)
  /// 
  /// **Returns**: The created log entry with populated `created_by` relationship, or `null` if
  /// context is unavailable or insertion fails.
  /// 
  /// **Use Case**: Logging user actions throughout the application (e.g., "User created booking #123",
  /// "User updated equipment item", "User deleted offer"). This enables audit trails and activity tracking.
  Future<LogModel?> addLog({
    required ActionType actionType,
    Map<String, dynamic>? additionalInformation,
    String? name,
    int? referenceId,
  }) async {
    assert(
      (name != null || referenceId != null || (additionalInformation != null && additionalInformation.isNotEmpty)),
      'At least one of `name`, `referenceId`, or `additionalInformation` must be provided',
    );

    // Check if context is available
    BuildContext? context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return null;

    // Get the current user from UserCubit
    final currentUser = context.read<UserCubit>().state.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    // Create the log entry
    additionalInformation ??= {};
    if (referenceId != null) additionalInformation['id'] = referenceId;
    if (name != null) additionalInformation['name'] = name;

    final LogModel log = LogModel(
      actionType: actionType,
      createdBy: currentUser,
      additionalInformation: additionalInformation,
    );
    final Map<String, dynamic> logMap = log.toMap();
    logMap.remove('id');
    logMap.remove('created_by');
    logMap['created_by_id'] = log.createdBy.id;

    // Insert the log entry into Supabase
    final response = await supabase.from(SupabaseTable.logs.toValue()).insert(logMap).select('*').maybeSingle();
    if (response == null) return null;
    response['created_by'] = log.createdBy;
    final LogModel result = LogModelMapper.fromMap(response);
    return result;
  }

  /// Fetches a paginated list of logs from Supabase ordered by creation date.
  /// 
  /// **Query Details:**
  /// - Fetches logs with pagination using `range()` for efficient data loading
  /// - Includes the `created_by` user relationship via foreign key (`created_by_id`)
  /// - Orders results by `created_at` in descending order (most recent first)
  /// - Uses `range(offset, offset + limit - 1)` for pagination
  /// 
  /// **Pagination:**
  /// - `offset`: Starting position (0-based index)
  /// - `limit`: Number of records to fetch
  /// - Example: `offset=0, limit=20` fetches the first 20 records
  /// - Example: `offset=20, limit=20` fetches records 21-40
  /// 
  /// **Parameters:**
  /// - `limit`: Maximum number of log entries to fetch
  /// - `offset`: Starting position for pagination (0-based index)
  /// 
  /// **Returns**: A list of log entries ordered by creation date (newest first), with populated
  /// `created_by` user relationships.
  /// 
  /// **Use Case**: Displaying activity logs in a paginated list view (e.g., admin dashboard,
  /// activity feed, audit log viewer). Pagination prevents loading all logs at once, improving
  /// performance for large datasets.
  Future<List<LogModel>> fetchPaginatedLogs({
    required int limit,
    required int offset,
  }) async {
    final response = await supabase
        .from(SupabaseTable.logs.toValue())
        .select('''
        *,
        created_by:created_by_id(*)
      ''')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((item) {
      return LogModelMapper.fromMap(item as Map<String, dynamic>);
    }).toList();
  }
}
