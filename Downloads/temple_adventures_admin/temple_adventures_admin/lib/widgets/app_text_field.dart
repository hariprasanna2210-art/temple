import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/styling/app_measurements.dart';

class AppTextField extends StatefulWidget {
  final int? maxLimit;
  final int? minLines;
  final int? maxLines;
  final Widget? icon;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? width;
  final String? suffixText;
  final bool required;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final VoidCallback? onFinalSubmit;
  final String? labelText;
  final String? hintText;
  final bool isStrictNumber;
  final InputBorder? border;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.maxLimit,
    this.isStrictNumber = false,
    this.labelText,
    this.suffixText,
    this.minLines,
    this.maxLines,
    this.icon,
    required this.controller,
    this.focusNode,
    this.onFinalSubmit,
    this.validator,
    this.onChanged,
    this.width,
    this.suffixIcon,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.hintText,
    this.border,
    this.prefixIcon,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? Screen.width,
      child: TextFormField(
        style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Colors.black),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        cursorColor: Colors.black,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        controller: widget.controller,
        focusNode: widget.focusNode,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: widget.isStrictNumber ? TextInputType.number : widget.keyboardType,
        inputFormatters: widget.isStrictNumber ? [FilteringTextInputFormatter.digitsOnly] : widget.inputFormatters,
        decoration: InputDecoration(
          labelText: (widget.labelText) != null ? "${widget.labelText} ${(widget.required) ? '*' : ''}" : '',
          suffixText: widget.suffixText,
          suffixIcon: widget.suffixIcon,
          icon: widget.icon,
          prefixIcon: widget.prefixIcon,
          hintText: widget.hintText,
          labelStyle: const TextStyle(fontSize: 12, color: Colors.black54),
          enabledBorder:
              (widget.border == null)
                  ? const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))
                  : widget.border,
          focusedBorder:
              (widget.border == null)
                  ? const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black))
                  : widget.border,
        ),
        validator: widget.validator,
        onChanged: (value) {
          widget.onChanged?.call(value);
        },
        onFieldSubmitted: (value) {
          if (widget.onFinalSubmit != null) {
            widget.onFinalSubmit!();
          }
        },
      ),
    );
  }
}
