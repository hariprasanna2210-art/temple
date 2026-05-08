import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';

import '../../../../theme.dart';
import '../../../../widgets/app_text_field.dart';
import '../../enums/discount_type.enum.dart';

class DiscountSwitchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<DiscountType> onDiscountTypeChanged;
  final ValueChanged<String> onDiscountChanged;
  final DiscountType initialDiscountType;
  final double totalAmount;

  const DiscountSwitchField({
    super.key,
    required this.controller,
    required this.onDiscountChanged,
    required this.onDiscountTypeChanged,
    required this.initialDiscountType,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: controller,
            labelText: 'Discount',
            keyboardType: TextInputType.number,
            validator: (value) {
              final discount = value?.toDoubleOrZero();
              if (discount == null || discount < 0) {
                return 'Must be ≥ 0';
              }

              final isPercent = initialDiscountType == DiscountType.percentage;
              final double maxAllowed = isPercent ? 100 : totalAmount;

              if (discount > maxAllowed) {
                return isPercent
                    ? 'Cannot exceed 100%'
                    : 'Cannot exceed ₹${totalAmount.toStringAsFixed(2)}';
              }

              return null;
            },
            onChanged: onDiscountChanged,
          ),
        ),
        Text(
          '₹',
          style: TextStyle(
            fontSize: 17,
            color: initialDiscountType != DiscountType.percentage ? skyBlueColor : Colors.grey,
          ),
        ),
        Switch(
          value: initialDiscountType == DiscountType.percentage,
          onChanged: (value) {
            final DiscountType updatedType = value ? DiscountType.percentage : DiscountType.rupees;
            onDiscountTypeChanged(updatedType);
          },
          activeThumbColor: skyBlueColor,
          inactiveThumbColor: Colors.grey,
        ),
        Text(
          '%',
          style: TextStyle(
            fontSize: 15,
            color: initialDiscountType == DiscountType.percentage ? skyBlueColor : Colors.grey,
          ),
        ),
      ],
    );
  }
}
