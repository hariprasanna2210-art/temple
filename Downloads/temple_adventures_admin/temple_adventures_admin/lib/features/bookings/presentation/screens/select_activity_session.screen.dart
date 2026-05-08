import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/bookings/models/booking.model.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/screens/booking_details.screen.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';

import '../../../../theme.dart';
import '../../../../widgets/app_button.dart';
import '../../../activities/models/activity.model.dart';
import '../../../user/bloc/user.cubit.dart';
import '../../enums/session_type.enum.dart';
import '../widgets/activity_dropdown.dart';
import '../widgets/session_selector.dart';

class SelectActivitySessionScreen extends StatefulWidget {
  const SelectActivitySessionScreen({super.key, required this.customer});

  final Customer customer;

  static MaterialPageRoute<dynamic> route({required Customer customer, }) {
    return MaterialPageRoute(builder: (_) => SelectActivitySessionScreen(customer: customer));
  }

  @override
  State<SelectActivitySessionScreen> createState() => _SelectActivitySessionScreenState();
}

class _SelectActivitySessionScreenState extends State<SelectActivitySessionScreen> {
  Activity? _selectedActivity;
  final List<DateTime> _theorySessionDates = [];
  final List<DateTime> _poolSessionDates = [];
  final List<DateTime> _diveSessionDates = [];
  final _formKey = GlobalKey<FormState>();
  final bool _areSessionsSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Choose Activity and Session ', description: ''),
      bottomNavigationBar: _buildActionButton().paddingAll(20),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Spacing.h10,
                  ActivityDropdown(
                    selectedActivity: _selectedActivity,
                    onChanged: (value) => _selectedActivity = value,
                  ),
                  Spacing.h20,
                  Text(
                    'Select sessions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: skyBlueColor),
                  ),
                  Spacing.h20,
                  SessionSelector(
                    title: 'Theory',
                    sessionDates: _theorySessionDates,
                    sessionType: SessionType.theorySession,
                    onSessionChanged: () => setState(() {}),
                  ),
                  Spacing.h20,

                  SessionSelector(
                    title: 'Pool',
                    sessionDates: _poolSessionDates,
                    sessionType: SessionType.poolSession,
                    onSessionChanged: () => setState(() {}),
                  ),

                  Spacing.h20,
                  SessionSelector(
                    title: 'Dive',
                    sessionDates: _diveSessionDates,
                    sessionType: SessionType.diveSession,
                    onSessionChanged: () => setState(() {}),
                  ),

                  Spacing.h20,
                  if (!_areSessionsSelected)
                    Text(
                      'Please select at least one session',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                ],
              ).paddingAll(20).scrollable,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return AppButton.flat(
      text: 'Continue',
      onTap: () {
        bool areSessionsSelected =
            _theorySessionDates.isNotEmpty || _poolSessionDates.isNotEmpty || _diveSessionDates.isNotEmpty;
        if (!areSessionsSelected) {
          if (_areSessionsSelected != areSessionsSelected) setState(() {});
          return;
        }
        if (_formKey.currentState?.validate() != true) return;
        final List<String> bookingDates =
            [
              ..._theorySessionDates,
              ..._poolSessionDates,
              ..._diveSessionDates,
            ].map((date) => date.formatDDMMYYYY).toSet().toList();

        Booking bookingsModel = Booking(
          primaryCustomer: widget.customer,
          noOfPersons: 1, // Default to 1 person (primary customer)
          activity: _selectedActivity!,
          theoryDate: _theorySessionDates,
          poolDate: _poolSessionDates,
          diveDate: _diveSessionDates,
          bookingDate: bookingDates,
          createdBy: context.read<UserCubit>().state.currentUser!,
        );
        Navigator.push(context, BookingDetailsScreen.route(booking: bookingsModel, activity: _selectedActivity!));
      },
    );
  }
}
