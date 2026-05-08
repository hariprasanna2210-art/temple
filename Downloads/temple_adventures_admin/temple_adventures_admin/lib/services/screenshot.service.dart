import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class ScreenshotService {
  /// Captures a screenshot of the widget with the given key
  static Future<File?> captureWidget(
    GlobalKey key, {
    String? fileName,
    double pixelRatio = 3.0,
  }) async {
    try {
      // Wait for rendering to complete
      await WidgetsBinding.instance.endOfFrame;

      final RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('Render boundary is null. Widget may not be rendered yet.');
        return null;
      }

      // Try capturing with specified pixel ratio, fallback to lower if OOM
      ui.Image? image;
      try {
        image = await boundary.toImage(pixelRatio: pixelRatio);
      } catch (e) {
        if (e.toString().contains('OutOfMemoryError') || pixelRatio > 1.5) {
          debugPrint('Capture failed at ${pixelRatio}x. Retrying with lower pixel ratio...');
          try {
            image = await boundary.toImage(pixelRatio: pixelRatio * 0.7);
          } catch (e2) {
            debugPrint('Capture failed at reduced ratio. Trying 1.0x...');
            image = await boundary.toImage(pixelRatio: 1.0);
          }
        } else {
          rethrow;
        }
      }

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('Failed to convert image to byte data.');
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final name = fileName ?? 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$name');

      await file.writeAsBytes(pngBytes);

      // Add haptic feedback on successful capture
      HapticFeedback.mediumImpact();

      return file;
    } catch (e, stackTrace) {
      debugPrint('Error capturing screenshot: $e\n$stackTrace');
      return null;
    }
  }
}
