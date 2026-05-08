import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';

import '../../features/bookings/presentation/widgets/booking_datetime_line.dart';
import '../../features/bookings/presentation/widgets/custom_title.dart';
import 'custom_date_picker.dart';

class BookingTimelineDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChange;

  BookingTimelineDateSelector({super.key, required this.selectedDate, required this.onDateChange});

  final EasyDatePickerController controller = EasyDatePickerController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CustomTitle(title: 'Calendar'),
            const Spacer(),
            Text(selectedDate.formatDDMMYYYY),
            IconButton(
              splashRadius: 20,
              icon: const Icon(Icons.calendar_today_outlined, size: 17),
              onPressed: () async {
                final date = await CustomDatePicker.show(context, initialDate: selectedDate);
                if (date == null || !context.mounted) return;
                controller.animateToDate(date);
                onDateChange(date);
              },
            ),
          ],
        ),
        Spacing.h10,
        BookingDateTimeline(
          selectedDate: selectedDate,
          controller: controller,
          onDateChange: (newDate) {
            onDateChange(newDate);
          },
        ),
      ],
    );
  }
}
