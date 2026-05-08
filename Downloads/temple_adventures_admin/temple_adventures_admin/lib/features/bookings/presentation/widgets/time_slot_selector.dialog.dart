import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../theme.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../enums/session_type.enum.dart';
import '../../services/time_generator.dart';
import 'booking_datetime_line.dart';

class TimeSlotSelectorDialog extends StatefulWidget {
  final EasyDatePickerController controller;
  final SessionType sessionType;
  final bool showDetails;

  const TimeSlotSelectorDialog({
    super.key,
    required this.controller,
    required this.sessionType,
    this.showDetails = false,
  });

  static Future<DateTime?> show(BuildContext context, {
    required EasyDatePickerController controller,
    required SessionType sessionType,
    bool showDetails = false,
  }) async {
    var data = await showDialog(
      context: context,
      builder: (context) {
        return TimeSlotSelectorDialog(
          controller: controller,
          sessionType: sessionType,
          showDetails: showDetails,
        );
      },
    );
    return data as DateTime?;
  }

  @override
  State<TimeSlotSelectorDialog> createState() => _TimeSlotSelectorDialogState();
}

class _TimeSlotSelectorDialogState extends State<TimeSlotSelectorDialog> {
  late DateTime _selectedDate;
  DateTime? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  List<DateTime> get _currentDaySlots {
    return TimeGenerator.generateTimeTable(
      selectedDate: _selectedDate,
      sessionType: widget.sessionType,
      showDetails: widget.showDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Select time slot',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: Screen.height * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date timeline
            BookingDateTimeline(
              selectedDate: _selectedDate,
              controller: widget.controller,
              onDateChange: (newDate) {
                setState(() {
                  _selectedDate = newDate;
                  _selectedSlot = null;
                });
              },
            ),
            Spacing.h20,

            // Time slots
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _currentDaySlots.map((slot) {
                    final isSelected = _selectedSlot == slot;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSlot = slot;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? skyBlueColor : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(slot.formatHHMM, style: const TextStyle(fontSize: 10)).paddingAll(8),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        AppButton.miniFlat(
          isSecondary: true,
          text: 'Cancel',
          onTap: () => Navigator.pop(context, null),
        ),
        AppButton.miniFlat(
          text: 'Okay',
          onTap: () async => Navigator.pop(context, _selectedSlot),
        ),
      ],
    );
  }
}
