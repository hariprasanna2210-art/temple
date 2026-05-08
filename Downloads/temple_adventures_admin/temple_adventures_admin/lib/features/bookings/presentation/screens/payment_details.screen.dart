import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/bookings/bloc/bookings.cubit.dart';
import 'package:temple_adventures_admin/features/bookings/bloc/payment_details.cubit.dart';
import 'package:temple_adventures_admin/features/bookings/enums/payment_modes.enum.dart';
import 'package:temple_adventures_admin/features/bookings/models/booking.model.dart';
import 'package:temple_adventures_admin/features/bookings/models/payment.model.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_text_field.dart';
import 'package:temple_adventures_admin/widgets/custom_alert_dialog.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';

import '../../../../utils/price_calculator.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../../widgets/custom_date_picker.dart';
import '../../../user/bloc/user.cubit.dart';

/// Creates a booking with an initial deposit or updates existing payment records or adds new payment if needed.

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({
    super.key,
    required this.booking,
    this.initialPayingAmount,
    required this.createBookingOnSubmit,
    this.editPayment,
  });

  final Booking booking;
  final double? initialPayingAmount;
  final bool createBookingOnSubmit;
  final Payment? editPayment;

  /// Get initial payment information and then create a new booking when submit pressed.
  static MaterialPageRoute route({required Booking booking, required double initialPayingAmount}) => MaterialPageRoute(
    builder: (context) {
      return PaymentDetailsScreen(
        booking: booking,
        initialPayingAmount: initialPayingAmount,
        createBookingOnSubmit: true,
        editPayment: null,
      );
    },
  );

  static MaterialPageRoute editPaymentRoute({required Booking booking, Payment? editPayment}) => MaterialPageRoute(
    builder: (context) {
      return PaymentDetailsScreen(booking: booking, createBookingOnSubmit: false, editPayment: editPayment);
    },
  );

  static MaterialPageRoute addPaymentRoute({required Booking booking}) => MaterialPageRoute(
    builder: (context) {
      return PaymentDetailsScreen(booking: booking, createBookingOnSubmit: false);
    },
  );

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  late TextEditingController _paymentReferenceNoTED;
  late TextEditingController _invoiceNoTED;
  late TextEditingController _payingNowTED;
  PaymentMode? _selectedPaymentMode;
  DateTime _paymentDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _paymentReferenceNoTED = TextEditingController(text: widget.editPayment?.referenceNo ?? '');
    _invoiceNoTED = TextEditingController(text: widget.editPayment?.invoiceNo ?? '');
    _payingNowTED = TextEditingController(
      text:
          (widget.createBookingOnSubmit)
              ? widget.initialPayingAmount.toString()
              : widget.editPayment?.amount.toString(),
    );

    _selectedPaymentMode = widget.editPayment?.paymentMode;
    _paymentDate = widget.editPayment?.createdAt ?? DateTime.now();

    super.initState();
  }

  Booking get booking => widget.booking;

  @override
  void dispose() {
    _paymentReferenceNoTED.dispose();
    _invoiceNoTED.dispose();
    _payingNowTED.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentDetailsCubit(repository: locator<BookingsRepository>()),
      child: BlocConsumer<PaymentDetailsCubit, PaymentDetailsState>(
        listener: (context, state) {
          if (state is PaymentDetailsSuccess) {
            if (widget.createBookingOnSubmit) {
              Navigator.popUntil(context, (route) => route.settings.name == 'DashboardScreen');
              // only fetch bookings if the current booking has same date as selected date
              if (booking.bookingDate.contains(context.read<BookingsCubit>().state.selectedDate.formatDDMMYYYY)) {
                context.read<BookingsCubit>().fetchBookings();
              }
            } else {
              Navigator.pop(context);
              // fetch booking in add/edit payment case for UI refresh
              context.read<BookingsCubit>().fetchBookings();
            }

            String snackBarMsg;
            if (widget.createBookingOnSubmit) {
              snackBarMsg = 'Booking Created Successfully';
            } else if (widget.editPayment != null) {
              snackBarMsg = 'Payment Updated Successfully';
            } else {
              snackBarMsg = 'Payment Added Successfully';
            }

            context.showSnackBar(snackBarMsg);
          }
          if (state is PaymentDetailsError) context.showSnackBar(state.message);
        },
        builder: (context, state) {
          return Scaffold(
            appBar: CustomAppBar(
              title: 'Payment Details',
              description: 'Payment Details Screen',
              action:
                  (widget.editPayment != null)
                      ? IconButton(
                        onPressed: () async {
                          final shouldDelete = await CustomAlertDialog.show(
                            context,
                            title: 'Are you sure ?',
                            content: 'This payment details will be deleted completely.',
                          );
                          if (shouldDelete == true && context.mounted) {
                            await context.read<PaymentDetailsCubit>().deletePayment(
                              widget.editPayment!.id!,
                            );
                          }
                        },
                        icon:
                            (state is PaymentDetailsLoading)
                                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2).size(20, 20)
                                : Icon(Icons.delete, size: 20, color: Colors.white),
                      )
                      : SizedBox(),
            ),
            bottomNavigationBar: _buildActionButton().paddingAll(20),
            body: SafeArea(
              child:
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Spacing.h20,
                        (widget.createBookingOnSubmit)
                            ? KeyValuePair(title: 'Payable Amount', value: widget.initialPayingAmount.toString())
                            : KeyValuePair(
                              title: 'Balance Amount',
                              value:
                                  (_totalWithTaxAndDiscount -
                                          widget.booking.payments!.fold(0.0, (sum, p) => sum + p.amount))
                                      .toString(),
                            ),
                        Spacing.h20,
                        KeyValuePair(
                          title: 'Select Payment Mode',
                          widget: AppDropdownButton<PaymentMode>(
                            items: PaymentMode.values,
                            initialValue: _selectedPaymentMode,
                            hintText: "",
                            validator: (value) => value == null ? 'required' : null,
                            onChanged: (payment) => _selectedPaymentMode = payment,
                            itemLabel: (payment) => payment.paymentType,
                          ),
                        ),
                        Spacing.h20,
                        KeyValuePair(
                          title: 'Payment Date',
                          widget: Row(
                            children: [
                              Text(_paymentDate.formatDDMMYYYY, style: TextStyle(fontSize: 12)),
                              Spacer(),
                              IconButton(
                                icon: Icon(Icons.calendar_today_outlined, size: 18),
                                onPressed: () async {
                                  final date = await CustomDatePicker.show(
                                    context,
                                    firstDate: DateTime.now().subtract(Duration(days: 36500)),
                                    lastDate: DateTime.now().subtract(Duration(days: 2920)),
                                    initialDate: DateTime.now().subtract(Duration(days: 3650)),
                                  );
                                  setState(() => _paymentDate = date!);
                                },
                              ),
                            ],
                          ),
                        ),
                        Spacing.h20,
                        if (!widget.createBookingOnSubmit)
                          AppTextField(
                            controller: _payingNowTED,
                            labelText: 'Paying now',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              double paying = _payingNowTED.text.toDoubleOrZero();
                              if (paying <= 0) return 'required';
                              if (paying > _totalWithTaxAndDiscount) return 'Cannot pay more than total';
                              return null;
                            },
                          ),
                        Spacing.h20,
                        AppTextField(controller: _paymentReferenceNoTED, labelText: 'Payment Reference'),
                        Spacing.h20,
                        AppTextField(controller: _invoiceNoTED, labelText: 'Receipt No / Invoice No'),
                        Spacing.h20,
                      ],
                    ),
                  ).paddingAll(20).scrollable,
            ),
          );
        },
      ),
    );
  }

  double get _totalWithTaxAndDiscount {
    return PriceCalculator.calculateTotalWithTaxAndDiscount(
      totalPrice: (booking.price! * booking.noOfPersons),
      taxPercent: booking.taxPercent!,
      discountValue: booking.discount!,
      discountType: booking.discountType!,
    );
  }

  Widget _buildActionButton() {
    return BlocSelector<PaymentDetailsCubit, PaymentDetailsState, bool>(
      selector: (state) => state is PaymentDetailsLoading,
      builder: (context, isLoading) {
        return AppButton.flat(
          text: widget.createBookingOnSubmit ? 'Create Booking' : 'Proceed',
          showLoading: isLoading,
          onTap: () async {
            if (_formKey.currentState?.validate() != true) return;

            context.read<PaymentDetailsCubit>().onSubmit(
              context,
              booking: booking,
              createBooking: widget.createBookingOnSubmit,
              bookingId: booking.id,
              payment: Payment(
                id: widget.editPayment?.id,
                createdBy: context.read<UserCubit>().state.currentUser!,
                amount: _payingNowTED.text.toDoubleOrZero(),
                paymentMode: _selectedPaymentMode!,
                invoiceNo: _invoiceNoTED.text,
                referenceNo: _paymentReferenceNoTED.text,
                createdAt: _paymentDate,
              ),
            );
          },
        );
      },
    );
  }
}
