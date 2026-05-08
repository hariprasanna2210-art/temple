import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:temple_adventures_admin/features/bookings/enums/payment_modes.enum.dart';
import 'package:temple_adventures_admin/features/bookings/models/booking.model.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/screens/add_edit_quick_booking.screen.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/screens/edit_booking.screen.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/screens/payment_details.screen.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/manage_pax.modal.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/paper_work_qr_modal.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/presentation/screens/all_customers_dive_logs.screen.dart';
import 'package:temple_adventures_admin/features/user/enums/access_levels.enum.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/access_levels.dart';
import 'package:temple_adventures_admin/utils/constants.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/app_image.dart';
import '../../../../services/pdf_generators/booking_info_pdf_generator.dart';
import '../../../../services/share.service.dart';
import '../../../../utils/phone_utils.dart';
import '../../../../utils/price_calculator.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/key_value_pair.dart';
import '../../models/customer.model.dart';
import '../../models/payment.model.dart';
import 'custom_title.dart';

class BookingDetailsCard extends StatefulWidget {
  final Booking booking;
  final DateTime? showBookingsForDateOnly;

  const BookingDetailsCard({super.key, required this.booking, this.showBookingsForDateOnly});

  @override
  State<BookingDetailsCard> createState() => _BookingDetailsCardState();
}

class _BookingDetailsCardState extends State<BookingDetailsCard> {
  bool _expanded = false;
  Booking get booking => widget.booking;
  final GlobalKey _menuKey = GlobalKey();
  List<Customer>? _updatedPaxList;

  @override
  Widget build(BuildContext context) {
    int customersRegisteredCount =
        (booking.pax ?? []).where((e) => e.paperWorkPdfPath != null && e.paperWorkPdfPath!.isNotEmpty).length;

    return Container(
      decoration: BoxDecoration(
        color: (booking.cancelBooking ?? false) ? Colors.red.shade300 : booking.activity.color.color.toNormalColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: CustomTitle(
                    title: '${booking.primaryCustomer.firstName} x ${booking.noOfPersons}',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ).paddingOnly(left: 15),
                ),
                if (booking.isQuickBooking)
                  Text('(Quick)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                if (!booking.isQuickBooking && _balance != 0) Text('💵', style: TextStyle(fontSize: 12)),
                if ((booking.pax ?? []).any((e) => e.needDoctor == true)) Text('🏥').paddingOnly(left: 10),
                if (customersRegisteredCount == booking.noOfPersons && !booking.isQuickBooking)
                  Icon(Icons.verified, size: 14, color: skyBlueColor).paddingOnly(left: 10),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded ? _buildExpandedContent(customersRegisteredCount) : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(int customersRegisteredCount) {
    final selectedDate = widget.showBookingsForDateOnly;

    // Now filter dates for selectedDate if selected date is not provided show all dates

    // Pool Times
    final poolTimes =
        booking.poolDate
            ?.where((d) => selectedDate == null || d.isSameDate(selectedDate))
            .map((d) => selectedDate == null ? d.formatFullDateTime : d.formatHHMM)
            .toList() ??
        [];

    // Dive Times
    final diveTimes =
        booking.diveDate
            ?.where((d) => selectedDate == null || d.isSameDate(selectedDate))
            .map((d) => selectedDate == null ? d.formatFullDateTime : d.formatHHMM)
            .toList() ??
        [];

    // Theory Times
    final theoryTimes =
        booking.theoryDate
            ?.where((d) => selectedDate == null || d.isSameDate(selectedDate))
            .map((d) => selectedDate == null ? d.formatFullDateTime : d.formatHHMM)
            .toList() ??
        [];

    // Sessions
    final sessions = <String>[];
    if (poolTimes.isNotEmpty) sessions.add('Pool');
    if (diveTimes.isNotEmpty) sessions.add('Dive');
    if (theoryTimes.isNotEmpty) sessions.add('Theory');

    // Times
    final allTimes = [...poolTimes, ...diveTimes, ...theoryTimes];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!booking.isQuickBooking)
              IconButton(
                onPressed: () {
                  PhoneUtils.makingPhoneCall(
                    phoneNumber: booking.primaryCustomer.phoneNumber!,
                    code: booking.primaryCustomer.countryCode!,
                  );
                },
                icon: Icon(Icons.phone, size: 14),
              ),
            AccessLevelWidget(
              accessLevel: AccessLevels.editBooking,
              child: IconButton(
                onPressed: () {
                  if (booking.isQuickBooking) {
                    Navigator.push(context, AddEditQuickBookingScreen.route(booking: booking));
                  } else {
                    Navigator.push(context, EditBookingScreen.route(booking: booking));
                  }
                },
                icon: Icon(Icons.edit, size: 14),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            if (booking.cancelBooking == true)
              KeyValuePair(title: 'Cancellation Reason', value: booking.cancellationReason),
            KeyValuePair(title: 'Booking Id', value: '${booking.id}'),
            KeyValuePair(title: 'Activity', value: booking.activity.name),
            KeyValuePair(title: 'Pax', value: '${booking.noOfPersons}'),
            if (!booking.isQuickBooking) ...[
              KeyValuePair(title: 'Total Cost', value: (_totalWithTaxAndDiscount).toString()),
              KeyValuePair(title: 'Balance', value: (_balance).toString()),
              KeyValuePair(
                title: 'Phone',
                value: '${booking.primaryCustomer.countryCode}${booking.primaryCustomer.phoneNumber}',
              ),
              KeyValuePair(title: 'Email', value: '${booking.primaryCustomer.email}'),
            ],
            KeyValuePair(title: 'Time', value: allTimes.join(', ')),
            KeyValuePair(title: 'Session', value: sessions.join(', ')),
            if (!booking.isQuickBooking) ...[
              KeyValuePair(title: 'Registered', value: '$customersRegisteredCount / ${booking.noOfPersons}'),
              KeyValuePair(title: 'Remarks', value: booking.remarks),
              Spacing.h20,
              _PaymentProgressBar(
                totalAmount: _totalWithTaxAndDiscount,
                payments: getSortedPaymentsByCreatedDate(booking.payments).map((p) => p.amount).toList(),
              ),
              Spacing.h10,
              _buildPayments(),
              if ((booking.pax ?? []).any((e) => e.needDoctor == true))
                Row(
                  children: [
                    CustomTitle(
                      title: 'Need Doctor',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    Spacing.w10,
                    Icon(Icons.medication, size: 20),
                  ],
                ).paddingOnly(top: 10),
              ...(booking.pax ?? []).map((e) {
                if (e.needDoctor != null && e.needDoctor == true) {
                  return KeyValuePair(
                    title: e.fullName,
                    titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    widget: InkWell(
                      onTap: () {
                        PhoneUtils.makingPhoneCall(
                          phoneNumber: e.phoneNumber!,
                          code: e.countryCode!,
                        );
                      },
                      child: Icon(Icons.call, size: 12).paddingAll(10),
                    ),
                  );
                } else {
                  return SizedBox();
                }
              }),
              Spacing.h10,
              if (!booking.isDSD)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppButton.miniFlat(
                      text: 'Add Log',
                      onTap: () {
                        // Use updated pax list if available, otherwise use booking.pax
                        final customers = _updatedPaxList ?? booking.pax ?? [];
                        Navigator.push(
                          context,
                          AllCustomersDiveLogsScreen.route(customers: customers, booking: booking),
                        );
                      },
                    ),
                    AppButton.miniFlat(
                      text: 'E-Learning',
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: eLearningWhatsappMessage),
                        );
                        if (mounted) {
                          context.showSnackBar('E-Learning request copied to clipboard');
                        }
                      },
                    ),
                  ],
                ).paddingOnly(bottom: 10),
            ],
            Row(
              children: [
                AppButton.miniFlat(
                  text: 'Manage Pax',
                  onTap: () async {
                    final List<Customer>? updatedPaxList = await ManagePaxModal.show(context, booking: booking);

                    if (updatedPaxList != null && context.mounted) {
                      setState(() {
                        _updatedPaxList = updatedPaxList;
                      });
                    }
                  },
                ),
                Spacer(),
                if (!booking.isQuickBooking) ...[
                  PopupMenuButton(
                    color: Colors.white,
                    icon: AppImage(
                      whatsApp,
                      height: 30,
                      width: 30,
                    ),
                    key: _menuKey,
                    itemBuilder:
                        (_) => <PopupMenuItem<String>>[
                          PopupMenuItem<String>(
                            child: const Text(
                              'Booking info',
                              style: TextStyle(fontSize: 12),
                            ),
                            onTap: () async {
                              try {
                                // Show loading indicator
                                if (mounted) {
                                  context.showSnackBar('Generating PDF and preparing to share...');
                                }

                                // Generate PDF with booking information
                                final pdfFile = await BookingInfoPdfGenerator.generate(booking);

                                // Share generally - let user choose the app
                                await ShareService.shareFile(file: pdfFile);

                                if (mounted) {
                                  context.showSnackBar('Booking information shared successfully!');
                                }
                              } catch (e) {
                                if (mounted) {
                                  context.showSnackBar('Failed to share booking info: ${e.toString()}');
                                }
                              }
                            },
                          ),
                          PopupMenuItem<String>(
                            child: const Text(
                              'Paperwork link',
                              style: TextStyle(fontSize: 12),
                            ),
                            onTap: () async {
                              try {
                                if (mounted) {
                                  context.showSnackBar('Generating paperwork link...');
                                }

                                // Generate shortened link
                                String bookingId = booking.id!.toString();
                                String bs64 = base64.encode(bookingId.codeUnits);
                                String link =
                                    'https://templeadventures.com/temple_adventures_paperwork/?bookingId=$bs64&author=dGVtcGxl';
                                var headers = {
                                  'x-api-key': 'uSirf5x9fM5iYjPuu8GXS4TVvLbt1tdg9DUe7f7N',
                                  'Content-Type': 'application/json',
                                };
                                final result = await http.post(
                                  Uri.parse('https://api.aws3.link/shorten'),
                                  body: jsonEncode({
                                    'longUrl': link,
                                    'expireHours': 48,
                                  }),
                                  headers: headers,
                                );
                                final jsonLink = jsonDecode(result.body)['shortUrl'];

                                // Prepare message
                                String message = paperworkWhatsAppMessage(jsonLink);

                                await ShareService.shareText(
                                  text: message,
                                  subject: 'Paperwork Link - ${booking.primaryCustomer.fullName}',
                                );

                                if (mounted) {
                                  context.showSnackBar('Paperwork link shared successfully!');
                                }
                              } catch (e) {
                                if (mounted) {
                                  context.showSnackBar('Failed to share paperwork link: ${e.toString()}');
                                }
                              }
                            },
                          ),
                        ],
                  ),
                  Spacing.w5,
                  AppButton.miniFlat(
                    text: 'Paperwork',
                    onTap: () {
                      String bookingId = booking.id!.toString();
                      String bs64 = base64.encode(bookingId.codeUnits);
                      PaperworkQrModal.show(
                        context,
                        paperWorkLink:
                            'https://templeadventures.com/temple_adventures_paperwork/?bookingId=$bs64&author=dGVtcGxl',
                      );
                    },
                    buttonColor: Colors.green,
                  ),
                ],
              ],
            ),
            Spacing.h20,
            CustomTitle(
              title: 'Created by :  ${booking.createdBy.fullName}',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ],
        ).paddingOnly(top: 5, bottom: 15, left: 15, right: 15),
      ],
    );
  }

  Widget _buildPayments() {
    return Column(
      children: [
        KeyValuePair(
          title: 'Edit Payments',
          titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          widget:
              (_balance != 0)
                  ? AppButton.miniFlat(
                    text: 'Add Payment',
                    onTap: () => Navigator.push(context, PaymentDetailsScreen.addPaymentRoute(booking: booking)),
                  ).right
                  : SizedBox(),
        ),
        Spacing.h15,
        ...getSortedPaymentsByCreatedDate(booking.payments).map((p) {
          return InkWell(
            onTap:
                () => Navigator.push(context, PaymentDetailsScreen.editPaymentRoute(editPayment: p, booking: booking)),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, size: 12),
                    Spacing.w10,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment  ${p.amount}  through  ${p.paymentMode.paymentType}  collected by  ${p.createdBy.firstName}',
                            style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w600),
                          ),
                          Spacing.h3,
                          Row(
                            children: [
                              if ((p.invoiceNo ?? '').isNotEmpty)
                                Text(
                                  'Invoice No : ${p.invoiceNo}',
                                  style: TextStyle(fontSize: 10, color: Colors.black),
                                ),
                              if ((p.referenceNo ?? '').isNotEmpty)
                                Text(
                                  '  /  Reference No : ${p.referenceNo}',
                                  style: TextStyle(fontSize: 10, color: Colors.black),
                                ),
                            ],
                          ),
                          Spacing.h3,
                          Text(p.createdAt.formatFullDateTime, style: TextStyle(fontSize: 10, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<Payment> getSortedPaymentsByCreatedDate(List<Payment>? payments) {
    final sorted = List<Payment>.from(payments ?? []);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Oldest to newest
    return sorted;
  }

  double get _balance {
    return _totalWithTaxAndDiscount - (booking.payments?.fold(0.0, (sum, p) => sum! + p.amount) ?? 0);
  }

  double get _totalWithTaxAndDiscount {
    return PriceCalculator.calculateTotalWithTaxAndDiscount(
      totalPrice: (booking.price! * booking.noOfPersons),
      taxPercent: booking.taxPercent!,
      discountValue: booking.discount!,
      discountType: booking.discountType!,
    );
  }

  String get eLearningWhatsappMessage {
    return """

   *E-Learning request details:* 
        
   First Name : *${booking.primaryCustomer.firstName}* 
   Last Name : *${(booking.primaryCustomer.lastName != "") ? booking.primaryCustomer.lastName : "-"}* 
   Email : *${booking.primaryCustomer.email}* 
   Date of Birth : *${DateTime.now().formatDDMMYYYY}* 
   Course Name : *${booking.activity.name}* 
   Invoice No : *${(booking.payments != null && booking.payments!.isNotEmpty) ? booking.payments?.last.invoiceNo : "-"}* 
   Phone Number : *${booking.primaryCustomer.phoneNumber}*       
   Regards: *${booking.createdBy.firstName}* 
                                        """;
  }

  String paperworkWhatsAppMessage(dynamic jsonLink) {
    return '''
*Temple Adventures - Scuba Diving Pondicherry*

Hey *${booking.primaryCustomer.fullName}*,

Thanks for choosing us, we are excited to take you scuba diving with us 😍.

we need *all the divers to complete* the *paperwork process*. Please share this link with them.

*Please complete the paperwork process* by clicking the below link: $jsonLink. This includes _Discover Scuba Diving Form, Medical Form, Liability Releases, Agency NDA and our policies_
''';
  }
}

class _PaymentProgressBar extends StatelessWidget {
  final List<double> payments;
  final double totalAmount;

  const _PaymentProgressBar({required this.payments, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    double deposits = payments.fold(0.0, (sum, p) => sum + p);
    bool isFullyPaid = deposits >= totalAmount;

    List<_CircleData> circleData = [...payments.map((p) => _CircleData(amount: p, color: Colors.black))];

    if (!isFullyPaid) {
      double balance = (totalAmount - deposits).clamp(0, totalAmount);
      circleData.add(_CircleData(amount: balance, color: Colors.red));
    }

    circleData.add(_CircleData(amount: totalAmount, color: Colors.blue, isBold: true));

    return Stack(
      children: [
        Container(height: 2, color: isFullyPaid ? Colors.green.shade400 : Colors.black).paddingOnly(top: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < circleData.length; i++)
              Column(
                mainAxisAlignment:
                    i == 0
                        ? MainAxisAlignment.start
                        : (i == circleData.length - 1)
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.center,
                crossAxisAlignment:
                    i == 0
                        ? CrossAxisAlignment.start
                        : (i == circleData.length - 1)
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.center,
                children: [_buildCircle(circleData[i].color), Spacing.h10, _buildAmountText(circleData: circleData[i])],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircle(Color color) {
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _buildAmountText({required _CircleData circleData}) {
    return Text(
      circleData.amount.round().toString(),
      style: TextStyle(
        color: circleData.color,
        fontWeight: (circleData.isBold) ? FontWeight.bold : FontWeight.normal,
        fontSize: 10,
      ),
    );
  }
}

class _CircleData {
  final double amount;
  final Color color;
  final bool isBold;

  _CircleData({required this.amount, required this.color, this.isBold = false});
}
