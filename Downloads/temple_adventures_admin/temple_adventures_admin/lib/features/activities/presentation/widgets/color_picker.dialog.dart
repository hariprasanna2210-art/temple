import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPickerDialog({super.key, required this.initialColor, required this.onColorSelected});

  static Future show(
    BuildContext context, {
    required Color initialColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return ColorPickerDialog(initialColor: initialColor, onColorSelected: onColorSelected);
      },
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color tempColor;

  @override
  void initState() {
    super.initState();
    tempColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a Color'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: tempColor,
          onColorChanged: (color) {
            tempColor = color;
          },
          showLabel: false,
          enableAlpha: false,
          displayThumbColor: true,
          paletteType: PaletteType.hsvWithHue,
          pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton.miniFlat(
              onTap: () => Navigator.pop(context),
              isSecondary: true,
              text: 'Cancel',
            ),
            Spacing.w10,
            AppButton.miniFlat(
              onTap: () {
                widget.onColorSelected(tempColor);
                Navigator.pop(context);
              },
              text: 'Select',
            ),
          ],
        ),
        Spacing.h20,
      ],
    );
  }
}
