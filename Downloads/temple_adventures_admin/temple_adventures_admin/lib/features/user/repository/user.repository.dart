import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../database/enums/supabase_tables.enum.dart';
import '../../../services/logging.dart';
import '../models/user.model.dart';

/// Repository for user-related database operations.
/// Handles CRUD operations for users and implements soft-delete restoration logic.
class UserRepository {
  UserRepository();

  final SupabaseClient supabase = Supabase.instance.client;

  /// Finds a deleted user with the same phone number and country code.
  /// 
  /// This is used to restore deleted users instead of creating duplicates.
  /// When a user is "deleted", we set `is_deleted = true` (soft delete).
  /// If someone tries to add a user with the same phone number, we restore
  /// the existing user instead of creating a duplicate.
  /// 
  /// Returns the deleted user if found, null otherwise.
  Future<User?> findDeletedUser({required String countryCode, required String phoneNumber}) async {
    final response = await supabase
        .from(SupabaseTable.users.toValue())
        .select()
        .eq('phone_number', phoneNumber)
        .eq('country_code', countryCode)
        .eq('is_deleted', true)
        .maybeSingle();

    if (response == null) return null;
    return UserMapper.fromMap(response);
  }

  /// Adds a new user to the database.
  /// 
  /// **Important Business Logic**: If a deleted user exists with the same phone number,
  /// this method will restore that user instead of creating a duplicate.
  /// 
  /// **Why restore instead of create?**
  /// - Prevents duplicate users in the system
  /// - Preserves historical data (bookings, logs, etc.) linked to the user ID
  /// - Maintains data integrity and referential relationships
  /// 
  /// **Flow:**
  /// 1. Check if a deleted user exists with the same phone number
  /// 2. If found: Update the deleted user with new data and set `is_deleted = false`
  /// 3. If not found: Insert as a new user
  /// 
  /// Returns the created or restored user, or null if the operation fails.
  Future<User?> addUser(User user) async {
    // Step 1: Check if a deleted user exists with the same phone number
    final deletedUser = await findDeletedUser(
      countryCode: user.countryCode,
      phoneNumber: user.phoneNumber,
    );

    if (deletedUser != null && deletedUser.id != null) {
      // Step 2: Restore the deleted user by updating it with new data and setting is_deleted = false
      Log.i(
        'Found deleted user with same phone number (ID: ${deletedUser.id}). Restoring user instead of creating new.',
      );

      // Create updated user with all new data but keep the existing ID and set isDeleted = false
      final userMap = user.toMap();
      userMap['id'] = deletedUser.id; // Preserve the original user ID
      userMap['is_deleted'] = false; // Restore the user

      await supabase.from(SupabaseTable.users.toValue()).update(userMap).eq('id', deletedUser.id!);

      // Fetch the updated user to return complete data (including any database defaults/triggers)
      final updatedResponse = await supabase
          .from(SupabaseTable.users.toValue())
          .select()
          .eq('id', deletedUser.id!)
          .maybeSingle();

      if (updatedResponse != null) {
        Log.i('Successfully restored user with ID: ${deletedUser.id}');
        return UserMapper.fromMap(updatedResponse);
      }
      Log.w('Failed to fetch restored user after update');
      return null;
    }

    // Step 3: No deleted user found, insert as new user
    Log.i('No deleted user found. Creating new user with phone: ${user.countryCode}${user.phoneNumber}');
    Map<String, dynamic> userJson = user.toMap();
    userJson.remove('id'); // Remove ID for new insert (database will auto-generate)
    final response = await supabase.from(SupabaseTable.users.toValue()).insert(userJson);

    if (response != null) {
      return UserMapper.fromMap(response);
    } else {
      return null;
    }
  }

  /// Updates an existing user in the database.
  /// 
  /// **Note**: User ID is required. This method will throw an exception if ID is null.
  /// 
  /// Throws [Exception] if user ID is null.
  Future<void> editUser(User user) async {
    final userId = user.id;

    if (userId == null) {
      throw Exception('User ID is required to edit user');
    }

    await supabase
        .from(SupabaseTable.users.toValue())
        .update(user.toMap())
        .eq('id', userId);
  }

  /// Checks if a non-deleted user exists with the given phone number and country code.
  /// 
  /// **Use Case**: Used during authentication to verify if a user is authorized to use the app.
  /// Only checks for active users (is_deleted = false).
  /// 
  /// Returns the user ID if found, null otherwise.
  Future<int?> isUserExists({required String countryCode, required String phoneNumber}) async {
    final response = await supabase
        .from(SupabaseTable.users.toValue())
        .select('id')
        .eq('phone_number', phoneNumber)
        .eq('country_code', countryCode)
        .eq('is_deleted', false)
        .maybeSingle();

    return response?['id'];
  }

  /// Fetches the current logged-in user by ID.
  /// 
  /// Only returns active users (is_deleted = false).
  /// Returns null if user not found or is deleted.
  Future<User?> fetchCurrentUser({required int userId}) async {
    final response = await supabase
        .from(SupabaseTable.users.toValue())
        .select()
        .eq('id', userId)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;

    return UserMapper.fromMap(response);
  }

  /// Fetches all active users from the database.
  /// 
  /// **Note**: Only returns users where `is_deleted = false`.
  /// Results are ordered by first name in ascending order.
  /// 
  /// Returns an empty list if no users found.
  Future<List<User>> fetchAllUsers() async {
    var query = supabase
        .from(SupabaseTable.users.toValue())
        .select()
        .eq('is_deleted', false)
        .order('first_name', ascending: true);

    final List<dynamic> response = await query;

    return response.map((item) => UserMapper.fromMap(item as Map<String, dynamic>)).toList();
  }
}
