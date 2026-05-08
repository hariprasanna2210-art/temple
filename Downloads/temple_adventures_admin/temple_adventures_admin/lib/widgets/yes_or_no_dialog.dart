import 'package:flutter/material.dart';

import 'app_button.dart';

class YesOrNoDialog extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? childWidget;

  const YesOrNoDialog({
    super.key,
    required this.title,
    this.content,
    this.childWidget,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? content,
    Widget? childWidget,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => YesOrNoDialog(
                title: title,
                content: content,
                childWidget: childWidget,
              ),
        ) ??
        false;
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
      actions: [
        AppButton.miniFlat(
          isSecondary: true,
          text: 'No',
          onTap: () => Navigator.pop(context, false),
        ),
        AppButton.miniFlat(
          text: 'Yes',
          onTap: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
