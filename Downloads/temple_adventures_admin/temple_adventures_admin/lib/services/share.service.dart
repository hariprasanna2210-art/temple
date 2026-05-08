import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ShareService {
  /// Single file share - let user choose the app
  static Future<void> shareFile({
    required File file,
    String? subject,
    String? text,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
          subject: subject ?? 'Screenshot - ${DateTime.now().toString().split(' ')[0]}',
          text: text,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing screenshot: $e');
    }
  }

  /// Shares multiple screenshot files
  static Future<void> shareMultipleFiles(
    List<File> files, {
    String? subject,
    String? text,
  }) async {
    try {
      final List<XFile> xFiles = files.map((file) => XFile(file.path)).toList();
      await SharePlus.instance.share(
        ShareParams(
          files: xFiles,
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
          subject: subject ?? 'Screenshots - ${DateTime.now().toString().split(' ')[0]}',
          text: text,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing multiple screenshots: $e');
    }
  }

  /// Cleanup temporary files
  static Future<void> cleanupFiles(List<File> files) async {
    try {
      for (final file in files) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up files: $e');
    }
  }

  ///  share an image from URL
  static Future<void> shareImageFromUrl({
    required String imageUrl,
    String? subject,
    String? text,
  }) async {
    try {
      // Download the image to temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');

      // Download image from URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);

        // Share the image file using existing shareFile method
        await shareFile(
          file: file,
          subject: subject ?? 'Image',
          text: text,
        );
      } else {
        throw Exception('Failed to download image: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sharing image from URL: $e');
      rethrow;
    }
  }

  /// Shares text normally - let user choose the app (WhatsApp, SMS, Email, etc.)
  /// [text] is the text message to be shared
  /// [subject] is an optional subject for the share
  static Future<void> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } catch (e) {
      debugPrint('Error sharing text: $e');
      rethrow;
    }
  }
}
