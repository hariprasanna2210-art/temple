import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temple_adventures_admin/features/checklists/models/template.model.dart';

import '../../../database/enums/supabase_tables.enum.dart';
import '../../../services/shared_preference_service.dart';

/// Repository for managing checklist templates and their items.
/// 
/// This repository handles CRUD operations for checklist templates, which are reusable
/// checklists that can be assigned to boats or used for various operational tasks.
/// Templates consist of a template definition and multiple template items (checklist items).
/// 
/// **Key Features:**
/// - Template management (create, update, delete templates)
/// - Template items management (items are stored in a separate table with foreign key relationship)
/// - Home screen integration (templates can be pinned to home screen via SharedPreferences)
/// - View-based queries (uses `templates_with_items` view for efficient data retrieval)
/// 
/// **Database Structure:**
/// - `templates` table: Stores template metadata (name, description, etc.)
/// - `template_items` table: Stores individual checklist items linked to templates via `template_id`
/// - `templates_with_items` view: Pre-joined view for fetching templates with their items
class ChecklistRepository {
  ChecklistRepository();

  final SupabaseClient supabase = Supabase.instance.client;

  /// Adds a new checklist template with its items to the database.
  /// 
  /// **Flow:**
  /// 1. Converts the template to a map (excluding ID for new entries)
  /// 2. Inserts the template into the `templates` table and retrieves the generated template ID
  /// 3. Maps each template item to include the new template ID
  /// 4. Inserts all template items into the `template_items` table
  /// 
  /// **Data Transformation:**
  /// - Template items are transformed to include the newly generated `template_id`
  /// - Uses `copyWith(templateId: templateId)` to associate items with the template
  /// - Items are inserted in a batch operation for efficiency
  /// 
  /// **Parameters:**
  /// - `template`: The template object to add. Should have `id` as `null` for new entries.
  /// 
  /// **Note**: If template insertion fails (no ID returned), the method returns early
  /// without inserting items. This ensures data consistency.
  /// 
  /// **Use Case**: Creating new checklist templates (e.g., "Pre-dive Safety Checklist",
  /// "Boat Maintenance Checklist") that can be reused across multiple boats or operations.
  Future<void> addTemplate(Template template) async {
    final templateMap = template.toRow(includeId: false);

    // Step 1: Insert template into templates table
    final response = await supabase.from(SupabaseTable.templates.toValue()).insert(templateMap).select();

    final templateId = response.firstOrNull?['id'];

    if (templateId == null) return;

    // Step 2: Build a list of item maps with template_id
    final itemsWithTemplateId =
        template.items.map((item) {
          return item.copyWith(templateId: templateId).toMap();
        }).toList();

    // Step 3: Insert items into template_items table
    await supabase.from(SupabaseTable.templateItems.toValue()).insert(itemsWithTemplateId);
  }

  /// Updates an existing checklist template and its items.
  /// 
  /// **Flow:**
  /// 1. Converts the template to a map (including ID for updates)
  /// 2. Updates the template record in the `templates` table
  /// 3. Deletes all existing template items for this template (clean slate approach)
  /// 4. Maps each updated template item to include the template ID
  /// 5. Inserts the updated template items into the `template_items` table
  /// 
  /// **Data Transformation:**
  /// - Uses "delete and recreate" pattern for template items to handle additions, removals, and modifications
  /// - Template items are transformed to include the template ID
  /// - Items are inserted in a batch operation for efficiency
  /// 
  /// **Parameters:**
  /// - `updatedTemplate`: The template object with updated data. Must have a non-null `id`.
  /// 
  /// **Note**: This method uses a "delete and recreate" pattern for template items, which means:
  /// - All existing items are deleted first
  /// - Then all items (including new, modified, and unchanged) are reinserted
  /// - This approach simplifies handling of item additions, removals, and modifications
  /// 
  /// **Use Case**: Updating existing checklist templates (e.g., adding new checklist items,
  /// modifying item descriptions, reordering items, or updating template metadata).
  Future<void> updateTemplate(Template updatedTemplate) async {
    final templateMap = updatedTemplate.toRow(includeId: true);

    await supabase.from(SupabaseTable.templates.toValue()).update(templateMap).eq('id', updatedTemplate.id!);

    // Step 1: Delete existing rows in table template_items for the given templateId
    await supabase.from(SupabaseTable.templateItems.toValue()).delete().eq('template_id', updatedTemplate.id!);

    // Step 2: Build a list of item maps with template_id
    final itemsWithTemplateId =
        updatedTemplate.items.map((item) {
          return item.copyWith(templateId: updatedTemplate.id).toMap();
        }).toList();

    // Step 3: Insert items into template_items table
    await supabase.from(SupabaseTable.templateItems.toValue()).insert(itemsWithTemplateId);
  }

  /// Fetches all checklist templates with their items from the database.
  /// 
  /// **Query Details:**
  /// - Uses the `templates_with_items` view for efficient data retrieval
  /// - The view pre-joins templates with their associated template items
  /// - Returns all templates regardless of home screen pinning status
  /// 
  /// **Returns**: A list of all templates with their populated items.
  /// 
  /// **Use Case**: Displaying all available checklist templates in the templates list screen,
  /// allowing users to browse, select, and manage templates.
  Future<List<Template>> fetchTemplates() async {
    final templates = await supabase.from('templates_with_items').select();

    return (templates as List).map((item) => TemplateMapper.fromMap(item)).toList();
  }

  /// Deletes a checklist template from the database and removes it from home screen.
  /// 
  /// **Flow:**
  /// 1. Deletes the template from the `templates` table (cascades to template items via foreign key)
  /// 2. Removes the template ID from SharedPreferences (home screen pinned templates)
  /// 
  /// **Parameters:**
  /// - `templateId`: The ID of the template to delete
  /// 
  /// **Note**: This is a hard delete - the template and its items will be permanently removed
  /// from the database. The template is also removed from the home screen if it was pinned there.
  /// 
  /// **Cascade Behavior**: Deleting a template will automatically delete all associated
  /// template items due to foreign key constraints (or explicit cascade delete).
  /// 
  /// **Use Case**: Removing checklist templates that are no longer needed (e.g., outdated
  /// templates, test templates, or templates that have been replaced by newer versions).
  Future<void> deleteTemplate(int templateId) async {
    // Step 1: Delete from Supabase
    await supabase.from(SupabaseTable.templates.toValue()).delete().eq('id', templateId);

    // Step 2: Remove templateId from SharedPreferences
    deleteChecklistToHome(templateId);
  }

  /// Adds a template ID to SharedPreferences for home screen display.
  /// 
  /// **Process:**
  /// - Adds the template ID (as a string) to a list stored in SharedPreferences
  /// - This marks the template as "pinned" to the home screen
  /// 
  /// **Parameters:**
  /// - `templateId`: The ID of the template to pin to the home screen
  /// 
  /// **Use Case**: Allowing users to pin frequently used checklist templates to the home screen
  /// for quick access, improving workflow efficiency.
  Future<void> addChecklistToHome(int templateId) async {
    await SharedPrefKeys.templateIds.addToStringList(templateId.toString());
  }

  /// Removes a template ID from SharedPreferences (unpins from home screen).
  /// 
  /// **Process:**
  /// - Removes the template ID (as a string) from the list stored in SharedPreferences
  /// - This unpins the template from the home screen
  /// 
  /// **Parameters:**
  /// - `templateId`: The ID of the template to unpin from the home screen
  /// 
  /// **Use Case**: Allowing users to unpin checklist templates from the home screen when
  /// they are no longer frequently used, keeping the home screen clean and organized.
  Future<void> deleteChecklistToHome(int templateId) async {
    await SharedPrefKeys.templateIds.removeFromStringList(templateId.toString());
  }

  /// Retrieves the list of template IDs stored in SharedPreferences (pinned templates).
  /// 
  /// **Returns**: A list of template IDs (as strings) that are pinned to the home screen.
  /// Returns an empty list if no templates are pinned.
  /// 
  /// **Use Case**: Checking which templates are currently pinned to the home screen,
  /// used for displaying pinned templates or determining pin status in the UI.
  List<String> getTemplateIdsFromPrefs() {
    return SharedPrefKeys.templateIds.getStringList ?? [];
  }

  /// Fetches checklist templates from Supabase using IDs stored in SharedPreferences.
  /// 
  /// **Flow:**
  /// 1. Retrieves the list of template IDs from SharedPreferences (pinned templates)
  /// 2. If the list is empty, returns an empty list immediately
  /// 3. Converts string IDs to integers for database query
  /// 4. Fetches templates from the `templates_with_items` view using `inFilter` to match IDs
  /// 
  /// **Query Details:**
  /// - Uses the `templates_with_items` view for efficient data retrieval
  /// - Uses `inFilter` to fetch only templates whose IDs are in the SharedPreferences list
  /// - Returns templates with their populated items
  /// 
  /// **Returns**: A list of templates that are pinned to the home screen, with their
  /// populated items. Returns an empty list if no templates are pinned.
  /// 
  /// **Use Case**: Loading pinned checklist templates for display on the home screen,
  /// providing quick access to frequently used checklists.
  Future<List<Template>> getTemplatesFromPrefs() async {
    final ids = SharedPrefKeys.templateIds.getStringList ?? [];

    if (ids.isEmpty) return [];

    final response = await supabase.from('templates_with_items').select().inFilter('id', ids.map(int.parse).toList());

    return (response as List).map((item) => TemplateMapper.fromMap(item)).toList();
  }
}
