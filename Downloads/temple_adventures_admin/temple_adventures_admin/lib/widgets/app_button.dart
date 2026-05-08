import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../theme.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? buttonColor;
  final double height;
  final double width;
  final double borderRadius;
  final double fontSize;
  final bool showLoading;
  final bool isSecondary;
  final bool useSafeArea;

  const AppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.buttonColor,
    this.height = 31,
    this.width = 100,
    this.borderRadius = 20,
    this.fontSize = 12,
    this.showLoading = false,
    this.isSecondary = false,
    this.useSafeArea = false,
  });

  factory AppButton.miniFlat({
    required String text,
    required VoidCallback onTap,
    Color? buttonColor,
    bool showLoading = false,
    bool isSecondary = false,
    double width = 100,
  }) {
    return AppButton(
      text: text,
      onTap: onTap,
      buttonColor: buttonColor,
      isSecondary: isSecondary,
      showLoading: showLoading,
      width: width,
      useSafeArea: false,
    );
  }

  factory AppButton.flat({
    required String text,
    required VoidCallback onTap,
    Color? buttonColor,
    bool showLoading = false,
    bool isSecondary = false,
    bool useSafeArea = true,
    double height = 50,
    double width = 155,
  }) {
    return AppButton(
      text: text,
      onTap: onTap,
      height: height,
      width: width,
      fontSize: 16,
      showLoading: showLoading,
      isSecondary: isSecondary,
      buttonColor: buttonColor,
      borderRadius: 10,
      useSafeArea: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: showLoading ? null : onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isSecondary ? disabledGrey : buttonColor ?? Colors.black,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child:
            showLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ).center
                : Text(
                  text,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: Colors.white),
                ).paddingHorizontal(10).center,
      ),
    );

    if (!useSafeArea) return button;
    return SafeArea(child: button);
  }
}
