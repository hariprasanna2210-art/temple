import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:temple_adventures_admin/features/bookings/bloc/bookings.cubit.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/screens/add_customer_details.screen.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/screens/add_edit_quick_booking.screen.dart';
import 'package:temple_adventures_admin/features/user/enums/access_levels.enum.dart';
import 'package:temple_adventures_admin/utils/access_levels.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import '../../../../widgets/booking_timeline_date_selector.dart';
import '../../../../widgets/filtered_bookings_list.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingsCubit>().fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AccessLevelWidget(
        accessLevel: AccessLevels.addBooking,
        child: _BookingFAB(),
      ),
      body: SafeArea(
        child: AccessLevelWidget(
          accessLevel: AccessLevels.viewBookings,
          showMessage: true,
          child:
              Column(
                children: [
                  BlocSelector<BookingsCubit, BookingsState, DateTime>(
                    selector: (state) {
                      return state.selectedDate;
                    },
                    builder: (context, selectedDate) {
                      return BookingTimelineDateSelector(
                        selectedDate: selectedDate,
                        onDateChange: (newDate) {
                          setState(() {
                            selectedDate = newDate;
                            context.read<BookingsCubit>().updateDateTime(selectedDate: newDate, refreshBookings: true);
                          });
                        },
                      );
                    },
                  ),
                  Spacing.h20,
                  BlocBuilder<BookingsCubit, BookingsState>(
                    builder: (context, state) {
                      return state.status.when(
                        initial: () => Text('Loading bookings').center.height(400),
                        loading: () => CircularProgressIndicator().center.height(400),
                        error: (message) => Text('Error: $message').center.height(400),
                        success: (bookings) {
                          return FilteredBookingList(
                            key: ValueKey(
                              'bookings_${context.read<BookingsCubit>().state.selectedDate.formatDDMMYYYY}',
                            ),
                            bookings: bookings,
                            selectedDate: state.selectedDate,
                          );
                        },
                      );
                    },
                  ),
                  Spacing.h60,
                ],
              ).paddingAll(20).scrollable,
        ),
      ),
    );
  }
}

class _BookingFAB extends StatelessWidget {
  const _BookingFAB();

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      elevation: 0,
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Colors.black,
      direction: SpeedDialDirection.up,
      animationDuration: Duration(milliseconds: 300),
      overlayColor: Colors.black,
      overlayOpacity: 0.4,
      spacing: 12,
      spaceBetweenChildren: 10,
      childrenButtonSize: const Size(60, 60),
      children: [
        SpeedDialChild(
          child: Icon(Icons.flash_on, color: Colors.white, size: 20),
          elevation: 0,
          backgroundColor: Colors.black,
          label: 'Quick Booking',
          labelBackgroundColor: Colors.black,
          labelStyle: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200)),
          onTap: () {
            Navigator.push(context, AddEditQuickBookingScreen.route());
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.event_note, color: Colors.white, size: 20),
          elevation: 0,
          backgroundColor: Colors.black,
          label: 'Normal Booking',
          labelBackgroundColor: Colors.black,
          labelStyle: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200)),
          onTap: () {
            Navigator.push(context, AddCustomerDetailsScreen.route());
          },
        ),
      ],
    );
  }
}
