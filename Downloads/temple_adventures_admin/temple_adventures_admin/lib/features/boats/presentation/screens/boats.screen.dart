import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/boats/bloc/boats.cubit.dart';
import 'package:temple_adventures_admin/features/user/enums/access_levels.enum.dart';
import 'package:temple_adventures_admin/utils/access_levels.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/booking_timeline_date_selector.dart';
import '../../../../widgets/filtered_bookings_list.dart';

class BoatsScreen extends StatefulWidget {
  const BoatsScreen({super.key});

  @override
  State<BoatsScreen> createState() => _BoatsScreenState();
}

class _BoatsScreenState extends State<BoatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BoatsCubit>().fetchBookingAndBoats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AccessLevelWidget(
          accessLevel: AccessLevels.boatPlan,
          showMessage: true,
          child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocSelector<BoatsCubit, BoatsState, DateTime>(
                    selector: (state) {
                      return state.selectedDate;
                    },
                    builder: (context, selectedDate) {
                      return BookingTimelineDateSelector(
                        selectedDate: selectedDate,
                        onDateChange: (newDate) {
                          setState(() {
                            selectedDate = newDate;
                            context.read<BoatsCubit>().updateDateTime(selectedDate: newDate, refreshBookings: true);
                          });
                        },
                      );
                    },
                  ),
                  Spacing.h20,
                  BlocBuilder<BoatsCubit, BoatsState>(
                    builder: (context, state) {
                      return state.status.when(
                        initial: () => Text('Loading bookings').center.height(400),
                        loading: () => CircularProgressIndicator().center.height(400),
                        error: (message) => Text('Error: $message').center.height(400),
                        success: (bookings, boats) {
                          return FilteredBookingList(
                            isBoatsScreen: true,
                            key: ValueKey('boats_${context.read<BoatsCubit>().state.selectedDate.formatDDMMYYYY}'),
                            bookings: bookings,
                            selectedDate: state.selectedDate,
                            allBoats: boats,
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
