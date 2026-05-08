import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class PhoneNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String? initialCountryCode;
  final ValueChanged<PhoneNumber>? onChanged;
  final String? Function(PhoneNumber?)? validator;
  final Function(Country)? onCountryChanged;
  final FocusNode? focusNode;
  final bool required;

  const PhoneNumberInput({
    super.key,
    required this.controller,
    this.initialCountryCode, // Default country (India)
    this.onChanged,
    this.validator,
    this.focusNode,
    this.required = false,
    this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      controller: controller,
      focusNode: focusNode,
      autovalidateMode: AutovalidateMode.always,
      validator: (phone) {
        if (validator != null) {
          return validator!(phone);
        }
        return null;
      },
      showCountryFlag: false,
      decoration: InputDecoration(
        labelText: 'Phone Number ${required ? '*' : ''}',
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black54),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
      ),
      initialCountryCode: initialCountryCode ?? 'IN',
      onChanged: (phone) {
        if (onChanged != null) {
          onChanged!(phone);
        }
      },
      onCountryChanged: (country) {
        if (onCountryChanged != null) {
          onCountryChanged!(country);
        }
      },
    );
  }
}
