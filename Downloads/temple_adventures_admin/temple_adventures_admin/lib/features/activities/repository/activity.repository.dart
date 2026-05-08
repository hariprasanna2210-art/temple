import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../database/enums/supabase_tables.enum.dart';
import '../models/activity.model.dart';
import '../models/activity_color.model.dart';

/// Repository for activity and activity color related database operations.
/// 
/// Handles CRUD operations for activities and their associated colors.
/// Activities represent different types of diving/water activities (e.g., Fun Dive, DSD, etc.)
/// and are linked to activity colors for UI display purposes.
class ActivityRepository {
  ActivityRepository();

  final SupabaseClient supabase = Supabase.instance.client;

  /// Creates a new activity color in the database.
  /// 
  /// **Data Transformation:**
  /// - Removes `id` field (database will auto-generate)
  /// 
  /// **Returns**: The created activity color with database-generated ID, or null if creation failed.
  /// 
  /// **Use Case**: Activity colors are used to visually distinguish different activity types
  /// in the UI.
  Future<ActivityColor?> addActivityColor(ActivityColor activityColor) async {
    Map<String, dynamic> activityColorJson = activityColor.toMap();
    // Remove ID to prevent sending `id: null` - database will auto-generate
    activityColorJson.remove('id');
    final response =
        await supabase.from(SupabaseTable.activityColors.toValue()).insert(activityColorJson).select('*').maybeSingle();

    if (response != null) {
      return ActivityColorMapper.fromMap(response);
    } else {
      return null;
    }
  }

  /// Updates an existing activity color in the database.
  /// 
  /// **Throws**: Exception if activity color ID is null (color must exist to be updated).
  /// 
  /// **Note**: This updates all fields of the activity color. Ensure the model contains
  /// all required fields, not just the ones being changed.
  Future<void> editActivityColor(ActivityColor activityColorModel) async {
    if (activityColorModel.id == null) {
      throw Exception('Activity color ID is required to edit activity');
    }

    await supabase
        .from(SupabaseTable.activityColors.toValue())
        .update(activityColorModel.toMap())
        .eq('id', activityColorModel.id!);
  }

  /// Fetches all activity colors from the database.
  /// 
  /// **Returns**: List of all activity colors, ordered by their natural order in the database.
  /// 
  /// **Use Case**: Used to populate color pickers or dropdowns when creating/editing activities.
  Future<List<ActivityColor>> fetchAllActivityColors() async {
    final List<dynamic> response = await supabase.from(SupabaseTable.activityColors.toValue()).select();

    return response.map((item) => ActivityColorMapper.fromMap(item as Map<String, dynamic>)).toList();
  }

  /// Creates a new activity in the database.
  /// 
  /// **Data Transformation:**
  /// - Removes `id` field (database will auto-generate)
  /// - Removes `color` object (replaced with `color_id` foreign key)
  /// - Adds `color_id` to link activity to its color
  /// 
  /// **Returns**: The created activity with database-generated ID and color object populated,
  /// or null if creation failed.
  /// 
  /// **Note**: The color object is manually added back to the response because the database
  /// returns only the foreign key. We use the original activity's color object for mapping.
  /// 
  /// **Use Case**: Activities represent different types of diving/water activities that can
  /// be booked (e.g., Fun Dive, DSD, Snorkeling, etc.). Each activity has a name, short name,
  /// price, priority, and associated color for UI display.
  Future<Activity?> addActivity(Activity activity) async {
    Map<String, dynamic> activityMap = activity.toMap();
    // Remove ID to prevent sending `id: null` - database will auto-generate
    activityMap.remove('id');
    // Remove color object, we'll use foreign key instead
    activityMap.remove('color');
    // Add foreign key relationship to activity_colors table
    activityMap['color_id'] = activity.color.id;
    
    final response =
        await supabase.from(SupabaseTable.activities.toValue()).insert(activityMap).select('*').maybeSingle();

    if (response != null) {
      // Manually populate color object in response
      // The database returns only the foreign key, but ActivityMapper expects the full color object
      // We use the original activity's color object since no changes occurred during insertion
      response['color'] = activity.color;
      return ActivityMapper.fromMap(response);
    } else {
      return null;
    }
  }

  /// Updates an existing activity in the database.
  /// 
  /// **Data Transformation:**
  /// - Removes `color` object (replaced with `color_id` foreign key)
  /// - Adds `color_id` to maintain relationship to activity color
  /// 
  /// **Throws**: Exception if activity ID is null (activity must exist to be updated).
  /// 
  /// **Note**: This updates all fields of the activity. Ensure the model contains
  /// all required fields, not just the ones being changed.
  /// 
  /// **Note**: The `is_deleted` flag can be set to true to soft-delete an activity
  /// (it will still exist in the database but won't appear in fetchAllActivities).
  Future<void> editActivity(Activity activity) async {
    if (activity.id == null) {
      throw Exception('Activity ID is required to edit activity');
    }

    final activityMap = activity.toMap();
    // Remove color object, use foreign key instead
    activityMap.remove('color');
    // Add foreign key relationship
    activityMap['color_id'] = activity.color.id;

    await supabase
        .from(SupabaseTable.activities.toValue())
        .update(activityMap)
        .eq('id', activity.id!);
  }

  /// Fetches all active (non-deleted) activities from the database.
  /// 
  /// **Query Details:**
  /// - Uses Supabase's join syntax to fetch related color data
  /// - Filters out soft-deleted activities (`is_deleted = false`)
  /// - Orders results by activity name (ascending, A-Z)
  /// 
  /// **Returns**: List of all active activities with their associated colors,
  /// ordered alphabetically by name.
  /// 
  /// **Note**: Soft-deleted activities (where `is_deleted = true`) are excluded from results.
  /// This allows activities to be "deleted" without losing historical booking data.
  /// 
  /// **Use Case**: Used to populate activity dropdowns, lists, and filters throughout the app.
  Future<List<Activity>> fetchAllActivities() async {
    final response = await supabase
        .from(SupabaseTable.activities.toValue())
        .select('''
          *,
          color:activity_colors (*)
        ''')
        .eq('is_deleted', false)
        .order('name', ascending: true);

    return (response as List<dynamic>).map((item) => ActivityMapper.fromMap(item as Map<String, dynamic>)).toList();
  }
}
