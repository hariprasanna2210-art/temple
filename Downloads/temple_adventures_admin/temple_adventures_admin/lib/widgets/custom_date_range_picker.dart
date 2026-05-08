import 'package:flutter/material.dart';

class DateRangePickerHelper {
  static Future<DateTimeRange?> pickDateRange(BuildContext context) async {
    return await showDateRangePicker(
      context: context,
      builder: (context, child) {
        return Theme(
          data: ThemeData.from(
            colorScheme: const ColorScheme.light(primary: Color(0xff376aed)),
          ),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400.0),
                child: child!,
              ),
            ],
          ),
        );
      },
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      currentDate: DateTime.now(),
    );
  }
}
