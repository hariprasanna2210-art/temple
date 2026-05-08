import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/add_edit_equipment_item.cubit.dart';
import 'package:temple_adventures_admin/features/equipment/widgets/add_edit_category.modal.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:temple_adventures_admin/widgets/app_text_field.dart';
import 'package:temple_adventures_admin/widgets/basic_snack_bar.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../../widgets/custom_alert_dialog.dart';
import '../../../offers/presentation/widgets/photo_picker_form_field.dart';
import '../../../user/models/user.model.dart';
import '../../bloc/all_equipment.cubit.dart';
import '../../model/equipment_category.model.dart';
import '../../model/equipment_item.model.dart';

class AddEditEquipmentItemScreen extends StatefulWidget {
  final EquipmentItem? equipmentItem;
  final List<EquipmentCategory> categories;
  final EquipmentCategory? category;

  const AddEditEquipmentItemScreen({
    super.key,
    this.equipmentItem,
    this.category,
    required this.categories,
  });

  static MaterialPageRoute<dynamic> route({
    EquipmentItem? equipmentItem,
    EquipmentCategory? category,
    required List<EquipmentCategory> categories,
  }) => MaterialPageRoute(
    builder:
        (_) => AddEditEquipmentItemScreen(
          equipmentItem: equipmentItem,
          categories: categories,
          category: category,
        ),
  );

  @override
  State<AddEditEquipmentItemScreen> createState() => _AddEditEquipmentItemScreenState();
}

class _AddEditEquipmentItemScreenState extends State<AddEditEquipmentItemScreen> {
  late TextEditingController _equipmentNameTED;
  late TextEditingController _remarksTED;
  final _formKey = GlobalKey<FormState>();
  EquipmentCategory? _selectedCategory;
  String? _selectedImage;
  User? _currentRentedPerson;

  EquipmentItem? get equipmentItem => widget.equipmentItem;

  bool get editMode => widget.equipmentItem != null;

  @override
  void initState() {
    super.initState();
    _equipmentNameTED = TextEditingController(text: equipmentItem?.equipmentName ?? '');
    _remarksTED = TextEditingController(text: equipmentItem?.remarks ?? '');
    _selectedCategory = equipmentItem?.category ?? widget.category;
    _currentRentedPerson = equipmentItem?.currentRentedPerson;
    _selectedImage = equipmentItem?.photo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: editMode ? 'Edit Equipment' : 'Add Equipment',
        description: editMode ? 'Update ${equipmentItem?.equipmentName}' : 'Add New Equipment',
        action: editMode ? buildDeleteActionButton() : SizedBox(),
      ),
      bottomNavigationBar: buildActionButton().paddingAll(20),
      body: SafeArea(
        child: BlocConsumer<AddEditEquipmentItemCubit, AddEditEquipmentItemState>(
          listener: (context, state) {
            if (state.status is AddEditEquipmentItemSuccess &&
                (state.status as AddEditEquipmentItemSuccess).shouldPop) {
              context.read<AllEquipmentCubit>().fetchCategories();
              Navigator.pop(context);
            }

            if (state.status is AddEditEquipmentItemError) {
              BasicSnackBar.show(
                context,
                message: 'Error: ${(state.status as AddEditEquipmentItemError).message}',
              );
            }
          },
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  BlocSelector<AllEquipmentCubit, AllEquipmentState, List<EquipmentCategory>>(
                    selector: (state) => state.categories,
                    builder: (context, categories) {
                      final addEditCategory = EquipmentCategory(id: -1, name: 'Add / Edit Category');
                      final dropdownItems = [...categories, addEditCategory];

                      return AppDropdownButton<EquipmentCategory>(
                        items: dropdownItems,
                        initialValue: _selectedCategory?.id == -1 ? null : _selectedCategory,
                        onChanged: (category) async {
                          if (category.id == -1) {
                            if (editMode) return;
                            _selectedCategory = null;
                            await AddEditCategoryModal.show(context);
                            if (!context.mounted) return;
                            await context.read<AllEquipmentCubit>().fetchCategories();
                            return;
                          }
                          setState(() => _selectedCategory = category);
                        },
                        hintText: 'Select Category',
                        itemLabel: (category) => category.name,
                        shouldIgnoreValue: (category) => category.id == -1,
                        itemLabelStyleBuilder:
                            (category) => category.id == -1 ? const TextStyle(color: Colors.blue, fontSize: 14) : null,
                        validator: (val) => val == null ? 'required' : null,
                      );
                    },
                  ),
                  Spacing.h20,
                  AppTextField(
                    controller: _equipmentNameTED,
                    labelText: 'Equipment Name *',
                    validator: (val) => val == null || val.isEmpty ? 'required' : null,
                  ),
                  Spacing.h20,
                  AppTextField(
                    controller: _remarksTED,
                    labelText: 'Remarks',
                  ),
                  Spacing.h20,
                  PhotoPickerFormField(
                    imagePath: _selectedImage,
                    isRequired: false,
                    onChanged: (path) => setState(() => _selectedImage = path),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildActionButton() {
    return BlocSelector<AddEditEquipmentItemCubit, AddEditEquipmentItemState, bool>(
      selector:
          (state) => state.status is AddEditEquipmentItemLoading || state.status is AddEditEquipmentItemUploadLoading,
      builder:
          (context, isLoading) => AppButton.flat(
            text: editMode ? 'Update' : 'Submit',
            showLoading: isLoading,
            onTap: () async {
              if (!_formKey.currentState!.validate()) return;

              String? photoUrl = widget.equipmentItem?.photo;
              if (_selectedImage != null) {
                photoUrl = await context.read<AddEditEquipmentItemCubit>().uploadEquipmentImage(
                  File(_selectedImage!),
                );
              }

              final newEquipment = EquipmentItem(
                id: widget.equipmentItem?.id,
                equipmentName: _equipmentNameTED.text.capitalizeFirst().trim(),
                remarks: _remarksTED.text.trim(),
                category: _selectedCategory!,
                photo: photoUrl,
                currentRentedPerson: _currentRentedPerson,
              );

              if (!context.mounted) return;
              context.read<AddEditEquipmentItemCubit>().onEquipmentItemSubmit(context, newEquipment);
            },
          ),
    );
  }

  Widget buildDeleteActionButton() {
    return BlocSelector<AddEditEquipmentItemCubit, AddEditEquipmentItemState, bool>(
      selector: (state) => state.status is AddEditEquipmentItemDeleteLoading,
      builder: (context, isLoading) {
        return IconButton(
          onPressed: () async {
            final shouldDelete = await CustomAlertDialog.show(
              context,
              title: 'Are you sure?',
              content: 'This equipment item will be deleted completely.',
            );
            if (shouldDelete == true && context.mounted) {
              await context.read<AddEditEquipmentItemCubit>().deleteEquipmentItem(
                context,
                equipmentItem!.id!,
              );
            }
          },
          icon:
              isLoading
                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2).size(20, 20)
                  : Icon(Icons.delete, size: 20, color: Colors.white),
        ).paddingOnly(right: 10);
      },
    );
  }
}
