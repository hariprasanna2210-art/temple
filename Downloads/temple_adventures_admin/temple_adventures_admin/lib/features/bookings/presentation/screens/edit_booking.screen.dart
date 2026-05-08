import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:temple_adventures_admin/features/bookings/bloc/edit_booking.cubit.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';
import 'package:temple_adventures_admin/features/user/bloc/user.cubit.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../theme.dart';
import '../../../../utils/locator.dart';
import '../../../../utils/price_calculator.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/custom_alert_dialog.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/phone_number.dart';
import '../../../activities/models/activity.model.dart';
import '../../../user/enums/gender.enum.dart';
import '../../bloc/bookings.cubit.dart';
import '../../enums/discount_type.enum.dart';
import '../../enums/session_type.enum.dart';
import '../../models/booking.model.dart';
import '../../models/customer.model.dart';
import '../../repository/bookings.repository.dart';
import '../widgets/activity_dropdown.dart';
import '../widgets/discount_switch_field.dart';
import '../widgets/session_selector.dart';

class EditBookingScreen extends StatefulWidget {
  final Booking? booking;
  const EditBookingScreen({super.key, this.booking});
  static MaterialPageRoute<dynamic> route({Booking? booking}) => MaterialPageRoute(
    builder:
        (_) => BlocProvider(
          create:
              (context) =>
                  EditBookingCubit(repository: locator<BookingsRepository>(), logRepository: locator<LogsRepository>()),
          child: EditBookingScreen(booking: booking),
        ),
  );

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  late final TextEditingController _emailTED,
      _firstNameTED,
      _lastNameTED,
      _phoneNumberTED,
      _noOfPersonsTED,
      _priceTED,
      _discountTED,
      _remarksTED,
      _cancellationReasonTED;
  Activity? _selectedActivity;
  Gender? _selectedGender;
  DiscountType? discountType;
  bool isTaxApplied = true;
  String? _countryCode;
  String? _isoCode;
  final List<DateTime> _theorySessionDates = [];
  final List<DateTime> _poolSessionDates = [];
  final List<DateTime> _diveSessionDates = [];
  // Used to check if the booking date is changed, widget.booking?.diveDate is
  // not working because of some memory reference issues.
  List<DateTime>? _originalBookingDates;

  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _originalBookingDates =
        <DateTime>{
          ...?widget.booking?.diveDate,
          ...?widget.booking?.poolDate,
          ...?widget.booking?.theoryDate,
        }.toList();

    _emailTED = TextEditingController(text: widget.booking?.primaryCustomer.email);
    _firstNameTED = TextEditingController(text: widget.booking?.primaryCustomer.firstName);
    _lastNameTED = TextEditingController(text: widget.booking?.primaryCustomer.lastName);
    _phoneNumberTED = TextEditingController(text: widget.booking?.primaryCustomer.phoneNumber);
    _noOfPersonsTED = TextEditingController(text: widget.booking?.noOfPersons.toString());
    _priceTED = TextEditingController(text: widget.booking?.price.toString());
    _discountTED = TextEditingController(text: widget.booking?.discount?.toString() ?? '');
    _remarksTED = TextEditingController(text: widget.booking?.remarks);
    _cancellationReasonTED = TextEditingController(text: widget.booking?.cancellationReason);
    _selectedActivity = widget.booking?.activity;
    _selectedGender = widget.booking?.primaryCustomer.gender;
    discountType = widget.booking?.discountType ?? DiscountType.percentage;
    isTaxApplied = (widget.booking?.taxPercent == 18) ? true : false;
    _countryCode = widget.booking?.primaryCustomer.countryCode;
    _isoCode = widget.booking?.primaryCustomer.isoCode;
    _theorySessionDates.addAll(widget.booking?.theoryDate ?? []);
    _poolSessionDates.addAll(widget.booking?.poolDate ?? []);
    _diveSessionDates.addAll(widget.booking?.diveDate ?? []);
  }

  @override
  void dispose() {
    _emailTED.dispose();
    _firstNameTED.dispose();
    _lastNameTED.dispose();
    _phoneNumberTED.dispose();
    _noOfPersonsTED.dispose();
    _priceTED.dispose();
    _discountTED.dispose();
    _remarksTED.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditBookingCubit, EditBookingState>(
      listener: (context, state) {
        final status = state.status;
        if (status is EditBookingSuccess) {
          if (widget.booking == null) return;
          final BookingsCubit bookingsCubit = context.read<BookingsCubit>();

          // If the booking date is changed, we need to fetch the bookings again
          final DateTime selectedDateInBookingsScreen = bookingsCubit.state.selectedDate;

          if (_originalBookingDates?.containsDateOnly(selectedDateInBookingsScreen) ?? false) {
            bookingsCubit.fetchBookings();
          }

          context.showSnackBar('Booking Updated Successfully');
          Navigator.popUntil(context, (route) => route.settings.name == 'DashboardScreen');
        }
        if (status is EditBookingError) {
          context.showSnackBar(status.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Edit Booking',
            description: 'Edit  Booking',
            action: IconButton(
              onPressed: _onDeletePressed,
              icon:
                  (state.status is EditBookingLoading)
                      ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2).size(20, 20)
                      : Icon(Icons.delete, size: 20, color: Colors.white),
            ).paddingOnly(right: 10),
          ),
          bottomNavigationBar: AppButton.flat(
            text: 'Update booking',
            showLoading: state.status is EditBookingLoading,
            onTap: _createOrUpdateBooking,
          ).paddingAll(20),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Spacing.h10,
                      AppTextField(
                        controller: _emailTED,
                        labelText: 'Customer Email Id',
                        keyboardType: TextInputType.emailAddress,
                        required: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'required';
                          }
                          return null;
                        },
                      ),
                      Spacing.h20,
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
                          Expanded(child: AppTextField(controller: _lastNameTED, labelText: 'Last Name')),
                        ],
                      ),
                      Spacing.h20,
                      PhoneNumberInput(
                        controller: _phoneNumberTED,
                        required: true,
                        initialCountryCode: _isoCode,
                        validator: (PhoneNumber? phone) {
                          try {
                            if (phone != null && phone.isValidNumber()) {
                              return null;
                            }
                            return 'required';
                          } catch (_) {
                            return 'Invalid Mobile Number';
                          }
                        },
                        onChanged: (phone) {
                          _countryCode = phone.countryCode;
                          _isoCode = phone.countryISOCode;
                        },
                        onCountryChanged: (country) {
                          _countryCode = country.dialCode;
                          _isoCode = country.code;
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
                      Spacing.h20,
                      AppTextField(
                        controller: _noOfPersonsTED,
                        labelText: 'No of persons *',
                        isStrictNumber: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'required';
                          if (int.tryParse(value) == null) return 'Invalid number';
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            // Rebuild to update total price
                          });
                        },
                      ),
                      Spacing.h20,
                      ActivityDropdown(
                        selectedActivity: _selectedActivity,
                        onChanged: (activity) => _selectedActivity = activity,
                      ),
                      Spacing.h20,
                      AppTextField(
                        controller: _priceTED,
                        labelText: 'Price',
                        required: true,
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                        onChanged: (value) {
                          setState(() {
                            // Rebuild to update total price
                          });
                        },
                      ),
                      Spacing.h20,
                      DiscountSwitchField(
                        controller: _discountTED,
                        initialDiscountType: discountType!,
                        totalAmount: totalPrice,
                        onDiscountTypeChanged: (DiscountType value) {
                          setState(() {
                            discountType = value;
                          });
                        },
                        onDiscountChanged: (String value) {
                          setState(() {
                            // Rebuild to update discount value
                          });
                        },
                      ),
                      Spacing.h10,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tax', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          SizedBox(
                            width: 70,
                            height: 75,
                            child: Switch(
                              value: isTaxApplied,
                              onChanged: (value) {
                                setState(() {
                                  isTaxApplied = value;
                                });
                              },
                              activeThumbColor: skyBlueColor,
                              inactiveThumbColor: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text(
                            '₹ ${totalWithTaxAndDiscount.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Spacing.h10,
                      AppTextField(labelText: 'Remarks', controller: _remarksTED, required: false, maxLines: 3),
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
                    ],
                  ).paddingAll(20).scrollable,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDeletePressed() async {
    final shouldDelete = await CustomAlertDialog.show(
      context,
      title: 'Are you sure ? This Booking will be deleted completely.',
      childWidget: AppTextField(controller: _cancellationReasonTED, labelText: 'Cancellation Reason'),
    );

    if (shouldDelete != true || !mounted) return;

    if (_cancellationReasonTED.text.trim().isEmpty) {
      context.showSnackBar('Please enter cancellation reason');
      return;
    }

    if (widget.booking == null) {
      context.showSnackBar('Booking not found');
      return;
    }

    final newBooking = widget.booking?.copyWith(cancelBooking: true, cancellationReason: _cancellationReasonTED.text);

    context.read<EditBookingCubit>().onUpdate(newBooking!);
  }

  Future<void> _createOrUpdateBooking() async {
    if (_formKey.currentState?.validate() != true) return;

    final List<String> bookingDates =
        [
          ..._theorySessionDates,
          ..._poolSessionDates,
          ..._diveSessionDates,
        ].map((date) => date.formatDDMMYYYY).toSet().toList();

    Customer? newCustomer = Customer(
      id: widget.booking?.primaryCustomer.id,
      firstName: _firstNameTED.text,
      lastName: _lastNameTED.text,
      email: _emailTED.text,
      phoneNumber: _phoneNumberTED.text,
      countryCode: _countryCode,
      isoCode: _isoCode,
      gender: _selectedGender!,
    );
    final newBooking = Booking(
      id: widget.booking?.id,
      noOfPersons: int.parse(_noOfPersonsTED.text),
      primaryCustomer: newCustomer,
      activity: _selectedActivity!,
      bookingDate: bookingDates,
      createdBy: context.read<UserCubit>().state.currentUser!,
      theoryDate: _theorySessionDates,
      poolDate: _poolSessionDates,
      diveDate: _diveSessionDates,
      price: _priceTED.text.toDoubleOrZero(),
      discount: _discountTED.text.toDoubleOrZero(),
      discountType: discountType,
      taxPercent: isTaxApplied ? 18 : 0,
      remarks: _remarksTED.text,
      isQuickBooking: false,
    );
    context.read<EditBookingCubit>().onUpdate(newBooking, widget.booking);
  }

  double get totalPrice => _priceTED.text.toDoubleOrZero() * _noOfPersonsTED.text.toDoubleOrZero();

  double get discountAmount => PriceCalculator.calculateDiscount(
    totalPrice: totalPrice,
    discountValue: _discountTED.text.toDoubleOrZero(),
    discountType: discountType!,
  );

  double get totalWithTaxAndDiscount => PriceCalculator.calculateTotalWithTaxAndDiscount(
    totalPrice: totalPrice,
    taxPercent: isTaxApplied ? 18 : 0,
    discountValue: _discountTED.text.toDoubleOrZero(),
    discountType: discountType!,
  );
}
