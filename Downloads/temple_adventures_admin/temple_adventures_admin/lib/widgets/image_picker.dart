import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../utils/styling/spacing_widgets.dart';

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({super.key});

  static Future<XFile?> show(BuildContext context) async {
    return await showModalBottomSheet<XFile?>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return ImagePickerWidget();
      },
    );
  }

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker imagePicker = ImagePicker();

      final XFile? pickedFile = await imagePicker.pickImage(source: source);
      setState(() {
        if (pickedFile != null) {
          Navigator.pop(context, pickedFile);
        } else {
          Navigator.pop(context);
          if (kDebugMode) {
            print("No image selected.");
          }
        }
      });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      if (kDebugMode) {
        print('Error picking image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItem(
            icon: Icons.browse_gallery_outlined,
            title: 'Gallery',
            onTap: () {
              _pickImage(ImageSource.gallery);
            },
          ),
          Divider(color: Colors.black),
          _buildItem(
            icon: Icons.camera_alt_outlined,
            title: 'Camera',
            onTap: () {
              _pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required void Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20),
          Spacing.w20,
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ).paddingAll(20),
    );
  }
}
