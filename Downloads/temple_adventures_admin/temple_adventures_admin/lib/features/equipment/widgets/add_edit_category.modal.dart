import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/add_edit_equipment_item.cubit.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_text_field.dart';
import 'package:temple_adventures_admin/widgets/custom_alert_dialog.dart';
import 'package:temple_adventures_admin/widgets/modal_wrapper.dart';

import '../../../theme.dart';
import '../../../utils/styling/app_measurements.dart';
import '../../../utils/styling/spacing_widgets.dart';
import '../../../widgets/app_button.dart';
import '../bloc/all_equipment.cubit.dart';
import '../model/equipment_category.model.dart';

class AddEditCategoryModal extends StatelessWidget {
  const AddEditCategoryModal({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEditCategoryModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrapper(
      child: SafeArea(
        child: Container(
          width: Screen.width,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 30,
          ),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: lightBlueColor,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                _buildHeader(context),
                Spacing.h20,
                Expanded(
                  child: BlocSelector<AllEquipmentCubit, AllEquipmentState, List<EquipmentCategory>>(
                    selector: (state) => state.categories,
                    builder: (context, categories) {
                      return _buildCategoryList(context, categories);
                    },
                  ),
                ),
                _buildAddCategoryButton(context),
                Spacing.h40,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Manage Categories',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ).paddingOnly(top: 8),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildAddCategoryButton(BuildContext context) {
    return SafeArea(
      top: false,
      child: AppButton.flat(
        width: Screen.width,
        text: 'Add Category',
        onTap:
            () => _showCategoryDialog(
              context,
              onSave: (name) async {
                final newCategory = EquipmentCategory(name: name);
                await context.read<AddEditEquipmentItemCubit>().onCategorySubmit(
                  context,
                  newCategory,
                );
              },
            ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, List<EquipmentCategory> categories) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          title: Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, size: 20, color: Colors.black),
            onPressed:
                () => _showCategoryDialog(
                  context,
                  initialCategory: category,
                  onSave: (updatedName) async {
                    final updatedCategory = EquipmentCategory(id: category.id, name: updatedName);
                    await context.read<AddEditEquipmentItemCubit>().onCategorySubmit(context, updatedCategory);
                  },
                ),
          ),
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  void _showCategoryDialog(
    BuildContext context, {
    EquipmentCategory? initialCategory,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialCategory?.name ?? '');

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              initialCategory == null ? 'Add New Category' : 'Edit Category',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            content: AppTextField(
              controller: controller,
              labelText: 'Enter Category Name',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel', style: TextStyle(color: Colors.black)),
              ),
              if (initialCategory != null)
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(dialogContext);
                    final cubit = context.read<AddEditEquipmentItemCubit>();
                    final isDelete = await CustomAlertDialog.show(
                      dialogContext,
                      title: 'Delete Category',
                      content: 'Are you sure you want to delete ${initialCategory.name}?',
                    );

                    if (isDelete == true) {
                      if (!context.mounted) return;
                      await cubit.deleteCategory(dialogContext, initialCategory.id!);
                    }

                    if (navigator.mounted) navigator.pop();
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.black)),
                ),
              TextButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    onSave(text);
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(
                  initialCategory == null ? 'Add' : 'Save',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }
}
