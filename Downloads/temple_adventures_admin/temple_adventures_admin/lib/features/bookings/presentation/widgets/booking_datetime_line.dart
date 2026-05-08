import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';

class BookingDateTimeline extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChange;
  final EasyDatePickerController controller;

  const BookingDateTimeline({
    super.key,
    required this.selectedDate,
    required this.onDateChange,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return EasyTheme(
      data: EasyTheme.of(context).copyWith(
        dayMiddleElementStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        currentDayMiddleElementStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      child: EasyDateTimeLinePicker(
        controller: controller,
        firstDate: DateTime(2020, 1, 1),
        lastDate: DateTime(2090, 1, 1),
        focusedDate: selectedDate,
        selectionMode: SelectionMode.autoCenter(),
        timelineOptions: const TimelineOptions(height: 90),
        daySeparatorPadding: 12,
        headerOptions: const HeaderOptions(headerType: HeaderType.none),
        itemExtent: 60.0,
        onDateChange: onDateChange,
      ),
    );
  }
}
