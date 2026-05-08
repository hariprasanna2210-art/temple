import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/time_slot_selector.dialog.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/tag_chip.dart';
import '../../enums/session_type.enum.dart';

class SessionSelector extends StatelessWidget {
  final String title;
  final List<DateTime> sessionDates;
  final SessionType sessionType;
  final VoidCallback onSessionChanged;

  const SessionSelector({
    super.key,
    required this.title,
    required this.sessionDates,
    required this.sessionType,
    required this.onSessionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$title session'),
            const Spacer(),
            AppButton.miniFlat(
              text: 'Select',
              onTap: () async {
                final selectedSlot = await TimeSlotSelectorDialog.show(
                  context,
                  controller: EasyDatePickerController(),
                  sessionType: sessionType,
                );

                if (selectedSlot != null && !sessionDates.contains(selectedSlot)) {
                  sessionDates.add(selectedSlot);
                  onSessionChanged();
                }
              },
            ),
          ],
        ),
        Spacing.h20,
        Wrap(
          spacing: 10,
          children:
              sessionDates.map((date) {
                return TagChip(
                  title: date.formatFullDateTime,
                  onTap: () {
                    sessionDates.remove(date);
                    onSessionChanged();
                  },
                ).paddingOnly(bottom: 10);
              }).toList(),
        ),
      ],
    );
  }
}
