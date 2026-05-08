import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/bookings/bloc/booking_details.cubit.dart';
import 'package:temple_adventures_admin/features/bookings/enums/discount_type.enum.dart';
import 'package:temple_adventures_admin/features/bookings/models/booking.model.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/screens/payment_details.screen.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';

import '../../../../utils/price_calculator.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../activities/models/activity.model.dart';
import '../../bloc/bookings.cubit.dart';
import '../widgets/discount_switch_field.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key, required this.booking, required this.activity});

  final Booking booking;
  final Activity activity;

  static MaterialPageRoute<dynamic> route({required Booking booking, required Activity activity}) {
    return MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: booking, activity: activity));
  }

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late final TextEditingController _priceTED, _discountTED, _payingNowTED, _remarksTED, _noOfPersonsTED;
  DiscountType discountType = DiscountType.percentage;
  bool isTaxApplied = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _priceTED = TextEditingController(text: widget.activity.price.toString());
    _noOfPersonsTED = TextEditingController(text: widget.booking.noOfPersons.toString());
    _discountTED = TextEditingController();
    _payingNowTED = TextEditingController();
    _remarksTED = TextEditingController();
  }

  Booking get booking => widget.booking;

  @override
  void dispose() {
    _priceTED.dispose();
    _discountTED.dispose();
    _payingNowTED.dispose();
    _remarksTED.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              BookingDetailsCubit(repository: locator<BookingsRepository>(), logRepository: locator<LogsRepository>()),
      child: BlocConsumer<BookingDetailsCubit, BookingDetailsState>(
        listener: (context, state) {
          final status = state.status;
          if (status is BookingDetailsSuccess) {
            Navigator.popUntil(context, (route) => route.settings.name == 'DashboardScreen');
            // only fetch bookings if the current booking has same date as selected date
            if (booking.bookingDate.contains(context.read<BookingsCubit>().state.selectedDate.formatDDMMYYYY)) {
              context.read<BookingsCubit>().fetchBookings();
            }
            context.showSnackBar('Booking Created Successfully');
          }
          if (status is BookingDetailsError) {
            context.showSnackBar(status.message);
          }
        },
        builder: (context, state) {
          return Scaffold(
            bottomNavigationBar: AppButton.flat(
              text: (_payingNowTED.text.isEmpty) ? 'Create Booking' : 'Continue',
              showLoading: state.status is BookingDetailsLoading,
              onTap: () {
                if (_formKey.currentState?.validate() != true) return;

                final newBooking = widget.booking.copyWith(
                  noOfPersons: int.parse(_noOfPersonsTED.text),
                  price: _priceTED.text.toDoubleOrZero(),
                  discount: _discountTED.text.toDoubleOrZero(),
                  discountType: discountType,
                  taxPercent: isTaxApplied ? 18 : 0,
                  remarks: _remarksTED.text,
                );

                if (_payingNowTED.text.isEmpty) {
                  context.read<BookingDetailsCubit>().addBooking(newBooking);
                } else {
                  Navigator.push(
                    context,
                    PaymentDetailsScreen.route(
                      booking: newBooking,
                      initialPayingAmount: _payingNowTED.text.toDoubleOrZero(),
                    ),
                  );
                }
              },
            ).paddingAll(20),
            appBar: CustomAppBar(title: 'Booking Details', description: ''),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child:
                    Column(
                      children: [
                        Spacing.h10,
                        AppTextField(
                          controller: _noOfPersonsTED,
                          labelText: 'No of persons',
                          required: true,
                          isStrictNumber: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'required';
                            return null;
                          },
                          onChanged: (_) {
                            setState(() {
                              // Rebuild to update total price
                            });
                          },
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
                          initialDiscountType: discountType,
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
                        AppTextField(
                          controller: _payingNowTED,
                          labelText: 'Paying Now',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final paying = value?.toDoubleOrZero();
                            if (paying! < 0) return 'Must be ≥ 0';
                            if (paying > totalWithTaxAndDiscount) return 'Cannot pay more than total';
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              // Rebuild to update balance
                            });
                          },
                        ),
                        Spacing.h20,
                        AppTextField(
                          labelText: 'Remarks',
                          controller: _remarksTED,
                          required: false,
                          maxLines: 3,
                        ),
                        Spacing.h40,
                        KeyValuePair(title: 'Price', value: totalPrice.toStringAsFixed(2)),
                        Spacing.h10,
                        KeyValuePair(title: 'Discount', value: discountAmount.toStringAsFixed(2)),
                        Spacing.h10,
                        KeyValuePair(title: 'Total Amount', value: totalWithTaxAndDiscount.toStringAsFixed(2)),
                        Spacing.h10,
                        KeyValuePair(title: 'Balance', value: balance.toStringAsFixed(2)),
                      ],
                    ).paddingAll(20).scrollable,
              ),
            ),
          );
        },
      ),
    );
  }

  double get totalPrice => _priceTED.text.toDoubleOrZero() * _noOfPersonsTED.text.toDoubleOrZero();
  double get discountAmount => PriceCalculator.calculateDiscount(
    totalPrice: totalPrice,
    discountValue: _discountTED.text.toDoubleOrZero(),
    discountType: discountType,
  );
  double get totalWithTaxAndDiscount => PriceCalculator.calculateTotalWithTaxAndDiscount(
    totalPrice: totalPrice,
    taxPercent: isTaxApplied ? 18 : 0,
    discountValue: _discountTED.text.toDoubleOrZero(),
    discountType: discountType,
  );
  double get balance =>
      (totalWithTaxAndDiscount - _payingNowTED.text.toDoubleOrZero()).clamp(0, totalWithTaxAndDiscount);
}
