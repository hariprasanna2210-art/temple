import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/services/share.service.dart';
import '../services/screenshot.service.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';

/// Capture mode for the screenshot FAB
enum ScreenshotCaptureMode {
  /// Single widget capture using a GlobalKey
  singleWidget,

  /// Custom capture function (for complex multi-step captures)
  customFunction,
}

/// A multi-purpose floating action button widget for screenshot capture and sharing
class ScreenshotCaptureFAB extends StatefulWidget {
  // Constructor for single widget capture
  const ScreenshotCaptureFAB.singleWidget({
    super.key,
    required GlobalKey captureKey,
    this.icon = Icons.share,
    this.heroTag = "screenshot_fab",
    this.onCaptureStart,
    this.onCaptureComplete,
    this.onCaptureError,
    this.text,
    this.fileName,
  }) : _captureMode = ScreenshotCaptureMode.singleWidget,
       _captureKey = captureKey,
       _customCaptureFunction = null;

  // Constructor for custom capture function
  const ScreenshotCaptureFAB.customFunction({
    super.key,
    required Future<void> Function() captureFunction,
    this.icon = Icons.camera_alt,
    this.heroTag = "screenshot_fab",
    this.onCaptureStart,
    this.onCaptureComplete,
    this.onCaptureError,
    this.text,
    this.fileName,
  }) : _captureMode = ScreenshotCaptureMode.customFunction,
       _captureKey = null,
       _customCaptureFunction = captureFunction;

  final ScreenshotCaptureMode _captureMode;
  final GlobalKey? _captureKey;
  final Future<void> Function()? _customCaptureFunction;

  /// Icon to display on the FAB
  final IconData icon;

  /// Hero tag for the FAB (required when multiple FABs exist)
  final String heroTag;

  /// Callback when capture starts
  final VoidCallback? onCaptureStart;

  /// Callback when capture completes successfully
  final VoidCallback? onCaptureComplete;

  /// Callback when capture fails
  final void Function(String error)? onCaptureError;

  /// Text content for sharing (optional)
  final String? text;

  /// Custom file name for the screenshot (optional)
  final String? fileName;

  @override
  State<ScreenshotCaptureFAB> createState() => _ScreenshotCaptureFABState();
}

class _ScreenshotCaptureFABState extends State<ScreenshotCaptureFAB> {
  bool _isCapturing = false;

  Future<void> _handleCapture() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    widget.onCaptureStart?.call();

    try {
      switch (widget._captureMode) {
        case ScreenshotCaptureMode.singleWidget:
          await _handleSingleWidgetCapture();
          break;
        case ScreenshotCaptureMode.customFunction:
          await _handleCustomFunctionCapture();
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _handleSingleWidgetCapture() async {
    try {
      // Use ScreenshotService directly with widget parameters
      final file = await ScreenshotService.captureWidget(
        widget._captureKey!,
        fileName: widget.fileName,
        pixelRatio: 3,
      );

      if (file != null) {
        await ShareService.shareFile(
          file: file,
          text: widget.text,
        );

        if (mounted) {
          context.showSnackBar('Screenshot shared successfully!');
        }
        await ShareService.cleanupFiles([file]);
        widget.onCaptureComplete?.call();
      } else {
        widget.onCaptureError?.call('Failed to capture screenshot');
      }
    } catch (e) {
      widget.onCaptureError?.call(e.toString());
    }
  }

  Future<void> _handleCustomFunctionCapture() async {
    try {
      if (mounted) {
        context.showSnackBar('Processing capture...');
      }

      await widget._customCaptureFunction!();
      widget.onCaptureComplete?.call();
    } catch (e) {
      final errorMessage = 'Error during capture: ${e.toString()}';
      if (mounted) {
        context.showSnackBar(errorMessage);
      }
      widget.onCaptureError?.call(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: widget.heroTag,
      backgroundColor: Colors.black,
      onPressed: _isCapturing ? null : _handleCapture,
      child:
          _isCapturing
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : Icon(
                widget.icon,
                color: Colors.white,
              ),
    );
  }
}
