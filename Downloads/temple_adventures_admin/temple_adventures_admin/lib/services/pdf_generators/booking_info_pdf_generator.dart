import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:temple_adventures_admin/features/bookings/enums/payment_modes.enum.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import '../../features/bookings/models/booking.model.dart';
import '../../features/bookings/models/payment.model.dart';
import '../../utils/price_calculator.dart';
import 'pdf_generator_base.dart';

class BookingInfoPdfGenerator {
  static Future<File> generate(Booking booking) async {
    final pdf = pw.Document();

    // Calculate totals
    final totalWithTaxAndDiscount = PriceCalculator.calculateTotalWithTaxAndDiscount(
      totalPrice: (booking.price! * booking.noOfPersons),
      taxPercent: booking.taxPercent!,
      discountValue: booking.discount!,
      discountType: booking.discountType!,
    );

    final totalPaid = booking.payments?.fold(0.0, (sum, p) => sum + p.amount) ?? 0;
    final balance = (totalWithTaxAndDiscount - totalPaid);

    // Get sorted payments
    final sortedPayments = List<Payment>.from(booking.payments ?? []);
    sortedPayments.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final image = await PdfGeneratorBase.loadCompanyLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Company Header
            PdfGeneratorBase.buildCompanyHeader(image),

            pw.SizedBox(height: 30),

            // Customer Name and Activity
            _buildCustomerHeader(booking),

            pw.SizedBox(height: 30),

            // Booking Details Section
            _buildBookingDetailsSection(booking),

            pw.SizedBox(height: 20),

            // Note Section
            _buildNoteSection(),

            pw.SizedBox(height: 30),

            // Payment Details Section
            ...[
              _buildPaymentDetailsSection(booking, totalWithTaxAndDiscount, totalPaid, balance),
              pw.SizedBox(height: 30),
            ],

            // All Transactions Section
            if (sortedPayments.isNotEmpty) ...[
              _buildTransactionsSection(sortedPayments),
              pw.SizedBox(height: 30),
            ],

            // Footer
            PdfGeneratorBase.buildFooter(),
          ];
        },
      ),
    );

    // Save PDF to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/booking_${booking.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Customer name and activity display
  static pw.Widget _buildCustomerHeader(Booking booking) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            "${booking.primaryCustomer.firstName}${booking.primaryCustomer.lastName != null ? ' ${booking.primaryCustomer.lastName}' : ''}'s",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            booking.activity.name,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  // Note Section
  static pw.Widget _buildNoteSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Note :',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Thank you for considering Temple Adventures for your scuba diving experience. We are pleased to offer a variety of dive plans to accommodate your needs and preferences. Our team is dedicated to providing a safe and enjoyable diving experience, and sometimes we have to negotiate the time of your dive based on the availability of our boats. We understand that flexibility is important, and we strive to accommodate your schedule to the best of our ability. Please let us know if you have any specific requests, and we will do our best to accommodate them.',
          style: const pw.TextStyle(
            fontSize: 10,
            height: 1.4,
          ),
          textAlign: pw.TextAlign.justify,
        ),
      ],
    );
  }

  // Booking Details Section
  static pw.Widget _buildBookingDetailsSection(Booking booking) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Booking Details',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          child: pw.Column(
            children: [
              PdfGeneratorBase.buildDetailRow('Booking ID', '${booking.id}'),
              PdfGeneratorBase.buildDetailRow(
                'Name',
                '${booking.primaryCustomer.firstName} ${booking.primaryCustomer.lastName ?? ''}',
              ),
              PdfGeneratorBase.buildDetailRow('Pax', '${booking.noOfPersons}'),
              if (!booking.isQuickBooking && booking.primaryCustomer.email != null)
                PdfGeneratorBase.buildDetailRow('Email ID', booking.primaryCustomer.email!),
              PdfGeneratorBase.buildDetailRow('Activity', booking.activity.name),

              // Dive Dates
              if (booking.diveDate?.isNotEmpty == true)
                PdfGeneratorBase.buildDetailRow(
                  'Dive Dates',
                  booking.diveDate!.map((date) => date.formatDDMMYYYY).join(', '),
                ),

              // Theory Dates
              if (booking.theoryDate?.isNotEmpty == true)
                PdfGeneratorBase.buildDetailRow(
                  'Theory Dates',
                  booking.theoryDate!.map((date) => date.formatDDMMYYYY).join(', '),
                )
              else
                PdfGeneratorBase.buildDetailRow('Theory Dates', ''),

              // Pool Dates with time
              if (booking.poolDate?.isNotEmpty == true)
                PdfGeneratorBase.buildDetailRow(
                  'Pool Dates',
                  booking.poolDate!.map((date) => date.formatFullDateTime).join(', '),
                )
              else
                PdfGeneratorBase.buildDetailRow('Pool Dates', ''),

              if (booking.cancelBooking == true) ...[
                PdfGeneratorBase.buildDetailRow('Status', 'CANCELLED'),
                if (booking.cancellationReason?.isNotEmpty == true)
                  PdfGeneratorBase.buildDetailRow('Cancellation Reason', booking.cancellationReason!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Payment Details Section
  static pw.Widget _buildPaymentDetailsSection(
    Booking booking,
    double totalAmount,
    double totalPaid,
    double balance,
  ) {
    final firstPayment = booking.payments?.isNotEmpty == true ? booking.payments!.first : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Payment Details',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(15),
          child: pw.Column(
            children: [
              PdfGeneratorBase.buildDetailRow('Total Amount', '${totalAmount.toInt()} /-'),
              PdfGeneratorBase.buildDetailRow('Deposit', '${totalPaid.toInt()} /-'),
              PdfGeneratorBase.buildDetailRow('Balance', '${balance.toInt()} /-'),
              if (firstPayment?.invoiceNo?.isNotEmpty == true)
                PdfGeneratorBase.buildDetailRow('Receipt No', firstPayment!.invoiceNo!),
              if (firstPayment != null)
                PdfGeneratorBase.buildDetailRow('Payment Mode', firstPayment.paymentMode.paymentType),
              if (firstPayment?.referenceNo?.isNotEmpty == true)
                PdfGeneratorBase.buildDetailRow('Transaction ID', firstPayment!.referenceNo!),
            ],
          ),
        ),
      ],
    );
  }

  // All Transactions Section
  static pw.Widget _buildTransactionsSection(List<Payment> payments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'All Transactions',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 10),
        ...payments.map(
          (payment) => pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Payment ${payment.amount.toInt()} by ${payment.paymentMode.paymentType} collected by ${payment.createdBy.firstName}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  payment.createdAt.formatFullDateTime,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
