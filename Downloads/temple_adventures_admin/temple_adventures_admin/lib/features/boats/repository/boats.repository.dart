import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temple_adventures_admin/features/general_info/models/general_info.model.dart';

import '../../../database/enums/supabase_tables.enum.dart';
import '../../../utils/extensions/date_time.extensions.dart';
import '../../bookings/models/booking.model.dart';
import '../../bookings/models/customer.model.dart';
import '../../events/models/event.model.dart';
import '../models/board_plan_response.model.dart';
import '../models/boat_info.model.dart';
import '../models/boats.model.dart';

/// Repository for boat and general info related database operations.
/// 
/// Handles CRUD operations for boats, boat status, tank assignments, and general info.
/// Manages the `user_tanks` join table which links users to boats/general_info/booking_status
/// with their tank assignments (air, nitrox) and roles.
class BoatsRepository {
  BoatsRepository();

  final SupabaseClient supabase = Supabase.instance.client;

  /// Updates tank information for a specific booking status.
  /// 
  /// **Use Case**: When assigning/updating tank assignments (air, nitrox) and roles
  /// for users on a specific booking date.
  /// 
  /// **Flow:**
  /// 1. Delete all existing tank assignments for the booking status
  /// 2. Insert new tank assignments
  /// 
  /// **Note**: This uses a "delete and recreate" pattern to ensure the tank info
  /// exactly matches what's provided, avoiding complex diff logic.
  /// 
  /// **Parameters:**
  /// - `tankInfo`: List of tank assignments (user, air, nitrox, role)
  /// - `bookingStatusId`: The booking_status ID to update (links to a specific booking date)
  Future<void> updateTankInfo({required List<TankInfo> tankInfo, required int bookingStatusId}) async {
    // Step 1: Delete all existing tank assignments for this booking status
    // This ensures we start fresh and avoid orphaned records
    await supabase.from(SupabaseTable.userTanks.toValue()).delete().eq('booking_status_id', bookingStatusId);

    // Step 2: Prepare new tank assignment rows
    final List<Map<String, dynamic>> userTankRows = [
      for (final tank in tankInfo)
        {
          'booking_status_id': bookingStatusId,
          'user_id': tank.userId,
          'air': tank.air, // Number of air tanks assigned
          'nitrox': tank.nitrox, // Number of nitrox tanks assigned
          'role': tank.role?.toValue(), // User's role (captain, instructor, etc.)
        },
    ];

    // Step 3: Insert new tank assignments
    // Skip if no tank info provided (allows clearing all assignments)
    if (userTankRows.isEmpty) return;
    await supabase.from(SupabaseTable.userTanks.toValue()).insert(userTankRows);
  }

  /// Updates boat status information for a booking date.
  /// 
  /// **Use Case**: Update the boat assignment, air count, or nitrox count for a specific booking date.
  /// 
  /// **Parameters:**
  /// - `bookingStatusId`: The booking_status ID (represents a booking date)
  /// - `air`: (Optional) Total air tanks for this booking date
  /// - `nitrox`: (Optional) Total nitrox tanks for this booking date
  /// - `boatId`: (Optional) Boat assigned to this booking date
  /// 
  /// **Note**: All parameters are optional - only provided values will be updated.
  Future<void> updateBoatStatus({required int bookingStatusId, int? air, int? nitrox, int? boatId}) async {
    await supabase
        .from(SupabaseTable.bookingStatus.toValue())
        .update({'air': air, 'nitrox': nitrox, 'boat_id': boatId})
        .eq('id', bookingStatusId);
  }

  /// Creates a new boat in the database.
  /// 
  /// **Multi-Step Process:**
  /// 1. Insert boat record and get the generated boat ID
  /// 2. Link users to the boat in the `user_tanks` table with their tank assignments
  /// 
  /// **Note**: The `user_tanks` table is a join table that can link users to:
  /// - Boats (via `boat_id`)
  /// - General info (via `general_info_id`)
  /// - Booking status (via `booking_status_id`)
  /// 
  /// This allows tracking tank assignments and roles in different contexts.
  Future<void> addBoat(Boat boat) async {
    // Step 1: Insert boat record and retrieve the generated boat ID
    final boatMap = boat.toRow(includeId: false);
    var response = await supabase.from(SupabaseTable.boats.toValue()).insert(boatMap).select();
    final boatId = response.firstOrNull?['id'];

    // Step 2: Prepare user tank assignments for this boat
    final List<Map<String, dynamic>> userTankRows = [
      for (final TankInfo tank in boat.users)
        {
          'boat_id': boatId,
          'user_id': tank.userId,
          'air': tank.air,
          'nitrox': tank.nitrox,
          'role': tank.role?.toValue(),
        },
    ];

    // Step 3: Insert user tank assignments
    // Skip if no users assigned (boat can exist without users)
    if (userTankRows.isEmpty) return;
    await supabase.from(SupabaseTable.userTanks.toValue()).insert(userTankRows);
  }

  /// Updates an existing boat in the database.
  /// 
  /// **Flow:**
  /// 1. Update the boat record itself
  /// 2. Delete all existing user tank assignments for this boat
  /// 3. Insert new user tank assignments
  /// 
  /// **Note**: Uses "delete and recreate" pattern for user assignments to ensure
  /// the assignments exactly match the updated boat's user list.
  /// 
  /// **Throws**: Exception if boat ID is null.
  Future<void> updateBoat(Boat updatedBoat) async {
    // Step 1: Update the boat record
    final boatMap = updatedBoat.toRow(includeId: true);
    await supabase.from(SupabaseTable.boats.toValue()).update(boatMap).eq('id', updatedBoat.id!);

    // Step 2: Delete all existing user tank assignments for this boat
    // This ensures we start fresh with the new assignments
    await supabase.from(SupabaseTable.userTanks.toValue()).delete().eq('boat_id', updatedBoat.id!);

    // Step 3: Prepare new user tank assignments
    final List<Map<String, dynamic>> userTankRows = [
      for (final tank in updatedBoat.users)
        {
          'boat_id': updatedBoat.id!,
          'user_id': tank.userId,
          'air': tank.air,
          'nitrox': tank.nitrox,
          'role': tank.role?.toValue(),
        },
    ];

    // Step 4: Insert new user tank assignments
    // Skip if no users assigned (allows clearing all assignments)
    if (userTankRows.isEmpty) return;
    await supabase.from(SupabaseTable.userTanks.toValue()).insert(userTankRows);
  }

  /// Fetches all boats for a specific date.
  /// 
  /// **Query Details:**
  /// - Uses `boats_with_user_info` view which includes user tank assignments
  /// - Filters by date
  /// 
  /// **Data Transformation:**
  /// - Categorizes users by role into separate arrays:
  ///   - `captains`: Boat captains
  ///   - `dsd_instructors`: DSD (Discover Scuba Diving) instructors
  ///   - `photographers`: Photographers
  ///   - `intern_photographers`: Intern photographers
  ///   - `surface_support`: Surface support staff
  /// - Other roles (instructor, buddy, etc.) are not categorized for boats
  /// 
  /// **Returns**: List of boats with users categorized by role.
  /// 
  /// **Note**: The role-based categorization makes it easier to display and manage
  /// different types of staff on boats in the UI.
  Future<List<Boat>> fetchBoatsByDate(String selectedDate) async {
    final response = await supabase.from('boats_with_user_info').select('*').eq('date', selectedDate);
    return (response as List<dynamic>).map((item) {
      // Initialize role-based arrays for boat-specific roles
      item['captains'] = [];
      item['dsd_instructors'] = [];
      item['photographers'] = [];
      item['intern_photographers'] = [];
      item['surface_support'] = [];
      
      // Categorize users by their role
      final users = item['users'] as List<dynamic>;
      for (final user in users) {
        final tankInfo = TankInfoMapper.fromMap(user);
        switch (tankInfo.role) {
          case Role.captains:
            item['captains'].add(tankInfo);
            break;

          case Role.internPhotographers:
            item['intern_photographers'].add(tankInfo);
            break;

          case Role.photographers:
            item['photographers'].add(tankInfo);
            break;

          case Role.surfaceSupport:
            item['surface_support'].add(tankInfo);
            break;

          case Role.dsdInstructors:
            item['dsd_instructors'].add(tankInfo);
            break;

          // Roles not used for boats (used in general info instead)
          case null:
          case Role.instructor:
          case Role.buddy:
          case Role.dsdPool:
          case Role.dsdOceanLeader:
          case Role.dsdCenterStaff:
          case Role.harbourStaff:
          case Role.dayOffs:
          case Role.leaves:
            // These roles are not categorized for boats
            break;
        }
      }

      return BoatMapper.fromMap(item as Map<String, dynamic>);
    }).toList();
  }

  /// Deletes a boat from the database.
  /// 
  /// **Note**: This is a hard delete. The boat and its associated user_tanks records
  /// (if any) will be permanently removed. Ensure foreign key constraints allow deletion.
  Future<void> deleteBoat(int boatId) async {
    await supabase.from(SupabaseTable.boats.toValue()).delete().eq('id', boatId);
  }

  /// Creates new general info for a date.
  /// 
  /// **Use Case**: General info tracks staff assignments, day-offs, leaves, and other
  /// non-boat-specific information for a given date.
  /// 
  /// **Multi-Step Process:**
  /// 1. Insert general info record and get the generated ID
  /// 2. Link users to the general info in the `user_tanks` table with their assignments
  /// 
  /// **Note**: Similar to boats, general info uses the `user_tanks` join table to track
  /// user assignments, tank counts, and roles.
  Future<void> addGeneralInfo(GeneralInfo generalInfo) async {
    final generalInfoMap = generalInfo.toRow(includeId: false);

    // Step 1: Insert general info record and retrieve the generated ID
    var response = await supabase.from(SupabaseTable.generalInfo.toValue()).insert(generalInfoMap).select();

    final generalInfoId = response.firstOrNull?['id'];

    // Step 2: Prepare user tank assignments for this general info
    final List<Map<String, dynamic>> userTankRows = [
      for (final TankInfo tank in generalInfo.users)
        {
          'general_info_id': generalInfoId,
          'user_id': tank.userId,
          'air': tank.air,
          'nitrox': tank.nitrox,
          'role': tank.role?.toValue(),
        },
    ];

    // Step 3: Insert user tank assignments
    // Skip if no users assigned (general info can exist without users)
    if (userTankRows.isEmpty) return;
    await supabase.from(SupabaseTable.userTanks.toValue()).insert(userTankRows);
  }

  /// Updates existing general info in the database.
  /// 
  /// **Flow:**
  /// 1. Update the general info record itself
  /// 2. Delete all existing user tank assignments for this general info
  /// 3. Insert new user tank assignments
  /// 
  /// **Note**: Uses "delete and recreate" pattern for user assignments to ensure
  /// the assignments exactly match the updated general info's user list.
  /// 
  /// **Throws**: Exception if general info ID is null.
  Future<void> updateGeneralInfo(GeneralInfo updatedGeneralInfo) async {
    // Step 1: Update the general info record
    final generalInfoMap = updatedGeneralInfo.toRow(includeId: true);
    await supabase.from(SupabaseTable.generalInfo.toValue()).update(generalInfoMap).eq('id', updatedGeneralInfo.id!);

    // Step 2: Delete all existing user tank assignments for this general info
    // This ensures we start fresh with the new assignments
    await supabase.from(SupabaseTable.userTanks.toValue()).delete().eq('general_info_id', updatedGeneralInfo.id!);

    // Step 3: Prepare new user tank assignments
    final List<Map<String, dynamic>> userTankRows = [
      for (final tank in updatedGeneralInfo.users)
        {
          'general_info_id': updatedGeneralInfo.id!,
          'user_id': tank.userId,
          'air': tank.air,
          'nitrox': tank.nitrox,
          'role': tank.role?.toValue(),
        },
    ];

    // Step 4: Insert new user tank assignments
    // Skip if no users assigned (allows clearing all assignments)
    if (userTankRows.isEmpty) return;
    await supabase.from(SupabaseTable.userTanks.toValue()).insert(userTankRows);
  }

  /// Fetches general info for a specific date.
  /// 
  /// **Query Details:**
  /// - Uses `general_info_with_user_info` view which includes user tank assignments
  /// - Filters by date
  /// 
  /// **Data Transformation:**
  /// - Categorizes users by role into separate arrays:
  ///   - `dsd_pool`: DSD pool staff
  ///   - `dsd_ocean_leader`: DSD ocean leaders
  ///   - `dsd_center_staff`: DSD center staff
  ///   - `harbour_staff`: Harbour staff
  ///   - `day_offs`: Staff on day off
  ///   - `leaves`: Staff on leave
  /// - Other roles (instructor, buddy, captains, etc.) are not categorized for general info
  /// 
  /// **Returns**: General info with users categorized by role, or null if no general info exists for the date.
  /// 
  /// **Note**: The role-based categorization makes it easier to display and manage
  /// different types of staff assignments in the UI.
  /// 
  /// **Warning**: There appears to be a mapping issue in lines 217-222 where
  /// `dsdCenterStaff` maps to `dsd_ocean_leader` and `dsdOceanLeader` maps to `dsd_center_staff`.
  /// This may be intentional or a bug - verify with business logic.
  Future<GeneralInfo?> fetchGeneralInfoByDate(String selectedDate) async {
    final response = await supabase.from('general_info_with_user_info').select('*').eq('date', selectedDate);

    if (response.isEmpty) {
      return null; // No general_info found for that date
    }

    final item = response.first;

    // Initialize role-based arrays for general info-specific roles
    item['dsd_pool'] = [];
    item['dsd_ocean_leader'] = [];
    item['dsd_center_staff'] = [];
    item['harbour_staff'] = [];
    item['day_offs'] = [];
    item['leaves'] = [];

    // Categorize users by their role
    final users = item['users'] as List<dynamic>? ?? [];

    for (final user in users) {
      final tankInfo = TankInfoMapper.fromMap(user);
      switch (tankInfo.role) {
        case Role.dsdPool:
          item['dsd_pool'].add(tankInfo);
          break;

        case Role.dsdCenterStaff:
          // Note: This maps to 'dsd_ocean_leader' - verify if this is correct
          item['dsd_ocean_leader'].add(tankInfo);
          break;

        case Role.dsdOceanLeader:
          // Note: This maps to 'dsd_center_staff' - verify if this is correct
          item['dsd_center_staff'].add(tankInfo);
          break;

        case Role.harbourStaff:
          item['harbour_staff'].add(tankInfo);
          break;

        case Role.dayOffs:
          item['day_offs'].add(tankInfo);
          break;

        case Role.leaves:
          item['leaves'].add(tankInfo);
          break;

        // Roles not used for general info (used in boats instead)
        case null:
        case Role.instructor:
        case Role.buddy:
        case Role.captains:
        case Role.internPhotographers:
        case Role.photographers:
        case Role.dsdInstructors:
        case Role.surfaceSupport:
          // These roles are not categorized for general info
          break;
      }
    }

    return GeneralInfoMapper.fromMap(item);
  }

  /// Use this method to update the TV information immediately,
  Future<void> updateBoardPlanData(DateTime date) async {
    // Fetch the current board plan data
    final response = await fetchBoardPlanData(date);

    // Save to board_plan table
    await saveBoardPlanData(date, response);
  }

  Future<BoardPlanResponse> fetchBoardPlanData(DateTime date) async {
    final selectedDate = date.formatDDMMYYYY;
    final response = await supabase.rpc(
      'fetch_board_plan_data',
      params: {
        'selected_date': selectedDate,
      },
    );

    final boats = _parseBoats(response['boats'] as List<dynamic>?);
    final info = _parseGeneralInfo(response['general_info'] as Map<String, dynamic>?);
    final bookings = _parseBookings(response['bookings'] as List<dynamic>?);
    final events = _parseEvents(response['events'] as List<dynamic>?);

    return BoardPlanResponse(
      boats: boats,
      generalInfo: info,
      bookings: bookings,
      events: events,
    );
  }

  /// Saves board plan data to the board_plan table
  /// Uses upsert to insert or update the row based on the date primary key
  Future<void> saveBoardPlanData(DateTime date, BoardPlanResponse data) async {
    final selectedDate = date.formatDDMMYYYY;

    try {
      final row = {
        'date': selectedDate,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'data': data.toMap(),
      };

      await supabase.from('board_plan').upsert(row);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving board plan data: $e');
      }
      rethrow;
    }
  }

  /// Parses boats data from the combined function response
  /// Same role categorization logic as fetchBoatsByDate
  List<Boat> _parseBoats(List<dynamic>? boatsData) {
    if (boatsData == null) return [];

    return boatsData.map((item) {
      final boatMap = Map<String, dynamic>.from(item as Map<String, dynamic>);
      boatMap['captains'] = [];
      boatMap['dsd_instructors'] = [];
      boatMap['photographers'] = [];
      boatMap['intern_photographers'] = [];
      boatMap['surface_support'] = [];
      final boatUsers = boatMap['users'] as List<dynamic>? ?? [];

      for (final user in boatUsers) {
        final tankInfo = TankInfoMapper.fromMap(user);
        switch (tankInfo.role) {
          case Role.captains:
            boatMap['captains'].add(tankInfo);
            break;

          case Role.internPhotographers:
            boatMap['intern_photographers'].add(tankInfo);
            break;

          case Role.photographers:
            boatMap['photographers'].add(tankInfo);
            break;

          case Role.surfaceSupport:
            boatMap['surface_support'].add(tankInfo);
            break;

          case Role.dsdInstructors:
            boatMap['dsd_instructors'].add(tankInfo);
            break;

          case null:
          case Role.instructor:
          case Role.buddy:
          case Role.dsdPool:
          case Role.dsdOceanLeader:
          case Role.dsdCenterStaff:
          case Role.harbourStaff:
          case Role.dayOffs:
          case Role.leaves:
            break;
        }
      }
      return BoatMapper.fromMap(boatMap);
    }).toList();
  }

  /// Parses general info data from the combined function response
  /// Same role categorization logic as fetchGeneralInfoByDate
  GeneralInfo? _parseGeneralInfo(Map<String, dynamic>? generalInfoData) {
    if (generalInfoData == null) return null;

    final item = Map<String, dynamic>.from(generalInfoData);
    // Initialize role-based arrays
    item['dsd_pool'] = [];
    item['dsd_ocean_leader'] = [];
    item['dsd_center_staff'] = [];
    item['harbour_staff'] = [];
    item['day_offs'] = [];
    item['leaves'] = [];

    final generalInfoUsers = item['users'] as List<dynamic>? ?? [];

    for (final user in generalInfoUsers) {
      final tankInfo = TankInfoMapper.fromMap(user);
      switch (tankInfo.role) {
        case Role.dsdPool:
          item['dsd_pool'].add(tankInfo);
          break;

        case Role.dsdCenterStaff:
          item['dsd_ocean_leader'].add(tankInfo);
          break;

        case Role.dsdOceanLeader:
          item['dsd_center_staff'].add(tankInfo);
          break;

        case Role.harbourStaff:
          item['harbour_staff'].add(tankInfo);
          break;

        case Role.dayOffs:
          item['day_offs'].add(tankInfo);
          break;

        case Role.leaves:
          item['leaves'].add(tankInfo);
          break;

        // Roles you aren't categorizing
        case null:
        case Role.instructor:
        case Role.buddy:
        case Role.captains:
        case Role.internPhotographers:
        case Role.photographers:
        case Role.dsdInstructors:
        case Role.surfaceSupport:
          break;
      }
    }

    return GeneralInfoMapper.fromMap(item);
  }

  /// Parses bookings data from the combined function response
  /// Same logic as fetchBookings
  List<Booking> _parseBookings(List<dynamic>? bookingsData) {
    if (bookingsData == null) return [];

    return bookingsData
        .map((item) {
          try {
            final bookingMap = Map<String, dynamic>.from(item as Map<String, dynamic>);

            // Parse all pax customers
            final paxList = _parsePaxCustomers(bookingMap['pax'] as List<dynamic>?);

            final int primaryCustomerId = bookingMap['primary_customer_id'];
            final primaryCustomer = paxList.firstWhere(
              (c) => c.id == primaryCustomerId,
              orElse: () {
                // Fallback: if primary customer not found in pax list, use first customer
                // This can happen if there's a data inconsistency
                if (paxList.isEmpty) {
                  throw Exception('No customers found in booking ${bookingMap['id']}');
                }
                return paxList.first;
              },
            );

            final Map<String, dynamic> processedBookingMap = {
              ...bookingMap,
              'pax': paxList,
              'primary_customer': primaryCustomer.toMap(),
            };
            return BookingMapper.fromMap(processedBookingMap);
          } catch (e, s) {
            if (kDebugMode) {
              print('Error parsing booking: $e');
              print(s);
            }
            return null;
          }
        })
        .whereType<Booking>()
        .toList();
  }

  /// Parses pax customers from booking data
  List<Customer> _parsePaxCustomers(List<dynamic>? paxData) {
    if (paxData == null) return [];

    return paxData.map((e) {
      final paxEntry = e as Map<String, dynamic>;
      final customerMap = paxEntry['customer'] as Map<String, dynamic>;
      final customerData = Map<String, dynamic>.from(customerMap);

      // Extract need_doctor and paper_work_pdf_path from paper_work relation at the pax entry level
      // paper_work is linked via paper_work_id in customers_bookings table
      final paperWork = paxEntry['paper_work'] as Map<String, dynamic>?;
      if (paperWork != null) {
        if (paperWork.containsKey('need_doctor')) {
          customerData['need_doctor'] = paperWork['need_doctor'];
        }
        if (paperWork.containsKey('paper_work_pdf_path')) {
          customerData['paper_work_pdf_path'] = paperWork['paper_work_pdf_path'];
        }
      }
      return CustomerMapper.fromMap(customerData);
    }).toList();
  }

  /// Parses events data from the combined function response
  /// Same logic as fetchEventsByDate
  List<EventModel> _parseEvents(List<dynamic>? eventsData) {
    if (eventsData == null) return [];

    return eventsData.map((item) => EventModelMapper.fromMap(item as Map<String, dynamic>)).toList();
  }
}
