import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temple_adventures_admin/database/enums/supabase_tables.enum.dart';
import 'package:temple_adventures_admin/features/conditions/model/surface_conditions.model.dart';
import 'package:temple_adventures_admin/features/conditions/model/water_conditions.model.dart';

import '../../../services/logging.dart';

/// Repository for managing surface and water conditions.
/// 
/// This repository handles CRUD operations for surface and water conditions, which track
/// environmental conditions for specific dates. Surface conditions typically include weather,
/// visibility, and other above-water factors, while water conditions track underwater
/// factors like temperature, visibility, currents, and other dive-related metrics.
/// 
/// **Key Features:**
/// - Date-based condition tracking (conditions are associated with specific dates)
/// - User tracking (records who updated each condition via `updated_by` foreign key)
/// - Separate management for surface and water conditions
/// - Date formatting to ensure consistent date storage (yyyy-MM-dd format)
class ConditionsRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  ConditionsRepository();

  /// Fetches surface conditions for a specific date.
  /// 
  /// **Query Details:**
  /// - Formats the date to 'yyyy-MM-dd' format for consistent database queries
  /// - Filters surface conditions by the specified date
  /// - Includes the `updated_by` user relationship via foreign key
  /// 
  /// **Parameters:**
  /// - `date`: The date for which to fetch surface conditions
  /// 
  /// **Returns**: A list of surface conditions for the specified date, with populated
  /// `updated_by` user relationships. Returns an empty list if no conditions exist for that date.
  /// 
  /// **Use Case**: Displaying surface conditions for a specific date (e.g., weather conditions,
  /// visibility, wind speed) in the conditions screen or dashboard.
  Future<List<SurfaceConditions>> fetchSurfaceCondition(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final List<dynamic> response = await supabase
        .from(SupabaseTable.surfaceConditions.toValue())
        .select('''
          *,
          updated_by (*)
        ''')
        .eq('date', formattedDate);

    return response.map((item) {
      return SurfaceConditionsMapper.fromMap(item as Map<String, dynamic>);
    })        .toList();
  }

  /// Fetches water conditions for a specific date.
  /// 
  /// **Query Details:**
  /// - Formats the date to 'yyyy-MM-dd' format for consistent database queries
  /// - Filters water conditions by the specified date
  /// - Includes the `updated_by` user relationship via foreign key
  /// 
  /// **Parameters:**
  /// - `date`: The date for which to fetch water conditions
  /// 
  /// **Returns**: A list of water conditions for the specified date, with populated
  /// `updated_by` user relationships. Returns an empty list if no conditions exist for that date.
  /// 
  /// **Use Case**: Displaying water conditions for a specific date (e.g., water temperature,
  /// visibility, currents, dive conditions) in the conditions screen or dashboard.
  Future<List<WaterConditions>> fetchWaterCondition(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final List<dynamic> response = await supabase
        .from(SupabaseTable.waterConditions.toValue())
        .select('''
          *,
          updated_by (*)
        ''')
        .eq('date', formattedDate);

    return response.map((item) {
      return WaterConditionsMapper.fromMap(item as Map<String, dynamic>);
    })        .toList();
  }

  /// Adds a new surface condition entry to the database.
  /// 
  /// **Flow:**
  /// 1. Converts the condition model to a map
  /// 2. Formats the date to 'yyyy-MM-dd' format
  /// 3. Removes `id` and `updated_by` from the map (not needed for insertion)
  /// 4. Adds `updated_by` as the user ID (`updated_by_id`) for database insertion
  /// 5. Inserts the condition into Supabase
  /// 6. Manually populates the `updated_by` relationship from the original user object
  /// 
  /// **Data Transformation:**
  /// - `updated_by` (User object) is removed from the map
  /// - `updated_by` is set to the user ID for database insertion
  /// - After insertion, the `updated_by` relationship is manually populated from the original user object
  /// - Date is formatted to 'yyyy-MM-dd' to ensure consistent storage format
  /// 
  /// **Parameters:**
  /// - `condition`: The surface condition object to add. The `id` should be `null` for new entries.
  /// 
  /// **Returns**: The created surface condition with populated `updated_by` relationship,
  /// or `null` if insertion fails.
  /// 
  /// **Use Case**: Recording surface conditions for a specific date (e.g., weather observations,
  /// visibility reports, wind conditions). This helps track environmental factors that may
  /// affect diving operations.
  Future<SurfaceConditions?> addSurfaceCondition(SurfaceConditions condition) async {
    final Map<String, dynamic> surfaceConditionMap = condition.toMap();
    final formattedDate = DateFormat('yyyy-MM-dd').format(condition.date);
    surfaceConditionMap.remove('id');
    surfaceConditionMap.remove('updated_by');
    surfaceConditionMap['updated_by'] = condition.updatedBy.id;
    surfaceConditionMap['date'] = formattedDate;

    final response =
        await supabase
            .from(SupabaseTable.surfaceConditions.toValue())
            .insert(surfaceConditionMap)
            .select('*')
            .maybeSingle();
    if (response != null) {
      response['updated_by'] = condition.updatedBy;
      final SurfaceConditions result = SurfaceConditionsMapper.fromMap(response);
      return result;
    }
    return null;
  }

  /// Adds a new water condition entry to the database.
  /// 
  /// **Flow:**
  /// 1. Converts the condition model to a map
  /// 2. Formats the date to 'yyyy-MM-dd' format
  /// 3. Removes `id` and `updated_by` from the map (not needed for insertion)
  /// 4. Adds `updated_by` as the user ID (`updated_by_id`) for database insertion
  /// 5. Inserts the condition into Supabase
  /// 6. Manually populates the `updated_by` relationship from the original user object
  /// 
  /// **Data Transformation:**
  /// - `updated_by` (User object) is removed from the map
  /// - `updated_by` is set to the user ID for database insertion
  /// - After insertion, the `updated_by` relationship is manually populated from the original user object
  /// - Date is formatted to 'yyyy-MM-dd' to ensure consistent storage format
  /// 
  /// **Parameters:**
  /// - `condition`: The water condition object to add. The `id` should be `null` for new entries.
  /// 
  /// **Returns**: The created water condition with populated `updated_by` relationship,
  /// or `null` if insertion fails.
  /// 
  /// **Use Case**: Recording water conditions for a specific date (e.g., water temperature,
  /// visibility, currents, dive conditions). This helps track underwater environmental
  /// factors that affect diving safety and experience.
  Future<WaterConditions?> addWaterCondition(WaterConditions condition) async {
    final Map<String, dynamic> waterConditionMap = condition.toMap();
    final formattedDate = DateFormat('yyyy-MM-dd').format(condition.date);
    waterConditionMap.remove('id');
    waterConditionMap.remove('updated_by');
    waterConditionMap['updated_by'] = condition.updatedBy.id;
    waterConditionMap['date'] = formattedDate;
    final response =
        await supabase
            .from(SupabaseTable.waterConditions.toValue())
            .insert(waterConditionMap)
            .select('*')
            .maybeSingle();
    if (response != null) {
      response['updated_by'] = condition.updatedBy;
      final WaterConditions result = WaterConditionsMapper.fromMap(response);
      return result;
    }
    return null;
  }

  /// Updates an existing surface condition in the database.
  /// 
  /// **Flow:**
  /// 1. Validates that the condition has an `id` (required for updates)
  /// 2. Converts the condition model to a map
  /// 3. Formats the date to 'yyyy-MM-dd' format
  /// 4. Removes `updated_by` from the map and sets it to the user ID for database update
  /// 5. Updates the condition in Supabase using the condition ID
  /// 6. Fetches the updated condition with populated `updated_by` relationship
  /// 
  /// **Data Transformation:**
  /// - `updated_by` (User object) is removed from the map
  /// - `updated_by` is set to the user ID for database update
  /// - Date is formatted to 'yyyy-MM-dd' to ensure consistent storage format
  /// - The `updated_by` relationship is fetched via foreign key in the select query
  /// 
  /// **Parameters:**
  /// - `condition`: The surface condition object to update. Must have a non-null `id`.
  /// 
  /// **Returns**: The updated surface condition with populated `updated_by` relationship.
  /// 
  /// **Throws**: `Exception` if the condition `id` is `null`.
  /// 
  /// **Use Case**: Updating existing surface condition records (e.g., correcting weather data,
  /// updating visibility reports, modifying wind conditions). This allows staff to maintain
  /// accurate condition records.
  Future<SurfaceConditions> editSurfaceCondition(SurfaceConditions condition) async {
    if (condition.id == null) {
      throw Exception('Surface condition ID is required to edit condition');
    }

    final Map<String, dynamic> surfaceConditionMap = condition.toMap();
    final formattedDate = DateFormat('yyyy-MM-dd').format(condition.date);
    surfaceConditionMap.remove('updated_by');
    surfaceConditionMap['updated_by'] = condition.updatedBy.id;
    surfaceConditionMap['date'] = formattedDate;

    final response =
        await supabase
            .from(SupabaseTable.surfaceConditions.toValue())
            .update(surfaceConditionMap)
            .eq('id', condition.id!)
            .select('''
        *,
        updated_by (*)
      ''')
            .single();

    final SurfaceConditions updatedCondition = SurfaceConditionsMapper.fromMap(response);
    return updatedCondition;
  }

  /// Updates an existing water condition in the database.
  /// 
  /// **Flow:**
  /// 1. Validates that the condition has an `id` (required for updates)
  /// 2. Converts the condition model to a map
  /// 3. Formats the date to 'yyyy-MM-dd' format
  /// 4. Removes `updated_by` from the map and sets it to the user ID for database update
  /// 5. Updates the condition in Supabase using the condition ID
  /// 6. Fetches the updated condition with populated `updated_by` relationship
  /// 
  /// **Data Transformation:**
  /// - `updated_by` (User object) is removed from the map
  /// - `updated_by` is set to the user ID for database update
  /// - Date is formatted to 'yyyy-MM-dd' to ensure consistent storage format
  /// - The `updated_by` relationship is fetched via foreign key in the select query
  /// 
  /// **Parameters:**
  /// - `condition`: The water condition object to update. Must have a non-null `id`.
  /// 
  /// **Returns**: The updated water condition with populated `updated_by` relationship.
  /// 
  /// **Throws**: `Exception` if the condition `id` is `null`.
  /// 
  /// **Use Case**: Updating existing water condition records (e.g., correcting water temperature,
  /// updating visibility measurements, modifying current information). This allows staff to maintain
  /// accurate underwater condition records.
  Future<WaterConditions> editWaterCondition(WaterConditions condition) async {
    if (condition.id == null) {
      throw Exception('Water condition ID is required to edit condition');
    }

    final Map<String, dynamic> waterConditionMap = condition.toMap();

    final formattedDate = DateFormat('yyyy-MM-dd').format(condition.date);

    waterConditionMap['date'] = formattedDate;
    waterConditionMap.remove('updated_by');
    waterConditionMap['updated_by'] = condition.updatedBy.id;

    final response =
        await supabase
            .from(SupabaseTable.waterConditions.toValue())
            .update(waterConditionMap)
            .eq('id', condition.id!)
            .select('''
        *,
        updated_by (*)
      ''')
            .single();

    final WaterConditions updatedCondition = WaterConditionsMapper.fromMap(response);
    return updatedCondition;
  }

  /// Deletes a water condition from the database.
  /// 
  /// **Process:**
  /// - Performs a hard delete (permanently removes the water condition record)
  /// 
  /// **Parameters:**
  /// - `id`: The ID of the water condition to delete
  /// 
  /// **Returns**: `true` if deletion succeeded, `false` if an error occurred.
  /// 
  /// **Note**: This is a hard delete - the water condition record will be permanently removed
  /// from the database.
  /// 
  /// **Use Case**: Removing incorrect water condition entries, cleaning up test data, or
  /// allowing staff to delete outdated condition records.
  
  Future<bool> deleteWaterCondition(int id) async {
    try {
      await supabase.from(SupabaseTable.waterConditions.toValue()).delete().eq('id', id);
      return true;
    } catch (e, stack) {
      Log.e('Error deleting water condition', error: e, stackTrace: stack);
      return false;
    }
  }
}
