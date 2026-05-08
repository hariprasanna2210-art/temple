import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../utils/constants.dart';

/// Base class with common PDF building utilities
class PdfGeneratorBase {
  /// Loads and returns the company logo image
  static Future<pw.MemoryImage> loadCompanyLogo() async {
    final imageByteData = await rootBundle.load(appLogo);
    final imageUint8List = imageByteData.buffer.asUint8List(
      imageByteData.offsetInBytes,
      imageByteData.lengthInBytes,
    );
    return pw.MemoryImage(imageUint8List);
  }

  /// Company Header with logo and contact details
  static pw.Widget buildCompanyHeader(pw.MemoryImage image) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        // Logo placeholder
        pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(30),
          ),
          child: pw.Image(image, height: 60, width: 60),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'ODESSY WATERSPORTS PVT LTD,',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '#6A, Gandhi st., Colas Nagar,',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Opposite to Indira Gandhi Stadium',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Pondicherry, India',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Contact : +91 9940219449 / 6385686600',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Footer
  static pw.Widget buildFooter() {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'For any queries,',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Contact : Temple Adventures',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Helper method for detail rows
  static pw.Widget buildDetailRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method for table cells
  static pw.Widget buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}

