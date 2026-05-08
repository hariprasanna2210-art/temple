import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';
import 'package:temple_adventures_admin/features/user/bloc/user.cubit.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';

import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/custom_alert_dialog.dart';
import '../../../../widgets/tag_chip.dart';
import '../../../activities/models/activity.model.dart';
import '../../../user/enums/gender.enum.dart';
import '../../bloc/add_edit_quick_booking.cubit.dart';
import '../../bloc/bookings.cubit.dart';
import '../../enums/session_type.enum.dart';
import '../../models/booking.model.dart';
import '../../models/customer.model.dart';
import '../widgets/activity_dropdown.dart';
import '../widgets/time_slot_selector.dialog.dart';

class AddEditQuickBookingScreen extends StatefulWidget {
  const AddEditQuickBookingScreen({super.key, this.booking});

  final Booking? booking;

  /// When [booking] passed this screen updates the passed booking.
  static MaterialPageRoute<dynamic> route({Booking? booking}) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (context) => AddEditQuickBookingCubit(
          repository: locator<BookingsRepository>(),
          logRepository: locator<LogsRepository>(),
        ),
        child: AddEditQuickBookingScreen(booking: booking),
      ),
    );
  }

  @override
  State<AddEditQuickBookingScreen> createState() => _AddEditQuickBookingScreenState();
}

class _AddEditQuickBookingScreenState extends State<AddEditQuickBookingScreen> {
  late final TextEditingController _firstNameTED, _lastNameTED, _noOfPersonsTED, _cancellationReasonTED;
  Activity? _selectedActivity;
  Gender? _selectedGender;
  List<DateTime> _diveSessionDates = [];
  final _formKey = GlobalKey<FormState>();
  // Used to check if the booking date is changed, widget.booking?.diveDate is
  // not working because of some memory reference issues.
  List<DateTime>? _originalBookingDates;
  Booking? _originalBooking;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _originalBooking = BookingMapper.fromMap(widget.booking!.toMap());
    }
    _originalBookingDates = List.of(widget.booking?.diveDate ?? []);
    _firstNameTED = TextEditingController(text: widget.booking?.primaryCustomer.firstName);
    _lastNameTED = TextEditingController(text: widget.booking?.primaryCustomer.lastName);
    _noOfPersonsTED = TextEditingController(text: widget.booking?.noOfPersons.toString());
    _cancellationReasonTED = TextEditingController(text: widget.booking?.cancellationReason);
    _selectedActivity = widget.booking?.activity;
    _selectedGender = widget.booking?.primaryCustomer.gender;
    _diveSessionDates = widget.booking?.diveDate ?? [];
  }

  @override
  void dispose() {
    _firstNameTED.dispose();
    _lastNameTED.dispose();
    _noOfPersonsTED.dispose();
    super.dispose();
  }

  bool get isEditMode => widget.booking != null;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddEditQuickBookingCubit, AddEditQuickBookingState>(
      listener: (context, state) {
        final status = state.status;

        if (status is AddEditQuickBookingSuccess) {
          final BookingsCubit bookingsCubit = context.read<BookingsCubit>();

          // If the booking date is changed, we need to refetch bookings for the selected date.
          final DateTime selectedDateInBookingsScreen = bookingsCubit.state.selectedDate;

          _originalBookingDates?.addAll(_diveSessionDates);

          if (_originalBookingDates?.containsDateOnly(selectedDateInBookingsScreen) ?? false) {
            bookingsCubit.fetchBookings();
          }
          context.showSnackBar(
            (isEditMode) ? 'Quick booking updated successfully' : 'Quick booking created successfully',
          );
          Navigator.pop(context);
        }
        if (status is AddEditQuickBookingError) {
          context.showSnackBar(status.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          bottomNavigationBar: AppButton.flat(
            text: isEditMode ? 'Update booking' : 'Create booking',
            showLoading: state.status is AddEditQuickBookingLoading,
            onTap: _createOrUpdateBooking,
          ).paddingAll(20),
          appBar: CustomAppBar(
            title: 'Quick Booking',
            description: isEditMode ? 'Edit Quick Booking' : 'Add Quick Booking',
            action: isEditMode
                ? IconButton(
                    onPressed: () async {
                      final shouldDelete = await CustomAlertDialog.show(
                        context,
                        title: 'Are you sure ? This Booking will be deleted completely.',
                        childWidget: AppTextField(
                          controller: _cancellationReasonTED,
                          labelText: 'Cancellation Reason',
                        ),
                      );
                      if (shouldDelete == true) {
                        await _onDeletePressed();
                      }
                    },
                    icon: (state.status is AddEditQuickBookingLoading)
                        ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2).size(20, 20)
                        : Icon(Icons.delete, size: 20, color: Colors.white),
                  ).paddingOnly(right: 10)
                : SizedBox(),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _firstNameTED,
                          labelText: 'First Name *',
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                        ),
                      ),
                      Spacing.w10,
                      Expanded(
                        child: AppTextField(controller: _lastNameTED, labelText: 'Last Name'),
                      ),
                    ],
                  ),
                  AppTextField(
                    controller: _noOfPersonsTED,
                    labelText: 'No of persons *',
                    isStrictNumber: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'required';
                      if (int.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  AppDropdownButton<Gender>(
                    items: Gender.values,
                    initialValue: _selectedGender,
                    hintText: "Gender *",
                    validator: (value) => value == null ? 'required' : null,
                    onChanged: (gender) => _selectedGender = gender,
                    itemLabel: (gender) => gender.label,
                  ),
                  ActivityDropdown(
                    selectedActivity: _selectedActivity,
                    onChanged: (activity) => _selectedActivity = activity,
                  ),
                  _DiveSessionsSelector(
                    initialDates: _diveSessionDates,
                    onChanged: (updatedDates) => setState(() {
                      _diveSessionDates = updatedDates;
                    }),
                  ),
                ],
              ).paddingAll(20).scrollable,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDeletePressed() async {
    if (_cancellationReasonTED.text.trim().isEmpty) {
      context.showSnackBar('Please enter cancellation reason');
      return;
    }

    if (widget.booking == null) {
      context.showSnackBar('Booking not found');
      return;
    }

    final newBooking = widget.booking?.copyWith(
      cancelBooking: true,
      cancellationReason: _cancellationReasonTED.text,
    );

    context.read<AddEditQuickBookingCubit>().onSubmit(newBooking!);
  }

  Future<void> _createOrUpdateBooking() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedActivity == null) {
      context.showSnackBar('Please select an activity');
      return;
    }

    Customer? newCustomer = Customer(
      id: widget.booking?.primaryCustomer.id,
      firstName: _firstNameTED.text,
      lastName: _lastNameTED.text,
      gender: _selectedGender!,
      email: null,
      phoneNumber: null,
      countryCode: null,
      isoCode: null,
    );
    final newBooking = Booking(
      id: widget.booking?.id,
      noOfPersons: int.parse(_noOfPersonsTED.text),
      primaryCustomer: newCustomer,
      activity: _selectedActivity!,
      bookingDate: _diveSessionDates.map((d) => d.formatDDMMYYYY).toSet().toList(),
      createdBy: context.read<UserCubit>().state.currentUser!,
      diveDate: _diveSessionDates,
      isQuickBooking: true,
    );

    context.read<AddEditQuickBookingCubit>().onSubmit(newBooking, _originalBooking);
  }
}

class _DiveSessionsSelector extends StatelessWidget {
  const _DiveSessionsSelector({required this.onChanged, required this.initialDates});
  final ValueChanged<List<DateTime>> onChanged;
  final List<DateTime> initialDates;

  @override
  Widget build(BuildContext context) {
    return FormField<List<DateTime>>(
      initialValue: initialDates,
      validator: (value) {
        if ((value ?? []).isEmpty) return 'Required';
        return null;
      },
      builder: (FormFieldState<List<DateTime>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Dive Session'),
                const Spacer(),
                AppButton.miniFlat(
                  text: initialDates.isEmpty ? 'Select' : 'Change',
                  onTap: () async {
                    context.closeKeyboard();
                    final selectedSlot = await TimeSlotSelectorDialog.show(
                      context,
                      controller: EasyDatePickerController(),
                      sessionType: SessionType.diveSession,
                    );

                    if (selectedSlot != null && context.mounted) {
                      initialDates.add(selectedSlot);
                      field.didChange(initialDates);
                      onChanged(initialDates);
                    }
                  },
                ),
              ],
            ),
            Spacing.h20,
            Wrap(
              spacing: 10,
              children: initialDates.map((currentDate) {
                return TagChip(
                  title: currentDate.formatFullDateTime,
                  onTap: () {
                    initialDates.removeWhere((date) => date == currentDate);
                    field.didChange(initialDates);
                    onChanged(initialDates);
                  },
                ).paddingOnly(bottom: 10);
              }).toList(),
            ),
            if (field.errorText != null)
              Text(field.errorText!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)).left,
          ],
        );
      },
    );
  }
}
