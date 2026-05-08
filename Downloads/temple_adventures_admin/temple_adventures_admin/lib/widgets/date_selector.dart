import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';

import '../features/bookings/presentation/widgets/custom_title.dart';
import '../utils/styling/spacing_widgets.dart';
import 'custom_date_picker.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChange;

  const DateSelector({super.key, required this.selectedDate, required this.onDateChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            onDateChange(selectedDate.subtract(const Duration(days: 1)));
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 15),
        ),
        Spacing.w5,
        CustomTitle(title: selectedDate.formatDDMMYYYY, fontWeight: FontWeight.w600, fontSize: 14),
        Spacing.w5,
        IconButton(
          onPressed: () {
            onDateChange(selectedDate.add(const Duration(days: 1)));
          },
          icon: Icon(Icons.arrow_forward_ios_rounded, size: 15),
        ),
        const Spacer(),
        IconButton(
          splashRadius: 20,
          icon: const Icon(Icons.calendar_today_outlined, size: 17),
          onPressed: () async {
            final date = await CustomDatePicker.show(context, initialDate: selectedDate);
            if (date == null || !context.mounted) return;
            onDateChange(date);
          },
        ),
      ],
    );
  }
}
