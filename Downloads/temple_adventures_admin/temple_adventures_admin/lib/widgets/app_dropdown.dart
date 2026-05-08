import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

class AppDropdownButton<T> extends StatelessWidget {
  final List<T> items;
  final T? initialValue;
  final ValueChanged<T>? onChanged;
  final String? Function(T?)? validator;
  final FocusNode? focusNode;
  final String hintText;
  final bool isExpanded;
  final String Function(T) itemLabel;
  final bool Function(T)? shouldIgnoreValue;
  final TextStyle? Function(T)? itemLabelStyleBuilder;

  const AppDropdownButton({
    super.key,
    required this.items,
    required this.initialValue,
    required this.onChanged,
    required this.hintText,
    required this.itemLabel,
    this.validator,
    this.focusNode,
    this.isExpanded = true,
    this.shouldIgnoreValue,
    this.itemLabelStyleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: ValueKey(initialValue),
      initialValue: initialValue,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      builder: (FormFieldState<T> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<T>(
              isExpanded: isExpanded,
              focusNode: focusNode,
              value: field.value,
              hint: Text(
                hintText,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ).paddingOnly(bottom: 20),
              underline: Container(
                height: 1,
                color: field.hasError ? Colors.red.shade700 : Colors.grey,
              ),
              onChanged: (T? newValue) {
                if (newValue != null) {
                  if (shouldIgnoreValue?.call(newValue) == true) {
                    onChanged?.call(newValue);
                    return;
                  }
                  field.didChange(newValue);
                  onChanged?.call(newValue);
                }
              },
              items:
                  items.map(
                    (item) {
                      final style =
                          itemLabelStyleBuilder?.call(item) ?? const TextStyle(color: Colors.black, fontSize: 14);
                      return DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          itemLabel(item),
                          style: style,
                        ),
                      );
                    },
                  ).toList(),
            ),
            if (field.hasError)
              Text(
                field.errorText ?? '',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ).paddingOnly(top: 2),
          ],
        );
      },
    );
  }
}
