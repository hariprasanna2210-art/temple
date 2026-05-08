import 'package:flutter/material.dart';

extension ColorToHexExtension on Color {
  String toHex({bool includeAlpha = false}) {
    return '#'
            '${includeAlpha ? alpha.toRadixString(16).padLeft(2, '0') : ''}'
            '${red.toRadixString(16).padLeft(2, '0')}'
            '${green.toRadixString(16).padLeft(2, '0')}'
            '${blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}
