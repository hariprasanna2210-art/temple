import 'package:flutter/material.dart';

import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_image.dart';
import '../../../../widgets/image_picker.dart';

class PhotoPickerFormField extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String> onChanged;
  final bool isRequired;

  const PhotoPickerFormField({super.key, required this.imagePath, required this.onChanged, this.isRequired = true});

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        if (isRequired && (imagePath == null || imagePath!.isEmpty)) {
          return 'Please upload a photo';
        }
        return null;
      },
      builder:
          (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Label Row ---
              Row(
                children: [
                  const Text(
                    'Photo : ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacing.w8,
                  const Text(
                    'Upload new or replace old photo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Spacing.h20,

              // --- Image Picker Box ---
              InkWell(
                onTap: () async {
                  final picked = await ImagePickerWidget.show(context);
                  if (picked != null) {
                    onChanged(picked.path);
                    field.didChange(picked.path); //  update form field
                  }
                },
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child:
                      imagePath != null && imagePath!.isNotEmpty
                          ? AppImage(imagePath!)
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add),
                              Text('Add'),
                            ],
                          ),
                ),
              ),

              // --- Error Text ---
              if (field.errorText != null) ...[
                Spacing.h4,
                Text(
                  field.errorText!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ],
            ],
          ),
    );
  }
}
