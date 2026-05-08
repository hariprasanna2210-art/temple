import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';

import '../utils/styling/spacing_widgets.dart';
import 'app_button.dart';
import 'custom_date_range_picker.dart';
import 'key_value_pair.dart';
import '../features/bookings/presentation/widgets/custom_title.dart';

class DateRangeFormField extends StatelessWidget {
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTimeRange> onDateSelected;
  final bool isRequired;

  const DateRangeFormField({
    super.key,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.onDateSelected,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<DateTimeRange>(
      validator: (_) {
        // Only validate if field is required
        if (isRequired && (startDate == null || endDate == null)) {
          return 'Please select valid dates';
        }
        return null;
      },
      builder:
          (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValuePair(
                title: title,
                widget:
                    AppButton.miniFlat(
                      text: (startDate == null || endDate == null) ? 'Select' : 'Change',
                      onTap: () async {
                        final picked = await DateRangePickerHelper.pickDateRange(context);
                        if (picked != null) {
                          onDateSelected(picked);
                          field.didChange(picked);
                        }
                      },
                    ).right,
              ),
              if (startDate != null && endDate != null) ...[
                Spacing.h8,
                CustomTitle(
                  title: '${startDate?.formatDDMMYYYY} - ${endDate?.formatDDMMYYYY}',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ],
              if (field.errorText != null) FieldErrorText(field.errorText),
            ],
          ),
    );
  }
}

class FieldErrorText extends StatelessWidget {
  final String? error;
  const FieldErrorText(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(error!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
    );
  }
}
