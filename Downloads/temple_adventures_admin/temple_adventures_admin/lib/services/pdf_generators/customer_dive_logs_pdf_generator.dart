import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../features/bookings/models/customer.model.dart';
import '../../features/customer_dive_logs/models/customer_dive_log.model.dart';
import '../../utils/extensions/date_time.extensions.dart';
import 'pdf_generator_base.dart';

class CustomerDiveLogsPdfGenerator {
  static Future<File> generate({
    required Customer customer,
    required List<CustomerDiveLog> diveLogs,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    final image = await PdfGeneratorBase.loadCompanyLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Company Header
            PdfGeneratorBase.buildCompanyHeader(image),

            pw.SizedBox(height: 20),

            // Customer Header
            _buildCustomerHeader(customer, diveLogs.length, startDate, endDate),

            pw.SizedBox(height: 20),

            // Dive Logs Table
            _buildDiveLogsTable(diveLogs),

            pw.SizedBox(height: 30),

            // Footer
            PdfGeneratorBase.buildFooter(),
          ];
        },
      ),
    );

    // Save PDF to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/dive_logs_${customer.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Customer header for dive logs PDF
  static pw.Widget _buildCustomerHeader(
    Customer customer,
    int totalLogs,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    String dateRangeText = 'All Dive Logs';
    if (startDate != null && endDate != null) {
      dateRangeText = '${startDate.formatDDMMYYYY} to ${endDate.formatDDMMYYYY}';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer Dive Logs',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildDiveLogInfoRow('Name', customer.fullName),
                  if (customer.email != null) _buildDiveLogInfoRow('Email', customer.email!),
                  if (customer.phoneNumber != null) _buildDiveLogInfoRow('Phone', customer.phoneNumber!),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildDiveLogInfoRow('Total Dives', '$totalLogs'),
                  _buildDiveLogInfoRow('Period', dateRangeText),
                  _buildDiveLogInfoRow('Generated', DateTime.now().formatDDMMYYYY),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper method for dive log info rows (without Expanded)
  static pw.Widget _buildDiveLogInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  /// Dive logs table
  static pw.Widget _buildDiveLogsTable(List<CustomerDiveLog> diveLogs) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(30), // #
        1: const pw.FixedColumnWidth(70), // Date
        2: const pw.FlexColumnWidth(2), // Dive Site
        3: const pw.FlexColumnWidth(1.5), // Instructor
        4: const pw.FixedColumnWidth(50), // Tank
        5: const pw.FixedColumnWidth(40), // Time
        6: const pw.FixedColumnWidth(40), // Depth
        7: const pw.FixedColumnWidth(50), // Pressure
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            PdfGeneratorBase.buildTableCell('#', isHeader: true),
            PdfGeneratorBase.buildTableCell('Date', isHeader: true),
            PdfGeneratorBase.buildTableCell('Dive Site', isHeader: true),
            PdfGeneratorBase.buildTableCell('Instructor', isHeader: true),
            PdfGeneratorBase.buildTableCell('Tank', isHeader: true),
            PdfGeneratorBase.buildTableCell('Time\n(min)', isHeader: true),
            PdfGeneratorBase.buildTableCell('Depth\n(m)', isHeader: true),
            PdfGeneratorBase.buildTableCell('Pressure\n(bar)', isHeader: true),
          ],
        ),
        // Data rows
        ...diveLogs.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final log = entry.value;
          return pw.TableRow(
            children: [
              PdfGeneratorBase.buildTableCell('$index'),
              PdfGeneratorBase.buildTableCell(log.diveDate.formatDDMMYYYY),
              PdfGeneratorBase.buildTableCell(log.diveSite),
              PdfGeneratorBase.buildTableCell(log.instructor.fullName),
              PdfGeneratorBase.buildTableCell('${log.tankType}\n#${log.tankNo}'),
              PdfGeneratorBase.buildTableCell('${log.bottomTime}'),
              PdfGeneratorBase.buildTableCell('${log.maxDepth}'),
              PdfGeneratorBase.buildTableCell('${log.pressure}'),
            ],
          );
        }),
      ],
    );
  }
}

