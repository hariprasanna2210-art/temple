import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:temple_adventures_admin/features/user/enums/gender.enum.dart';
import '../../features/boats/models/boat_info.model.dart';
import '../../features/boats/models/boats.model.dart';
import '../../features/bookings/models/booking.model.dart';
import '../../features/bookings/models/customer.model.dart';
import '../../utils/extensions/date_time.extensions.dart';
import 'pdf_generator_base.dart';

class CoastGuardSlipPdfGenerator {
  static Future<File> generate({
    required List<Boat> boats,
    required Map<int, List<Booking>> bookingsByBoat,
    required DateTime selectedDate,
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

            pw.Center(
              child: pw.Text(
                selectedDate.formatDDMMYYYY,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            // Boat sections
            ...boats.map((boat) => _buildBoatSection(boat, bookingsByBoat[boat.id] ?? [])),

            // Footer
            PdfGeneratorBase.buildFooter(),
          ];
        },
      ),
    );

    // Save PDF to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/coast_guard_slip_${selectedDate.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Individual Boat Section
  static pw.Widget _buildBoatSection(Boat boat, List<Booking> bookings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),

        // Boat Header
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${boat.name} - ${boat.time.formatHHMM}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Dive Site: ${boat.diveSite ?? "Not specified"}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Boat No: ${boat.number ?? "N/A"}',
                style: pw.TextStyle(fontSize: 12),
              ),
              if (boat.captains?.isNotEmpty == true)
                pw.Text(
                  'Captains: ${boat.captains!.map((s) => s.name).join(", ")}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              if (boat.surfaceSupport?.isNotEmpty == true)
                pw.Text(
                  'Surface Support: ${boat.surfaceSupport!.map((s) => s.name).join(", ")}',
                  style: pw.TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),

        pw.SizedBox(height: 10),

        // Coast Guard Slip - Direct iteration through bookings
        if (bookings.isNotEmpty)
          _buildCoastGuardSlipFromBookings(
            bookings: bookings,
            boat: boat,
          ),

        pw.SizedBox(height: 20),

        // Boat Summary
        _buildBoatSummary(
          bookings: bookings,
          boat: boat,
        ),
      ],
    );
  }

  static pw.Widget _buildCoastGuardSlipFromBookings({
    required List<Booking> bookings,
    required Boat boat,
  }) {
    int slNo = 1;
    final List<pw.TableRow> rows = [];
    List<TankInfo> bookingInstructors = [];
    List<TankInfo> diveBuddies = [];

    // Header row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          PdfGeneratorBase.buildTableCell('SL.No', isHeader: true),
          PdfGeneratorBase.buildTableCell('Diver Names', isHeader: true),
          PdfGeneratorBase.buildTableCell('Gender', isHeader: true),
          PdfGeneratorBase.buildTableCell('Dive Category', isHeader: true),
          PdfGeneratorBase.buildTableCell('Country', isHeader: true),
        ],
      ),
    );

    // Iteration through bookings and their customers
    for (final booking in bookings) {
      if (booking.pax != null) {
        for (final pax in booking.pax!) {
          rows.add(
            _buildCustomerRow(
              slNo++,
              pax,
              booking.activity.shortName,
            ),
          );
        }
      }
      //  Add all instructors from booking
      if (booking.instructor != null) {
        bookingInstructors.add(booking.instructor!);
      }
      //  Add all buddies from booking
      if (booking.buddies != null && booking.buddies!.isNotEmpty) {
        diveBuddies.addAll(booking.buddies!);
      }
    }

    bookingInstructors = bookingInstructors.toSet().toList();
    diveBuddies = diveBuddies.toSet().toList();

    rows.addAll(
      bookingInstructors.map((user) => _buildStaffRow(slNo++, user, 'Instructor')),
    );
    rows.addAll(
      diveBuddies.map((user) => _buildStaffRow(slNo++, user, 'Dive Buddy')),
    );

    rows.addAll(
      boat.dsdInstructors?.map((user) => _buildStaffRow(slNo++, user, 'DSD Instructor')) ?? [],
    );

    rows.addAll(
      boat.photographers?.map((user) => _buildStaffRow(slNo++, user, 'Photo / Video')) ?? [],
    );

    rows.addAll(
      boat.internPhotographers?.map((user) => _buildStaffRow(slNo++, user, 'Intern photo / video')) ?? [],
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: const pw.FixedColumnWidth(40), // SL.No
        1: const pw.FlexColumnWidth(2), // Diver Names
        2: const pw.FixedColumnWidth(60), // Gender
        3: const pw.FixedColumnWidth(80), // Dive Category
        4: const pw.FixedColumnWidth(60), // Country
      },
      children: rows,
    );
  }

  /// Helper method to build a customer row
  static pw.TableRow _buildCustomerRow(int slNo, Customer customer, String diveCategory) {
    return pw.TableRow(
      children: [
        PdfGeneratorBase.buildTableCell('$slNo'),
        PdfGeneratorBase.buildTableCell(customer.fullName),
        PdfGeneratorBase.buildTableCell(customer.gender.label),
        PdfGeneratorBase.buildTableCell(diveCategory),
        PdfGeneratorBase.buildTableCell(customer.isoCode ?? 'IN'),
      ],
    );
  }

  /// Helper method to build a staff row
  static pw.TableRow _buildStaffRow(int slNo, TankInfo tankInfo, String diveCategory) {
    return pw.TableRow(
      children: [
        PdfGeneratorBase.buildTableCell('$slNo'),
        PdfGeneratorBase.buildTableCell(tankInfo.name),
        PdfGeneratorBase.buildTableCell('Male'),
        PdfGeneratorBase.buildTableCell(diveCategory),
        PdfGeneratorBase.buildTableCell('India'),
      ],
    );
  }

  /// Boat Summary - Direct calculation from bookings
  static pw.Widget _buildBoatSummary({
    required List<Booking> bookings,
    required Boat boat,
  }) {
    int totalCustomers = 0;
    int totalDSD = 0;
    num totalStaff = 0.0;
    List<TankInfo> bookingInstructors = [];
    List<TankInfo> diveBuddies = [];

    for (final booking in bookings) {
      totalCustomers += booking.pax?.length ?? 0;
      if (booking.isDSD) {
        totalDSD += booking.pax?.length ?? 0;
      }

      //  Add all instructors from booking
      if (booking.instructor != null) {
        bookingInstructors.add(booking.instructor!);
      }
      //  Add all buddies from booking
      if (booking.buddies != null && booking.buddies!.isNotEmpty) {
        diveBuddies.addAll(booking.buddies!);
      }
    }

    bookingInstructors = bookingInstructors.toSet().toList();
    diveBuddies = diveBuddies.toSet().toList();

    totalStaff =
        (boat.dsdInstructors?.length ?? 0) +
        (boat.photographers?.length ?? 0) +
        (boat.internPhotographers?.length ?? 0) +
        bookingInstructors.length;

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildSummaryItem('Total Customers', '$totalCustomers'),
        _buildSummaryItem('Total DSD', '$totalDSD'),
        _buildSummaryItem('DSD Instructors', '${boat.dsdInstructors?.length}'),
        _buildSummaryItem('Total Staff', '$totalStaff'),
      ],
    );
  }

  /// Summary Item
  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label :',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}
