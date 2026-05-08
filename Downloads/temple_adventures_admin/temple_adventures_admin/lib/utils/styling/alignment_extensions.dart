import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_measurements.dart';

extension WidgetAlignment on Widget {
  Align get left => Align(
    alignment: Alignment.centerLeft,
    child: this,
  );

  Align get right => Align(
    alignment: Alignment.centerRight,
    child: this,
  );

  Align get center => Align(
    alignment: Alignment.center,
    child: this,
  );

  Widget get centerR => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      this,
    ],
  );

  Align get bottom => Align(
    alignment: Alignment.bottomCenter,
    child: this,
  );
}

extension WidgetSizes on Widget {
  SizedBox height(double? x) => SizedBox(
    height: x,
    child: this,
  );

  SizedBox width(double x) => SizedBox(
    width: x,
    child: this,
  );

  SizedBox size(double h, double w) => SizedBox(
    height: h * 1.0,
    width: w * 1.0,
    child: this,
  );

  SingleChildScrollView get scrollableBody {
    if (Screen.isSmallDevice) {
      return scrollable;
    }
    return SizedBox(
      height: Screen.height,
      child: this,
    ).scrollable;
  }
}

extension KeyBoardOptions on Widget {
  SingleChildScrollView get scrollable => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    physics: const BouncingScrollPhysics(),
    child: this,
  );
}
