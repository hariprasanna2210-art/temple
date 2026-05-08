import 'package:flutter/material.dart';

import '../utils/styling/app_measurements.dart';

class KeyValuePair extends StatelessWidget {
  const KeyValuePair({
    super.key,
    required this.title,
    this.value,
    this.widget,
    this.titleStyle,
    this.valueStyle,
  });

  final String title;
  final String? value;
  final Widget? widget;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Screen.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: titleStyle ?? TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child:
                widget ??
                Text(
                  (value != null && value!.isNotEmpty) ? value! : '-',
                  style: valueStyle ?? TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600),
                ),
          ),
        ],
      ),
    );
  }
}
