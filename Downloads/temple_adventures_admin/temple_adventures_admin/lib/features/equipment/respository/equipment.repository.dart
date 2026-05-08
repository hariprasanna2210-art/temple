import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:temple_adventures_admin/database/enums/supabase_tables.enum.dart';
import 'package:temple_adventures_admin/features/equipment/model/enriched_equipment_logs.model.dart';
import 'package:temple_adventures_admin/features/equipment/model/equipment_category.model.dart';
import 'package:temple_adventures_admin/features/user/models/user.model.dart';

import '../../../services/logging.dart';
import '../model/equipment_item.model.dart';
import '../model/equipment_log.model.dart';

/// Repository for equipment-related database operations.
/// 
/// Handles CRUD operations for equipment items, equipment categories, equipment logs,
/// and equipment image uploads. Manages equipment rental tracking and availability.
class EquipmentRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  EquipmentRepository();

  /// Creates a new equipment item in the database.
  /// 
  /// **Data Transformation:**
  /// - The response from database doesn't include related objects (category, current_rented_person)
  /// - These are manually added back from the original equipment item for proper mapping
  /// 
  /// **Returns**: The created equipment item with database-generated ID, or null if creation failed.
  /// 
  /// **Use Case**: Adding new equipment items to the inventory (e.g., wetsuits, fins, masks, etc.).
  Future<EquipmentItem?> addNewEquipment(EquipmentItem equipmentItem) async {
    final response =
        await supabase
            .from(SupabaseTable.equipmentItems.toValue())
            .insert(equipmentItem.toRow())
            .select('*')
            .maybeSingle();

    if (response != null) {
      // Manually populate related objects that aren't returned by the database
      // The database returns only foreign keys, but EquipmentItemMapper expects full objects
      response['category'] = equipmentItem.category;
      response['current_rented_person'] = equipmentItem.currentRentedPerson;
      final EquipmentItem result = EquipmentItemMapper.fromMap(response);
      return result;
    }
    return null;
  }

  /// Updates an existing equipment item in the database.
  /// 
  /// **Query Details:**
  /// - Uses Supabase's join syntax to fetch related category data
  /// - Updates all fields of the equipment item
  /// 
  /// **Throws**: Exception if equipment ID is null (equipment must exist to be updated).
  /// 
  /// **Returns**: The updated equipment item with related category data.
  /// 
  /// **Note**: This updates all fields of the equipment item. Ensure the model contains
  /// all required fields, not just the ones being changed.
  Future<EquipmentItem> editEquipment(EquipmentItem equipmentItem) async {
    if (equipmentItem.id == null) {
      throw Exception('Equipment ID is required to edit the equipment item');
    }
    final response =
        await supabase
            .from(SupabaseTable.equipmentItems.toValue())
            .update(equipmentItem.toRow(removeId: false))
            .eq('id', equipmentItem.id!)
            .select('*, category:category_id(*)')
            .single();
    final EquipmentItem updatedEquipmentItem = EquipmentItemMapper.fromMap(response);
    return updatedEquipmentItem;
  }

  /// Fetches all active (non-deleted) equipment items from the database.
  /// 
  /// **Query Details:**
  /// - Uses Supabase's join syntax to fetch related data:
  ///   - `category`: Equipment category information
  ///   - `current_rented_person`: User who currently has the equipment rented
  /// - Filters out soft-deleted equipment (`is_deleted = false`)
  /// 
  /// **Returns**: List of all active equipment items with their categories and rental status.
  /// 
  /// **Note**: Soft-deleted equipment (where `is_deleted = true`) are excluded from results.
  /// This allows equipment to be "deleted" without losing historical rental data.
  /// 
  /// **Use Case**: Used to populate equipment lists, inventory views, and rental management screens.
  Future<List<EquipmentItem>> fetchEquipmentItems() async {
    final List<dynamic> response = await supabase
        .from(SupabaseTable.equipmentItems.toValue())
        .select('''
        *, 
        category:category_id(*),
        current_rented_person:current_rented_person_id(*)
      ''')
        .eq('is_deleted', false);

    return response.map((item) {
      return EquipmentItemMapper.fromMap(item as Map<String, dynamic>);
    }).toList();
  }

  /// Soft-deletes an equipment item from the database.
  /// 
  /// **Process:**
  /// - Sets `is_deleted = true` on the equipment item (soft delete)
  /// 
  /// **Parameters:**
  /// - `id`: Equipment item ID to delete
  /// 
  /// **Returns**: `true` if deletion succeeded, `false` if an error occurred.
  /// 
  /// **Note**: This is a soft delete - the equipment record remains in the database
  /// but is marked as deleted. This preserves historical rental data.
  /// 
  Future<bool> deleteEquipment(int id) async {
    try {
      // Soft delete: mark as deleted instead of removing from database
      await supabase.from(SupabaseTable.equipmentItems.toValue()).update({'is_deleted': true}).eq('id', id);
      return true;
    } catch (e, stack) {
      Log.e('Error deleting equipment', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Updates equipment item rental status for multiple items.
  /// 
  /// **Use Cases:**
  /// - When equipment is rented: Set `renter` to the user renting the equipment
  /// - When equipment is returned: Set `renter` to `null` (marks equipment as available)
  /// 
  /// **Data Transformation:**
  /// - Removes `category` object (replaced with `category_id` foreign key)
  /// - Removes `current_rented_person` object (replaced with `current_rented_person_id` foreign key)
  /// 
  /// **Parameters:**
  /// - `equipmentItems`: List of equipment items to update
  /// - `renter`: (Optional) User who is renting the equipment. Set to `null` to mark as available.
  /// - `lastRented`: (Optional) Last rented date. Currently not used but reserved for future use.
  /// 
  /// **Throws**: Exception if any equipment item ID is null.
  /// 
  /// **Note**: This method updates multiple equipment items in a loop. Each item is updated
  /// individually to maintain data consistency.
  /// 
  /// **Note**: When `renter` is `null`, the equipment is marked as available (not rented).
  Future<void> updateEquipmentItemAvailability(
    List<EquipmentItem> equipmentItems,
    User? renter,
    DateTime? lastRented,
  ) async {
    if (equipmentItems.isEmpty) {
      return;
    }

    // Update each equipment item's rental status
    for (var item in equipmentItems) {
      if (item.id == null) {
        throw Exception('Equipment ID is required to update equipment item');
      }

      // Create updated equipment item with new renter
      final updated = item.copyWith(
        currentRentedPerson: renter,
      );

      final equipmentItemMap = updated.toMap();

      // Remove objects, use foreign keys instead
      equipmentItemMap.remove('category');
      equipmentItemMap['category_id'] = updated.category.id;

      equipmentItemMap.remove('current_rented_person');
      equipmentItemMap['current_rented_person_id'] = updated.currentRentedPerson?.id;

      await supabase.from(SupabaseTable.equipmentItems.toValue()).update(equipmentItemMap).eq('id', item.id!);
    }
  }

  /// Creates a new equipment category in the database.
  /// 
  /// **Returns**: The created equipment category with database-generated ID, or null if creation failed.
  /// 
  /// **Use Case**: Equipment categories group similar equipment items together
  /// (e.g., "Wetsuits", "Fins", "Masks", "BCD", etc.).
  Future<EquipmentCategory?> addCategory(EquipmentCategory equipmentCategory) async {
    final response =
        await supabase
            .from(SupabaseTable.equipmentCategories.toValue())
            .insert(equipmentCategory.toRow())
            .select('*')
            .maybeSingle();
    if (response != null) {
      final EquipmentCategory result = EquipmentCategoryMapper.fromMap(response);
      return result;
    }
    return null;
  }

  /// Updates an existing equipment category in the database.
  /// 
  /// **Throws**: Exception if category ID is null (category must exist to be updated).
  /// 
  /// **Returns**: The updated equipment category.
  /// 
  /// **Note**: This updates all fields of the category. Ensure the model contains
  /// all required fields, not just the ones being changed.
  Future<EquipmentCategory> editCategory(EquipmentCategory equipmentCategory) async {
    if (equipmentCategory.id == null) {
      throw Exception('Equipment category ID is required to edit category');
    }
    final response =
        await supabase
            .from(SupabaseTable.equipmentCategories.toValue())
            .update(equipmentCategory.toRow(removeId: false))
            .eq('id', equipmentCategory.id!)
            .select('*')
            .single();
    final EquipmentCategory updatedEquipmentCategory = EquipmentCategoryMapper.fromMap(response);
    return updatedEquipmentCategory;
  }

  /// Fetches all active (non-deleted) equipment categories from the database.
  /// 
  /// **Query Details:**
  /// - Filters out soft-deleted categories (`is_deleted = false`)
  /// 
  /// **Returns**: List of all active equipment categories.
  /// 
  /// **Note**: Soft-deleted categories (where `is_deleted = true`) are excluded from results.
  /// 
  /// **Use Case**: Used to populate category dropdowns when creating/editing equipment items.
  Future<List<EquipmentCategory>> fetchEquipmentCategories() async {
    final List<dynamic> response = await supabase
        .from(SupabaseTable.equipmentCategories.toValue())
        .select('*')
        .eq('is_deleted', false);

    return response.map((item) {
      return EquipmentCategoryMapper.fromMap(item as Map<String, dynamic>);
    }).toList();
  }

  /// Soft-deletes an equipment category from the database.
  /// 
  /// **Process:**
  /// - Sets `is_deleted = true` on the category (soft delete)
  /// 
  /// **Returns**: `true` if deletion succeeded, `false` if an error occurred.
  /// 
  /// **Note**: This is a soft delete - the category record remains in the database
  /// but is marked as deleted. This preserves relationships with existing equipment items.
  /// 
  /// **Warning**: Ensure no active equipment items are using this category before deleting,
  /// or handle the relationship appropriately in the UI.
  Future<bool> deleteCategory(int id) async {
    try {
      // Soft delete: mark as deleted instead of removing from database
      await supabase.from(SupabaseTable.equipmentCategories.toValue()).update({'is_deleted': true}).eq('id', id);
      return true;
    } catch (e, stack) {
      Log.e('Error deleting category', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Creates a new equipment rental log in the database.
  /// 
  /// **Multi-Step Process:**
  /// 1. Insert equipment log record with renter, approver, and collector information
  /// 2. Link equipment items to the log via the `equipment_logs_items` join table
  /// 3. Manually attach equipment items to response for proper mapping
  /// 
  /// **Query Details:**
  /// - Uses Supabase's join syntax to fetch related user data:
  ///   - `renter_id`: Person who is renting the equipment
  ///   - `approver_id`: Person who approved the rental
  ///   - `collector_id`: Person who collected/returned the equipment (may be null initially)
  /// 
  /// **Returns**: The created equipment log with all related data, or null if creation failed.
  /// 
  /// **Throws**: Exception if log creation fails or no ID is returned.
  /// 
  /// **Note**: Equipment items are linked to the log via a many-to-many relationship
  /// in the `equipment_logs_items` join table, allowing one log to track multiple items.
  /// 
  /// **Use Case**: Records equipment rental transactions, tracking who rented what,
  /// when it was approved, and when it was returned.
  Future<EquipmentLog?> addEquipmentLog(EquipmentLog equipmentLog) async {
    try {
      // Step 1: Insert equipment log and fetch related user data
      final response =
          await supabase.from(SupabaseTable.equipmentLogs.toValue()).insert(equipmentLog.toRow()).select('''
          *,
          renter_id:renter_person_id(*),
          approver_id:approver_person_id(*),
          collector_id:collector_person_id(*)
        ''').maybeSingle();

      if (response == null) {
        throw Exception('Failed to create log');
      }

      final equipmentLogId = response['id'];
      if (equipmentLogId == null) {
        throw Exception('Failed to create log - no ID returned');
      }

      // Step 2: Link equipment items to this log via join table
      for (final item in equipmentLog.equipmentItem) {
        await supabase.from('equipment_logs_items').insert({
          'equipment_log_id': equipmentLogId,
          'equipment_item_id': item.id,
        });
      }
      
      // Step 3: Manually attach equipment items to response for mapping
      // The database doesn't return equipment items in the join, so we add them from the original log
      final transformedResponse = Map<String, dynamic>.from(response);
      transformedResponse['equipment_item'] = equipmentLog.equipmentItem.map((item) => item.toMap()).toList();
      final EquipmentLog result = EquipmentLogMapper.fromMap(transformedResponse);
      return result;
    } catch (e, stack) {
      Log.e('Error adding equipmentLog', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Fetches all equipment logs from the enriched equipment logs view.
  /// 
  /// **Query Details:**
  /// - Uses `enriched_equipment_logs` view which includes aggregated equipment data
  /// - Orders by `collected_time` (most recently collected first, nulls first for pending returns)
  /// 
  /// **Returns**: List of all equipment logs with enriched data, ordered by collection time.
  /// 
  /// **Note**: Logs with `collected_time = null` appear first, indicating pending returns.
  /// Logs with collection times are ordered newest first.
  /// 
  /// **Use Case**: Used to display equipment rental history, track pending returns,
  /// and manage equipment inventory.
  Future<List<EnrichedEquipmentLogs>> fetchEnrichedEquipmentLogs() async {
    final List<dynamic> response = await supabase
        .from('enriched_equipment_logs')
        .select('*')
        .order('collected_time', ascending: false, nullsFirst: true);

    return response.map((item) {
      return EnrichedEquipmentLogsMapper.fromMap(item as Map<String, dynamic>);
    }).toList();
  }

  /// Completes the equipment return process.
  /// 
  /// **Multi-Step Process:**
  /// 1. Update equipment log with collector information and collection time
  /// 2. Mark all equipment items in the log as available (set `current_rented_person` to null)
  /// 3. Return the updated equipment log
  /// 
  /// **Parameters:**
  /// - `log`: The equipment log to complete (contains equipment items being returned)
  /// - `currentUser`: User who is collecting/returning the equipment
  /// 
  /// **Returns**: The updated equipment log with collector and collection time populated.
  /// 
  /// **Note**: This method marks all equipment items in the log as available by calling
  /// `updateEquipmentItemAvailability` with `renter = null`.
  /// 
  /// **Note**: Collection time is stored in UTC ISO 8601 format for consistency.
  /// 
  /// **Use Case**: When equipment is returned, this method records who collected it,
  /// when it was collected, and marks all items as available for future rentals.
  Future<EquipmentLog> completeEquipmentSubmission(EnrichedEquipmentLogs log, User currentUser) async {
    // Prepare update data with collector and collection time
    final updateData = {
      'collector_person_id': currentUser.id,
      'collected_time': DateTime.now().toUtc().toIso8601String(),
    };

    // Step 1: Update the equipment log with collector information
    final response =
        await supabase.from(SupabaseTable.equipmentLogs.toValue()).update(updateData).eq('id', log.logId).select('''
        *,
        renter_id:renter_person_id(*),
        approver_id:approver_person_id(*),
        collector_id:collector_person_id(*)
      ''').single();

    // Step 2: Mark all equipment items as available (set renter to null)
    await updateEquipmentItemAvailability(log.equipmentItems, null, null);

    // Step 3: Manually attach equipment items to response for mapping
    // The database doesn't return equipment items in the join, so we add them from the original log
    final transformedResponse = Map<String, dynamic>.from(response);
    transformedResponse['equipment_item'] = log.equipmentItems.map((e) => e.toMap()).toList();

    // Map to EquipmentLog and return
    return EquipmentLogMapper.fromMap(transformedResponse);
  }

  /// Uploads an equipment image to Supabase storage.
  /// 
  /// **Process:**
  /// 1. Read image file as bytes
  /// 2. Generate unique filename using current timestamp
  /// 3. Upload to Supabase storage bucket `equipment_items`
  /// 4. Get and return the public URL for the uploaded image
  /// 
  /// **Parameters:**
  /// - `imageFile`: The image file to upload
  /// 
  /// **Returns**: The public URL of the uploaded image, or null if upload failed.
  /// 
  /// **File Naming:**
  /// - Uses timestamp in milliseconds as filename to ensure uniqueness
  /// - Always uses `.jpg` extension regardless of original file format
  /// 
  /// **Storage Options:**
  /// - Uses `upsert: true` to overwrite if file with same name exists (shouldn't happen with timestamp)
  /// 
  /// **Use Case**: Upload equipment photos when creating or editing equipment items.
  /// The returned URL can be stored in the equipment item record for display in the UI.
  Future<String?> uploadEquipmentImage(File imageFile) async {
    try {
      // Read image file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // Generate unique filename using timestamp
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Supabase storage
      await supabase.storage
          .from('equipment_items')
          .uploadBinary(fileName, bytes, fileOptions: FileOptions(upsert: true));
      
      // Get public URL for the uploaded image
      final publicUrl = supabase.storage.from(SupabaseTable.equipmentItems.toValue()).getPublicUrl(fileName);
      Log.i("Image uploaded successfully: $publicUrl");
      return publicUrl;
    } catch (e, stack) {
      Log.e("Upload failed: $e", error: e, stackTrace: stack);
      return null;
    }
  }
}
