import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? childWidget;

  const CustomAlertDialog({
    super.key,
    required this.title,
    this.content,
    this.childWidget,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? content,
    Widget? childWidget,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CustomAlertDialog(
            title: title,
            content: content,
            childWidget: childWidget,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content:
          childWidget ??
          Text(
            content ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
      actions: <Widget>[
        AppButton.miniFlat(
          isSecondary: true,
          text: 'Cancel',
          onTap: () => Navigator.pop(context, false),
        ),
        AppButton.miniFlat(
          text: 'Okay',
          onTap: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
