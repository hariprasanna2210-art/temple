import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Screen {
  static double get _ppi => (Platform.isAndroid || Platform.isIOS) ? 150 : 96;

  static bool isLandscape(BuildContext c) => MediaQuery.of(c).orientation == Orientation.landscape;

  //PIXELS
  static Size get size {
    Size size = PlatformDispatcher.instance.views.first.physicalSize;

    // Convert to logical pixels
    if (PlatformDispatcher.instance.views.first.devicePixelRatio != 0.0) {
      size = Size(
        size.width / PlatformDispatcher.instance.views.first.devicePixelRatio,
        size.height / PlatformDispatcher.instance.views.first.devicePixelRatio,
      );
    }
    return size;
  }

  static double get width => size.width;

  static double get height => size.height;

  static double get diagonal => sqrt((size.width * size.width) + (size.height * size.height));

  //INCHES
  static Size get inches => Size(size.width / _ppi, size.height / _ppi);

  static double get widthInches => inches.width;

  static double get heightInches => inches.height;

  static double get diagonalInches => diagonal / _ppi;

  static Future<void> setScreenOrientation() async {
    if (diagonalInches >= 7.0) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  static Future<void> allowLandScapeOrientation() async {
    if (diagonalInches < 7.0) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    }
  }

  static double smallDevicePoint = 708;

  static bool get isSmallDevice => Screen.height < smallDevicePoint;
}
