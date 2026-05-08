import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';

import '../../../../widgets/custom_date_picker.dart';

class DateOfBirthSelector extends StatelessWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onChanged;

  const DateOfBirthSelector({super.key, required this.initialDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      key: ValueKey(initialDate),
      initialValue: initialDate,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => value == null ? 'Please select date of birth' : null,

      builder: (FormFieldState<DateTime> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Date of Birth * : ',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      TextSpan(
                        text: field.value?.formatDDMMYYYY ?? '',
                        style: const TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  onPressed: () async {
                    final date = await CustomDatePicker.show(
                      context,
                      firstDate: DateTime.now().subtract(const Duration(days: 36500)),
                      lastDate: DateTime.now().subtract(const Duration(days: 2920)),
                      initialDate: DateTime.now().subtract(const Duration(days: 3650)),
                    );
                    if (context.mounted) {
                      field.didChange(date);
                      onChanged(date);
                    }
                  },
                ),
              ],
            ),
            if (field.errorText != null)
              Text(
                field.errorText!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ).left,
          ],
        );
      },
    );
  }
}
