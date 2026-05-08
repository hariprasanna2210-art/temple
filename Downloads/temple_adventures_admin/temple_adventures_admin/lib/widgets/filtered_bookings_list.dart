import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:temple_adventures_admin/features/boats/models/boats.model.dart';
import 'package:temple_adventures_admin/features/boats/repository/boats.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/tag_chip.dart';
import '../features/boats/presentation/screens/add_edit_boat_details.screen.dart';
import '../features/boats/presentation/widgets/boat_details_card.dart';
import '../features/bookings/models/booking.model.dart';
import '../features/bookings/presentation/widgets/booking_details_card.dart';
import '../features/bookings/presentation/widgets/custom_title.dart';
import '../features/bookings/presentation/widgets/tab_button.dart';
import '../features/bookings/repository/bookings.repository.dart';
import '../theme.dart';
import '../utils/debouncer.dart';
import '../utils/styling/app_measurements.dart';
import '../utils/styling/spacing_widgets.dart';
import 'bloc/filtered_bookings_list.cubit.dart';
import 'empty_state_message.dart';

class FilteredBookingList extends StatefulWidget {
  final List<Booking> bookings;
  final DateTime selectedDate;
  final bool isBoatsScreen;
  final List<Boat>? allBoats;

  const FilteredBookingList({
    super.key,
    required this.bookings,
    required this.selectedDate,
    this.isBoatsScreen = false,
    this.allBoats,
  });

  @override
  State<FilteredBookingList> createState() => _FilteredBookingListState();
}

class _FilteredBookingListState extends State<FilteredBookingList> {
  final Map<BookingSession, Color> sessionColors = {
    BookingSession.theory: Colors.orangeAccent,
    BookingSession.pool: Colors.green,
    BookingSession.dive: Colors.lightBlueAccent,
  };

  late Map<BookingSession, int> sessionCounts;
  BookingSession? _bookingSession; // Selected session
  DateTime? _selectedTime; // Selected time slot
  Map<DateTime, int> times = {}; // All available times for selected session/date
  Boat? _selectedBoat;
  @override
  void initState() {
    super.initState();
    _calculateSessionCounts();
  }

  // Count the number of bookings for each session type
  void _calculateSessionCounts() {
    int theoryCount = 0, poolCount = 0, diveCount = 0;
    for (final booking in widget.bookings) {
      if ((booking.theoryDate ?? []).containsDateOnly(widget.selectedDate)) theoryCount += booking.noOfPersons;
      if ((booking.poolDate ?? []).containsDateOnly(widget.selectedDate)) poolCount += booking.noOfPersons;
      if ((booking.diveDate ?? []).containsDateOnly(widget.selectedDate)) diveCount += booking.noOfPersons;
    }
    sessionCounts = {
      BookingSession.theory: theoryCount,
      BookingSession.pool: poolCount,
      BookingSession.dive: diveCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookings.isEmpty) return EmptyStateMessage(message: 'No bookings for selected date');

    return BlocProvider(
      create:
          (context) => FilteredBookingsListCubit(
            bookingsRepository: locator<BookingsRepository>(),
            boatsRepository: locator<BoatsRepository>(),
            bookings: widget.bookings,
          ),
      child: BlocBuilder<FilteredBookingsListCubit, FilteredBookingsListState>(
        builder: (context, state) {
          List<Booking> filteredBookings = state.filterBookings(
            selectedDate: widget.selectedDate,
            selectedTime: _selectedTime,
            selectedBoat: _selectedBoat,
            selectedSession: _bookingSession,
          );

          times = state.getAvailableTimes(
            selectedDate: widget.selectedDate,
            selectedSession: _bookingSession,
            selectedBoat: _selectedBoat,
          );

          return Column(
            children: [
              // Session toggle buttons
              Row(
                children: [
                  ...BookingSession.values.map(
                    (session) => TabButton(
                      title: session.title,
                      onTap: () {
                        setState(() => _bookingSession = session);
                        _selectedTime = null;
                        _selectedBoat = null;
                      },
                      enable: _bookingSession == session,
                      color: sessionColors[session],
                      count: sessionCounts[session]!,
                    ),
                  ),
                ],
              ),

              Spacing.h16,

              // All boats of the day if it is boats screen
              if (widget.isBoatsScreen)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...?widget.allBoats?.map((boat) {
                      return TagChip(
                        title: boat.nameAndTime,
                        color: _selectedBoat == boat ? lightSkyBlue : Colors.grey.withAlpha(30),
                        onTap: () {
                          setState(() {
                            _selectedBoat = boat;
                            _selectedTime = null;
                          });
                        },
                        onLongPress: () {
                          Navigator.push(context, AddEditBoatDetailsScreen.route(boat: boat));
                        },
                        fullTap: true,
                      );
                    }),
                  ],
                ),

              Spacing.h16,
              // Time chip selector
              _BookingTimeSelector(
                times: times,
                onTimeSelected: (time) => setState(() => _selectedTime = time),
                selectedTime: _selectedTime,
              ),
              Spacing.h16,

              // Booking list
              _BookingList(
                key: ValueKey(filteredBookings),
                bookings: filteredBookings,
                selectedDate: widget.selectedDate,
                isBoatsScreen: widget.isBoatsScreen,
                allBoats: widget.allBoats,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingList extends StatefulWidget {
  final List<Booking> bookings;
  final DateTime selectedDate;
  final bool isBoatsScreen;
  final List<Boat>? allBoats;

  const _BookingList({
    super.key,
    required this.bookings,
    required this.selectedDate,
    required this.isBoatsScreen,
    this.allBoats,
  });

  @override
  State<_BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<_BookingList> {
  final TextEditingController searchController = TextEditingController();
  final Debouncer searchDebouncer = Debouncer(delay: const Duration(milliseconds: 200));

  @override
  Widget build(BuildContext context) {
    if (widget.bookings.isEmpty) return EmptyStateMessage(message: 'No bookings for selected filters');
    final selectedDate = widget.selectedDate;
    final searchQuery = searchController.text.toLowerCase();

    // Filter bookings by customer info or booking ID
    final filteredBookings =
        widget.bookings.where((booking) {
          final id = booking.id.toString();
          final paxString =
              [booking.primaryCustomer, ...?booking.pax]
                  .map((c) => '${c.firstName}${c.lastName ?? ''}${c.email ?? ''}${c.phoneNumber ?? ''}')
                  .join()
                  .toLowerCase();

          return '$id$paxString'.contains(searchQuery);
        }).toList();
    return Column(
      children: [
        // Search bar - only show if there are bookings to search
        if (widget.bookings.isNotEmpty) ...[
          Container(
            height: 47,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Spacing.w15,
                const Icon(Icons.search, color: Colors.black45, size: 20),
                Spacing.w15,
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => searchDebouncer.call(() => setState(() {})),
                    cursorHeight: 14, // Smaller cursor
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Spacing.h16,
        ],

        // Show message when no bookings match filters (but only for boats screen)
        if (filteredBookings.isEmpty && widget.isBoatsScreen)
          Text('No bookings match the selected filters').center.height(200),

        // Show message when no bookings match filters (for non-boats screen)
        if (filteredBookings.isEmpty && !widget.isBoatsScreen)
          Text('No bookings for selected filters').center.height(400),

        // Display filtered booking cards
        ...filteredBookings.map(
          (booking) =>
              (widget.isBoatsScreen)
                  ? BoatDetailsCard(
                    key: ValueKey(booking.id),
                    booking: booking,
                    selectedDate: selectedDate,
                    allBoats: widget.allBoats ?? [],
                  ).paddingOnly(bottom: 20)
                  : BookingDetailsCard(
                    key: ValueKey(booking.id),
                    booking: booking,
                    showBookingsForDateOnly: selectedDate,
                  ).paddingOnly(bottom: 20),
        ),
      ],
    );
  }
}

class _BookingTimeSelector extends StatelessWidget {
  final Map<DateTime, int> times;
  final ValueChanged<DateTime> onTimeSelected;
  final DateTime? selectedTime;

  const _BookingTimeSelector({required this.times, required this.onTimeSelected, required this.selectedTime});

  @override
  Widget build(BuildContext context) {
    if (times.isEmpty) return SizedBox.shrink();

    return Container(
      width: Screen.width,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadiusDirectional.circular(10)),
      child: Column(
        children: [
          Row(children: [CustomTitle(title: 'Bookings'), Spacing.w3, const SizedBox()]),
          Spacing.h10,
          Wrap(
            spacing: 0,
            runSpacing: 5,
            runAlignment: WrapAlignment.start,
            alignment: WrapAlignment.start,
            children: [
              ...times.keys.map(
                (date) => _TimeChip(
                  time: date,
                  onTap: () => onTimeSelected(date),
                  isSelected: selectedTime == date,
                  bookingsCount: times[date]?.toString() ?? '0',
                ),
              ),
            ],
          ).left,
        ],
      ).paddingAll(16),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final DateTime time;
  final VoidCallback onTap;
  final bool isSelected;
  final String bookingsCount;

  const _TimeChip({required this.time, required this.onTap, required this.isSelected, required this.bookingsCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            color: Colors.white,
            child: Center(
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: isSelected ? lightSkyBlue : Colors.grey.withAlpha(30),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: (time.minute == 0) ? DateFormat('hh').format(time) : DateFormat('hh:mm').format(time),
                      style: TextStyle(color: Colors.black, fontSize: 10),
                      children: <TextSpan>[
                        TextSpan(
                          text: (time.minute == 0) ? DateFormat(' a').format(time) : DateFormat('\na').format(time),
                          style: const TextStyle(fontSize: 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(border: Border.all(color: skyBlueColor), shape: BoxShape.circle),
          child:
              Text(
                bookingsCount,
                style: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.w600),
              ).center,
        ),
      ],
    );
  }
}

// Enum to represent the type of booking session
enum BookingSession { theory, pool, dive }

// Extension to provide title for each booking session
extension _BookingSessionExtension on BookingSession {
  String get title => switch (this) {
    BookingSession.theory => 'Theory',
    BookingSession.pool => 'Pool',
    BookingSession.dive => 'Dive',
  };
}
