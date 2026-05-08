import 'package:flutter/material.dart';

import '../../services/logging.dart';

extension BuildContextX on BuildContext {
  void closeKeyboard() {
    if (mounted) {
      FocusScope.of(this).requestFocus(FocusNode());
    } else {
      Log.w("Context is not mounted");
    }
  }

  void showSnackBar(
    String message, {
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) {
      Log.w("Context is not mounted for SnackBar");
      return;
    }
    ScaffoldMessenger.of(
      this,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }
}
