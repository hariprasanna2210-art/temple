import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import 'package:temple_adventures_admin/features/bookings/models/payment.model.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';

import '../../../database/enums/supabase_tables.enum.dart';
import '../models/all_bookings_filter.model.dart';
import '../models/booking.model.dart';

/// Repository for booking-related database operations.
/// 
/// Handles CRUD operations for bookings, customers, payments, and their relationships.
/// Manages complex operations like booking creation with multiple steps, date tracking,
/// and paginated queries with filters.
class BookingsRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Creates a new booking in the database.
  /// 
  /// **Multi-Step Process:**
  /// 1. **Resolve Primary Customer**: If customer doesn't have an ID, create it. Otherwise, update it.
  /// 2. **Insert Booking**: Create the booking record and get the booking ID.
  /// 3. **Link Primary Customer**: Add primary customer to the join table (customers_bookings).
  /// 4. **Create Booking Status Records**: For each booking date, create a booking_status entry
  ///    to track air/nitrox/boat assignments per date.
  /// 
  /// **Returns**: The created booking ID, or throws an exception if any step fails.
  /// 
  /// **Note**: The booking_status table is used to track equipment (air, nitrox) and boat
  /// assignments for each individual booking date, allowing flexibility for multi-day bookings.
  Future<int?> addBooking(Booking booking) async {
    // Step 1: Resolve primary customer
    // If customer is new (no ID), create it. If existing (has ID), update it.
    Customer? customer = booking.primaryCustomer;
    if (customer.id == null) {
      customer = await addCustomer(customer);
      booking = booking.copyWith(primaryCustomer: customer);
      if (customer == null) throw Exception('Failed to create customer');
    } else {
      await updateCustomer(customer);
    }

    // Step 2: Insert booking record
    // This creates the main booking entry and returns the generated booking ID
    final response =
        await supabase
            .from(
              SupabaseTable.bookings.toValue(),
            )
            .insert(booking.toRow())
            .select('id')
            .maybeSingle();

    final bookingId = response?['id'];
    if (bookingId == null) throw Exception('Failed to create booking');

    // Step 3: Link primary customer to booking in join table
    // The customers_bookings table is a many-to-many relationship table
    // that links customers to bookings (allows multiple customers per booking)
    await addPaxToBooking(bookingId: bookingId, customerId: customer.id!);

    // Step 4: Create booking_status entries for each booking date
    // This allows us to track equipment (air, nitrox) and boat assignments
    // separately for each date in a multi-day booking
    for (final date in booking.bookingDate) {
      final bookingStatus = {
        'booking_id': bookingId,
        'booking_date': date, // Must be a String in 'dd-MM-yyyy' format
        'nitrox': 0, // Initialized to 0, can be updated later
        'air': 0, // Initialized to 0, can be updated later
      };

      await supabase.from(SupabaseTable.bookingStatus.toValue()).insert(bookingStatus);
    }

    return bookingId;
  }

  /// Adds a customer as PAX (passenger) to an existing booking.
  /// 
  /// Creates a relationship in the `customers_bookings` join table, which is a
  /// many-to-many relationship allowing multiple customers per booking.
  /// 
  /// **Use Case**: When adding additional passengers to a booking after creation.
  /// 
  /// **Note**: The primary customer should already be linked during booking creation.
  /// This method is typically used to add additional passengers.
  Future<void> addPaxToBooking({
    required int bookingId,
    required int customerId,
  }) async {
    await supabase.from(SupabaseTable.customersBookings.toValue()).insert({
      'booking_id': bookingId,
      'customer_id': customerId,
    });
  }

  /// Updates an existing booking in the database.
  /// 
  /// **Flow:**
  /// 1. Update the primary customer information
  /// 2. Update the booking record itself
  /// 3. If `originalBooking` is provided, sync booking_status table:
  ///    - Remove booking_status entries for dates that were removed
  ///    - Add booking_status entries for new dates that were added
  /// 
  /// **Why sync booking_status?**
  /// The booking_status table tracks equipment and boat assignments per date.
  /// When booking dates change, we need to update this table to reflect the changes.
  /// 
  /// **Parameters:**
  /// - `updatedBooking`: The booking with updated information
  /// - `originalBooking`: (Optional) The original booking before changes.
  ///   If provided, booking dates will be synced. If null, only booking and customer are updated.
  /// 
  /// **Throws**: Exception if booking ID is null.
  Future<void> updateBooking(Booking updatedBooking, [Booking? originalBooking]) async {
    if (updatedBooking.id == null) throw Exception('Booking ID is required to edit booking');

    // Step 1: Update primary customer information
    final customer = updatedBooking.primaryCustomer;
    await updateCustomer(customer);

    // Step 2: Update the booking record
    await supabase
        .from(SupabaseTable.bookings.toValue())
        .update(updatedBooking.toRow(includeId: true))
        .eq('id', updatedBooking.id!);

    // Step 3: Sync booking_status table if original booking is provided
    // This handles date changes (additions and removals)
    if (originalBooking == null) return;
    
    List<DateTime> originalDates = originalBooking.allDates ?? [];
    List<DateTime> updatedDates = updatedBooking.allDates ?? [];

    // Remove booking_status entries for dates that were removed from the booking
    // Use Set to avoid duplicate deletions
    for (final removedDate in originalDates.map((date) => date.formatDDMMYYYY).toSet()) {
      await supabase
          .from(SupabaseTable.bookingStatus.toValue())
          .delete()
          .eq('booking_date', removedDate)
          .eq('booking_id', originalBooking.id!);
    }

    // Insert booking_status entries for new dates that were added
    // Use Set to avoid duplicate insertions
    final List<Map<String, dynamic>> newDateRows = [
      for (final newDate in updatedDates.map((date) => date.formatDDMMYYYY).toSet())
        {
          'booking_id': originalBooking.id!,
          'booking_date': newDate,
          'nitrox': 0, // Initialize to 0
          'air': 0, // Initialize to 0
        },
    ];
    await supabase.from(SupabaseTable.bookingStatus.toValue()).insert(newDateRows);
  }

  /// Adds a payment to a booking.
  /// 
  /// **Data Transformation:**
  /// - Removes `id` (database will auto-generate)
  /// - Removes `created_by` object (replaced with `created_by_id` foreign key)
  /// - Adds `booking_id` to link payment to booking
  /// 
  /// **Returns**: The created payment with database-generated ID, or null if creation failed.
  Future<Payment?> addPayment(Payment payment, int bookingId) async {
    final paymentMap = payment.toMap();

    // Remove fields that shouldn't be sent to database
    paymentMap.remove('id'); // Prevent sending `id: null` - database will auto-generate
    paymentMap.remove('created_by'); // Remove object, we'll use foreign key instead

    // Add foreign key relationships
    paymentMap['created_by_id'] = payment.createdBy.id;
    paymentMap['booking_id'] = bookingId;

    final response = await supabase.from(SupabaseTable.payments.toValue()).insert(paymentMap).select('*').maybeSingle();

    if (response != null) {
      // Re-add created_by object for mapping (PaymentMapper expects it)
      response['created_by'] = payment.createdBy;
      return PaymentMapper.fromMap(response);
    } else {
      return null;
    }
  }

  /// Updates an existing payment.
  /// 
  /// **Data Transformation:**
  /// - Removes `created_by` object (replaced with `created_by_id` foreign key)
  /// - Adds `booking_id` to maintain relationship
  /// 
  /// **Throws**: Exception if payment ID is null.
  Future<void> updatePayment(Payment payment, int bookingId) async {
    if (payment.id == null) {
      throw Exception('Payment ID is required to edit payment');
    }

    final paymentMap = payment.toMap();
    // Remove object, use foreign key instead
    paymentMap.remove('created_by');

    // Add foreign key relationships
    paymentMap['created_by_id'] = payment.createdBy.id;
    paymentMap['booking_id'] = bookingId;

    await supabase.from(SupabaseTable.payments.toValue()).update(paymentMap).eq('id', payment.id!);
  }

  /// Deletes a payment from the database.
  /// 
  /// **Note**: This is a hard delete. The payment will be permanently removed.
  Future<void> deletePayment(int paymentId) async {
    await supabase.from(SupabaseTable.payments.toValue()).delete().eq('id', paymentId);
  }

  /// Fetches all bookings for a specific date.
  /// 
  /// **Parameters:**
  /// - `date`: Date in 'DDMMYYYY' format (e.g., '25122024' for December 25, 2024)
  /// - `boatId`: (Optional) Filter bookings by specific boat
  /// 
  /// **Query Details:**
  /// - Uses `enriched_bookings_with_tanks` view which includes tank information
  /// - Fetches related data: activity, activity colors, all PAX customers, payments, and creator
  /// - Includes paper work details (need_doctor, paper_work_pdf_path) for each PAX
  /// 
  /// **Returns**: List of bookings ordered by creation time (oldest first).
  /// 
  /// **Note**: Each booking includes:
  /// - Primary customer (identified from PAX list by primary_customer_id)
  /// - All PAX customers with their paper work details
  /// - Activity and color information
  /// - All payments with creator information
  Future<List<Booking>> fetchBookings(String date, {int? boatId}) async {
    var query = supabase.from('enriched_bookings_with_tanks').select('''
      *,
  activity:activities (
    *,
    color:activity_colors (*)
  ),
  pax:customers_bookings!booking_id(
    customer:customers!customer_id(*),
    paper_work:customer_paper_work_details!paper_work_id(need_doctor,paper_work_pdf_path)
  ),
  payments:payments (
    *,
    created_by:users!payments_created_by_id_fkey (*)
  ),
  created_by:users!bookings_created_by_id_fkey (*)
      ''');
    // Filter by booking date
    query = query.eq('filter_booking_date', date);

    // Optionally filter by boat
    if (boatId != null) query = query.eq('boat_id', boatId);

    // Order by creation time (oldest first)
    final filteredQuery = query.order('created_at', ascending: true);
    final response = await filteredQuery;

    // Transform database response into Booking objects
    return (response as List).map((item) {
      // Parse all PAX customers from the join table
      // Each PAX entry includes customer data and paper work details
      final paxList =
          (item['pax'] as List<dynamic>).map((e) {
            final customerMap = e['customer'] as Map<String, dynamic>;
            final customerData = Map<String, dynamic>.from(customerMap);
            
            // Extract paper work details from the paper_work relation
            // paper_work is linked via paper_work_id in customers_bookings table
            // This allows each PAX to have their own paper work requirements
            final paperWork = e['paper_work'] as Map<String, dynamic>?;
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

      // Find the primary customer from the PAX list
      // The primary customer is identified by primary_customer_id in the booking
      final int primaryCustomerId = item['primary_customer_id'];
      final primaryCustomer = paxList.firstWhere(
        (c) => c.id == primaryCustomerId,
        orElse: () {
          // Fallback: if primary customer not found in PAX list, use first customer
          // This can happen if there's a data inconsistency (shouldn't happen in normal flow)
          if (paxList.isEmpty) {
            throw Exception('No customers found in booking ${item['id']}');
          }
          return paxList.first;
        },
      );

      // Map the database response to Booking model
      return BookingMapper.fromMap({...item, 'pax': paxList, 'primary_customer': primaryCustomer});
    }).toList();
  }

  /// Fetches bookings with pagination and filtering support.
  /// 
  /// **Pagination:**
  /// - `limit`: Maximum number of bookings to return
  /// - `offset`: Number of bookings to skip (for pagination)
  /// 
  /// **Filters Supported:**
  /// - `createdBy`: Filter by user(s) who created the booking
  /// - `dateRange`: Filter by date range (finds bookings that overlap with any date in range)
  /// - `activities`: Filter by activity type(s)
  /// - `isQuickBooking`: Filter by quick booking flag
  /// - `noOfPax`: Filter by number of passengers
  /// - `searchQuery`: Search by booking ID (if query is numeric)
  /// 
  /// **Query Details:**
  /// - Fetches related data: activity, activity colors, all PAX customers, payments, and creator
  /// - Includes paper work details for each PAX
  /// - Results ordered by creation time (newest first)
  /// 
  /// **Returns**: List of bookings matching the filters, limited by pagination.
  /// 
  /// **Note**: Date range filter uses `overlaps` to find bookings that have at least
  /// one date within the specified range.
  Future<List<Booking>> fetchPaginatedBookings({
    required int limit,
    required int offset,
    required AllBookingsFilters filters,
  }) async {
    var query = supabase.from(SupabaseTable.bookings.toValue()).select('''
      *,
  activity:activities (
    *,
    color:activity_colors (*)
  ),
  pax:customers_bookings!booking_id(
    customer:customers!customer_id(*),
    paper_work:customer_paper_work_details!paper_work_id(need_doctor,paper_work_pdf_path)
  ),
  payments:payments (
    *,
    created_by:users!payments_created_by_id_fkey (*)
  ),
  created_by:users!bookings_created_by_id_fkey (*)
      ''');

    // Apply filters based on AllBookingsFilters

    // Filter by creator(s)
    if (filters.createdBy?.isNotEmpty ?? false) {
      final userIds = filters.createdBy!.map((user) => user.id).toList();
      query = query.inFilter('created_by_id', userIds);
    }

    // Filter by date range
    // Generates all dates between start and end, then uses overlaps to find bookings
    // that have at least one date within the range
    if (filters.dateRange?.length == 2) {
      final startDate = filters.dateRange!.first;
      final endDate = filters.dateRange!.last;
      // Generate all dates in the range (inclusive)
      final allDates =
          List.generate(
            endDate.difference(startDate).inDays + 1,
            (index) => startDate.add(Duration(days: index)),
          ).map((date) => date.formatDDMMYYYY).toList();
      // Use overlaps to find bookings that have any date in the range
      query = query.overlaps('booking_date', allDates);
    }

    // Filter by activity type(s)
    if (filters.activities?.isNotEmpty ?? false) {
      final activityIds = filters.activities!.map((activity) => activity.id).toList();
      query = query.inFilter('activity_id', activityIds);
    }

    // Filter by quick booking flag
    if (filters.isQuickBooking != null) {
      query = query.eq('is_quick_booking', filters.isQuickBooking!);
    }

    // Filter by number of passengers
    if (filters.noOfPax != null) {
      query = query.eq('no_of_persons', filters.noOfPax!);
    }

    // Search by booking ID (if search query is numeric)
    if (filters.searchQuery?.isNotEmpty ?? false) {
      final text = filters.searchQuery!.toLowerCase();
      final bookingId = int.tryParse(text);
      if (bookingId != null) query = query.eq('id', text);
    }

    // Apply pagination and ordering
    // Order by creation time (newest first) and limit results
    final filteredQuery = query.order('created_at', ascending: false).range(offset, offset + limit - 1);

    final response = await filteredQuery;

    // Transform database response into Booking objects
    // (Same transformation logic as fetchBookings)
    return (response as List).map((item) {
      // Parse all PAX customers from the join table
      final paxList =
          (item['pax'] as List<dynamic>).map((e) {
            final customerMap = e['customer'] as Map<String, dynamic>;
            final customerData = Map<String, dynamic>.from(customerMap);
            // Extract paper work details from the paper_work relation
            // paper_work is linked via paper_work_id in customers_bookings table
            final paperWork = e['paper_work'] as Map<String, dynamic>?;
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

      // Find the primary customer from the PAX list
      final int primaryCustomerId = item['primary_customer_id'];
      final primaryCustomer = paxList.firstWhere(
        (c) => c.id == primaryCustomerId,
        orElse: () {
          // Fallback: if primary customer not found in PAX list, use first customer
          // This can happen if there's a data inconsistency (shouldn't happen in normal flow)
          if (paxList.isEmpty) {
            throw Exception('No customers found in booking ${item['id']}');
          }
          return paxList.first;
        },
      );

      // Map the database response to Booking model
      return BookingMapper.fromMap({...item, 'pax': paxList, 'primary_customer': primaryCustomer});
    }).toList();
  }

  /// Removes a customer from a booking.
  /// 
  /// **Note**: This only removes the relationship in the join table.
  /// The customer record itself is not deleted (customers can be in multiple bookings).
  /// 
  /// **Use Case**: When removing a PAX from a booking.
  Future<void> deleteCustomer(int bookingId, int customerId) async {
    await supabase
        .from(SupabaseTable.customersBookings.toValue())
        .delete()
        .eq('booking_id', bookingId)
        .eq('customer_id', customerId);
  }

  /// Creates a new customer in the database.
  /// 
  /// **Returns**: The created customer with database-generated ID, or null if creation failed.
  Future<Customer?> addCustomer(Customer customer) async {
    final customerMap = customer.toRow();

    final response =
        await supabase.from(SupabaseTable.customers.toValue()).insert(customerMap).select('*').maybeSingle();

    if (response != null) {
      return CustomerMapper.fromMap(response);
    } else {
      return null;
    }
  }

  /// Updates an existing customer in the database.
  /// 
  /// **Throws**: Exception if customer ID is null (customer must exist to be updated).
  Future<void> updateCustomer(Customer customer) async {
    final customerMap = customer.toRow(removeId: false);
    await supabase.from(SupabaseTable.customers.toValue()).update(customerMap).eq('id', customer.id!);
  }

  /// Finds a customer by email address.
  /// 
  /// **Use Case**: Check if a customer already exists before creating a new one.
  /// 
  /// **Returns**: The customer if found, null otherwise.
  /// 
  /// **Note**: Only returns the first match (limit: 1).
  Future<Customer?> fetchCustomerByEmail({required String emailId}) async {
    final response =
        await supabase.from(SupabaseTable.customers.toValue()).select().eq('email', emailId).limit(1).maybeSingle();

    if (response == null) return null;

    return CustomerMapper.fromMap(response);
  }
}
