import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../database/enums/supabase_tables.enum.dart';
import '../../../services/logging.dart';
import '../models/event.model.dart';

/// Repository for event-related database operations.
/// 
/// Handles CRUD operations for events. Events represent scheduled activities,
/// bookings, or special occasions that need to be tracked and managed.
class EventsRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  EventsRepository();

  /// Creates a new event in the database.
  /// 
  /// **Data Transformation:**
  /// - Removes `id` field (database will auto-generate)
  /// - Removes `created_by` object (replaced with `created_by_id` foreign key)
  /// - Removes `contact_person` object (replaced with `contact_person_id` foreign key)
  /// - Adds foreign key relationships for creator and contact person
  /// 
  /// **Returns**: The created event with database-generated ID and related objects populated,
  /// or null if creation failed.
  /// 
  /// **Note**: The `created_by` and `contact_person` objects are manually added back to
  /// the response because the database returns only foreign keys, but EventModelMapper
  /// expects full user objects.
  /// 
  /// **Use Case**: Creating new events such as group bookings, special occasions,
  /// or scheduled activities that need to be tracked in the system.
  Future<EventModel?> addEvent(EventModel event) async {
    // Prepare event data for insertion
    final Map<String, dynamic> eventMap = event.toMap();
    // Remove ID - database will auto-generate
    eventMap.remove('id');
    // Remove objects, use foreign keys instead
    eventMap.remove('created_by');
    eventMap.remove('contact_person');
    // Add foreign key relationships
    eventMap['created_by_id'] = event.createdBy.id;
    eventMap['contact_person_id'] = event.contactPerson.id;

    // Insert event into database
    final response = await supabase.from(SupabaseTable.events.toValue()).insert(eventMap).select('*').maybeSingle();
    if (response != null) {
      // Manually populate related objects in response
      // The database returns only foreign keys, but EventModelMapper expects full objects
      response['contact_person'] = event.contactPerson;
      response['created_by'] = event.createdBy;
      final EventModel result = EventModelMapper.fromMap(response);
      return result;
    }

    return null;
  }

  /// Updates an existing event in the database.
  /// 
  /// **Data Transformation:**
  /// - Removes `created_by` object (replaced with `created_by_id` foreign key)
  /// - Removes `contact_person` object (replaced with `contact_person_id` foreign key)
  /// - Adds foreign key relationships for creator and contact person
  /// 
  /// **Query Details:**
  /// - Uses Supabase's join syntax to fetch related user data:
  ///   - `created_by`: User who created the event
  ///   - `contact_person`: User who is the contact person for the event
  /// 
  /// **Throws**: Exception if event ID is null (event must exist to be updated).
  /// 
  /// **Returns**: The updated event with related user data populated.
  /// 
  /// **Note**: This updates all fields of the event. Ensure the model contains
  /// all required fields, not just the ones being changed.
  /// 
  /// **Use Case**: Updating event details such as date, time, description, or contact information.
  Future<EventModel> editEvent(EventModel event) async {
    if (event.id == null) {
      throw Exception('Event ID is required to edit event');
    }

    // Prepare event data for update
    final eventMap = event.toMap();
    // Remove objects, use foreign keys instead
    eventMap.remove('created_by');
    eventMap.remove('contact_person');
    // Add foreign key relationships
    eventMap['created_by_id'] = event.createdBy.id;
    eventMap['contact_person_id'] = event.contactPerson.id;

    // Update event in database and fetch related user data
    final response =
        await supabase.from(SupabaseTable.events.toValue()).update(eventMap).eq('id', event.id!).select('''
        *,
        created_by:created_by_id (*),
        contact_person:contact_person_id (*)
      ''').single();

    final EventModel updatedEvent = EventModelMapper.fromMap(response);
    return updatedEvent;
  }

  /// Deletes an event from the database.
  /// 
  /// **Process:**
  /// - Performs a hard delete (permanently removes the event record)
  /// 
  /// **Parameters:**
  /// - `id`: Event ID to delete
  /// 
  /// **Returns**: `true` if deletion succeeded, `false` if an error occurred.
  
  Future<bool> deleteEvent(int id) async {
    try {
      // Hard delete: permanently remove event from database
      await supabase.from(SupabaseTable.events.toValue()).delete().eq('id', id);
      return true;
    } catch (e, stack) {
      Log.e('Error deleting event', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Fetches all events from the database.
  /// 
  /// **Query Details:**
  /// - Uses Supabase's join syntax to fetch related user data:
  ///   - `created_by`: User who created each event
  ///   - `contact_person`: Contact person for each event
  /// - Orders results by `event_date_time` (ascending, earliest events first)
  
  Future<List<EventModel>> fetchAllEvents() async {
    final List<dynamic> response = await supabase
        .from(SupabaseTable.events.toValue())
        .select('''
        *,
        created_by:created_by_id (*),
        contact_person:contact_person_id (*)
      ''')
        .order('event_date_time', ascending: true);

    // Transform database response to EventModel objects
    return response.map((item) {
      return EventModelMapper.fromMap(item as Map<String, dynamic>);
    }).toList();
  }
}
