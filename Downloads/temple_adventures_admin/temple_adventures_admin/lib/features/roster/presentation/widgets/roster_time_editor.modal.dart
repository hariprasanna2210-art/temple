import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/custom_time_picker.dart';
import '../../../../widgets/modal_wrapper.dart';

class RoasterTimeEditorModal extends StatefulWidget {
  const RoasterTimeEditorModal({
    super.key,
    this.selectedTimeIn,
    this.selectedTmeOut,
  });

  final TimeOfDay? selectedTimeIn;
  final TimeOfDay? selectedTmeOut;

  static Future<List<TimeOfDay?>> show(
    BuildContext context,
    TimeOfDay? selectedTmeIn,
    TimeOfDay? selectedTmeOut,
  ) async {
    final List<TimeOfDay?>? data = await showModalBottomSheet<List<TimeOfDay?>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return RoasterTimeEditorModal(
          selectedTimeIn: selectedTmeIn,
          selectedTmeOut: selectedTmeOut,
        );
      },
    );
    return data ?? <TimeOfDay?>[];
  }

  @override
  State<RoasterTimeEditorModal> createState() => _RoasterTimeEditorModalState();
}

class _RoasterTimeEditorModalState extends State<RoasterTimeEditorModal> {
  TimeOfDay? timeIn;
  TimeOfDay? timeOut;

  @override
  void initState() {
    timeIn = widget.selectedTimeIn;
    timeOut = widget.selectedTmeOut;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrapper(
      child: SafeArea(
        child: Container(
          width: Screen.width,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              topLeft: Radius.circular(16),
            ),
            color: lightBlueColor,
          ),
          child:
              Column(
                children: [
                  ModalHeader(
                    title: 'Change Times',
                    onClose: () => Navigator.pop(context, <TimeOfDay?>[]),
                  ),
                  Spacing.h30,
                  if (timeIn != null)
                    TimeSelector(
                      time: timeIn!,
                      title: 'Time In',
                      onTap: () => selectTimeIn(context),
                    ),
                  Spacing.h20,
                  if (timeOut != null)
                    TimeSelector(
                      time: timeOut!,
                      title: 'Time Out',
                      onTap: () => selectTimeOut(context),
                    ),
                  Spacing.h30,
                  AppButton.miniFlat(
                    text: 'Reset',
                    onTap: () {
                      timeIn = null;
                      timeOut = null;
                      if (context.mounted) {
                        Navigator.pop(context, <TimeOfDay?>[timeIn, timeOut]);
                      }
                    },
                  ).left,
                  Spacing.h100,
                  AppButton.flat(
                    width: Screen.width,
                    text: 'Okay',
                    onTap: () async {
                      if (context.mounted) {
                        Navigator.pop(context, <TimeOfDay?>[timeIn, timeOut]);
                      }
                    },
                  ),
                ],
              ).paddingSymmetric(horizontal: 20).scrollable,
        ).paddingOnly(bottom: MediaQuery.of(context).viewInsets.bottom),
      ),
    );
  }

  Future<void> selectTimeIn(
    BuildContext context,
  ) async {
    final TimeOfDay? pickedTime = await TimePicker.showOnlyTime(
      context,
      initialTime: timeIn!,
    );

    if (pickedTime != null) {
      setState(() {
        timeIn = pickedTime;
      });
    }
  }

  Future<void> selectTimeOut(
    BuildContext context,
  ) async {
    final TimeOfDay? pickedTime = await TimePicker.showOnlyTime(
      context,
      initialTime: timeOut!,
    );

    if (pickedTime != null) {
      setState(() {
        timeOut = pickedTime;
      });
    }
  }
}

class TimeSelector extends StatelessWidget {
  final String title;
  final TimeOfDay time;
  final VoidCallback onTap;

  const TimeSelector({
    super.key,
    required this.title,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 30,
            width: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                time.formatTimeOfDay,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ModalHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const ModalHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ).paddingOnly(top: 8),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }
}
