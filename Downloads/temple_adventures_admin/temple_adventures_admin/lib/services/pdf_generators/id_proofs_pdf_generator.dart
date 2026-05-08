import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../features/boats/models/boats.model.dart';
import '../../features/bookings/models/booking.model.dart';
import '../../features/bookings/models/customer.model.dart';
import '../../utils/extensions/date_time.extensions.dart';
import 'pdf_generator_base.dart';

class IdProofsPdfGenerator {
  static Future<File> generate({
    required List<Boat> boats,
    required Map<int, List<Booking>> bookingsByBoat,
    required DateTime selectedDate,
  }) async {
    final pdf = pw.Document();

    final image = await PdfGeneratorBase.loadCompanyLogo();

    // Collect all bookings for image preloading
    final List<Booking> allBookings = [];
    for (final bookings in bookingsByBoat.values) {
      allBookings.addAll(bookings);
    }

    // Preload and compress images
    final Map<String, pw.ImageProvider?> imageCache = {};
    for (final booking in allBookings) {
      if (booking.pax != null) {
        for (final customer in booking.pax!) {
          if (customer.idProofFront != null && customer.idProofFront!.isNotEmpty) {
            final url = customer.idProofFront!;
            if (!imageCache.containsKey(url)) {
              imageCache[url] = await _loadCompressedImageFromUrl(url);
            }
          }
          if (customer.idProofBack != null && customer.idProofBack!.isNotEmpty) {
            final url = customer.idProofBack!;
            if (!imageCache.containsKey(url)) {
              imageCache[url] = await _loadCompressedImageFromUrl(url);
            }
          }
        }
      }
    }

    bool isFirstPage = true;

    // Collect all valid bookings with their boats
    final List<({Boat boat, Booking booking})> validBookings = [];
    for (final boat in boats) {
      final bookings = bookingsByBoat[boat.id] ?? [];
      for (final booking in bookings) {
        // Only include bookings that have at least one ID proof
        final hasIdProof = (booking.pax ?? []).any((c) =>
            (c.idProofFront != null && c.idProofFront!.isNotEmpty) ||
            (c.idProofBack != null && c.idProofBack!.isNotEmpty));

        if (hasIdProof) {
          validBookings.add((boat: boat, booking: booking));
        }
      }
    }

    //  Split generation per booking (prevents TooManyPagesException)
    for (int i = 0; i < validBookings.length; i++) {
      final item = validBookings[i];
      final isLastBooking = i == validBookings.length - 1;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            if (isFirstPage) ...[
              PdfGeneratorBase.buildCompanyHeader(image),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'ID Proofs - ${selectedDate.formatDDMMYYYY}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            _buildBoatBookingSection(item.boat, item.booking, imageCache),
            // Footer only on the last booking
            if (isLastBooking) PdfGeneratorBase.buildFooter(),
          ],
        ),
      );

      isFirstPage = false;
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/id_proofs_${selectedDate.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Build a section for one booking under a boat
  static pw.Widget _buildBoatBookingSection(
      Boat boat, Booking booking, Map<String, pw.ImageProvider?> imageCache) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Boat info
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Text(
            '${boat.name} - ${boat.time.formatHHMM}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
        ),
        pw.SizedBox(height: 10),

        // Booking ID
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(
            'Booking ID: ${booking.id}',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 10),

        // Customers with ID proofs
        if (booking.pax != null)
          ...booking.pax!
              .map((customer) => _buildCustomerIdProofs(customer, imageCache))
              .whereType<pw.Widget>(),
      ],
    );
  }

  /// Build ID proof section for one customer
  static pw.Widget _buildCustomerIdProofs(Customer customer, Map<String, pw.ImageProvider?> imageCache) {
    final hasFront = customer.idProofFront != null && 
                     customer.idProofFront!.isNotEmpty && 
                     imageCache[customer.idProofFront] != null;
    final hasBack = customer.idProofBack != null && 
                    customer.idProofBack!.isNotEmpty && 
                    imageCache[customer.idProofBack] != null;

    if (!hasFront && !hasBack) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          customer.fullName,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (hasFront) ...[
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text('Front', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    _buildImageWidget(
                      customer.idProofFront,
                      imageCache[customer.idProofFront ?? ''],
                    ),
                  ],
                ),
              ),
              if (hasBack) pw.SizedBox(width: 10),
            ],
            if (hasBack)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text('Back', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    _buildImageWidget(
                      customer.idProofBack,
                      imageCache[customer.idProofBack ?? ''],
                    ),
                  ],
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Divider(),
        pw.SizedBox(height: 8),
      ],
    );
  }

  /// Build image container - returns empty widget if no image
  static pw.Widget _buildImageWidget(String? imageUrl, pw.ImageProvider? imageProvider) {
    if (imageUrl != null && imageUrl.isNotEmpty && imageProvider != null) {
      return pw.Container(
        height: 100,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Image(imageProvider, fit: pw.BoxFit.contain, width: double.infinity),
      );
    }
    // Return empty widget instead of "No Image" box
    return pw.SizedBox.shrink();
  }

  /// Load and compress image from URL
  static Future<pw.ImageProvider?> _loadCompressedImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = img.decodeImage(response.bodyBytes);
        if (decoded != null) {
          // Resize to reasonable width to save memory (e.g., 800px)
          final resized = img.copyResize(decoded, width: 800);
          final compressed = img.encodeJpg(resized, quality: 75);
          return pw.MemoryImage(compressed);
        }
      }
    } catch (_) {}
    return null;
  }
}
