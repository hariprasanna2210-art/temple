// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/custom_title.dart';
import 'package:temple_adventures_admin/features/checklists/bloc/all_templates.cubit.dart';
import 'package:temple_adventures_admin/features/checklists/repository/checklist.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/custom_floating_action_button.dart';

import '../../../../theme.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/custom_alert_dialog.dart';
import '../../bloc/add_edit_template.cubit.dart';
import '../../models/template.model.dart';

class AddEditTemplateScreen extends StatefulWidget {
  const AddEditTemplateScreen({super.key, this.template});

  final Template? template;

  static MaterialPageRoute<dynamic> route({Template? template}) {
    return MaterialPageRoute(
      builder:
          (_) => AddEditTemplateScreen(
            template: template,
          ),
    );
  }

  @override
  State<AddEditTemplateScreen> createState() => _AddEditTemplateScreenState();
}

class _AddEditTemplateScreenState extends State<AddEditTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleTED;
  late List<TextEditingController> checkListItems;
  late List<FocusNode> focusNodes;
  int? selectedIndex;

  Template? get template => widget.template;

  @override
  void initState() {
    super.initState();
    titleTED = TextEditingController(text: template?.title);
    final items = widget.template?.items ?? [];
    checkListItems = (items).map((item) => TextEditingController(text: item.name)).toList();
    focusNodes = List.generate((items).length, (_) => FocusNode());
  }

  @override
  void dispose() {
    titleTED.dispose();
    for (final c in checkListItems) c.dispose(); // dispose all checklist TEDs
    for (final n in focusNodes) n.dispose(); // dispose all focus nodes

    super.dispose();
  }

  void _addItem() {
    checkListItems.add(TextEditingController());
    focusNodes.add(FocusNode());
    selectedIndex = checkListItems.length - 1;
    focusNodes[selectedIndex!].requestFocus();
    setState(() {});
  }

  void _deleteItem(int index) {
    checkListItems[index].dispose();
    focusNodes[index].dispose();
    checkListItems.removeAt(index);
    focusNodes.removeAt(index);
    if (selectedIndex == index) selectedIndex = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddEditTemplateCubit(repository: locator<ChecklistRepository>()),
      child: BlocConsumer<AddEditTemplateCubit, AddEditTemplateState>(
        listener: (context, state) {
          final status = state.status;
          if (status is AddEditTemplateSuccess) {
            context.read<AllTemplatesCubit>().fetchTemplates();
            context.showSnackBar((template == null) ? 'Template Added Successfully' : 'Template Updated Successfully');
            Navigator.pop(context);
          } else if (status is AddEditTemplateError) {
            context.showSnackBar(status.message);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: CustomAppBar(
              title: template?.title ?? 'Template',
              description: (template == null) ? 'Add Template' : 'Update Template',
              action:
                  (template != null)
                      ? IconButton(
                        onPressed: () async {
                          final shouldDelete = await CustomAlertDialog.show(
                            context,
                            title: 'Are you sure?',
                            content: 'This template will be deleted completely.',
                          );
                          if (shouldDelete == true && context.mounted) {
                            await context.read<AddEditTemplateCubit>().deleteTemplate(template!.id!);
                          }
                        },
                        icon:
                            (state.status is AddEditTemplateLoading)
                                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2).size(20, 20)
                                : Icon(Icons.delete, size: 20, color: Colors.white),
                      ).paddingOnly(right: 10)
                      : SizedBox(),
            ),
            floatingActionButton: CustomFloatingActionButton(onTap: _addItem),
            bottomNavigationBar:
                (checkListItems.isNotEmpty)
                    ? AppButton.flat(
                      text: (template == null) ? 'Submit' : 'Update',
                      showLoading: state.status is AddEditTemplateLoading,
                      onTap: () async {
                        context.closeKeyboard();
                        final shouldContinue = await CustomAlertDialog.show(
                          context,
                          title: 'Please fill title before submitting the checklist',
                          childWidget: Form(
                            key: _formKey,
                            child: AppTextField(
                              controller: titleTED,
                              labelText: 'Title',
                              validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                            ),
                          ),
                        );

                        if (shouldContinue == true && context.mounted) {
                          if (!_formKey.currentState!.validate()) return;

                          final filteredItems =
                              checkListItems.where((controller) => controller.text.trim().isNotEmpty).toList();

                          final templateModel = Template(
                            id: template?.id,
                            title: titleTED.text.trim(),
                            items: List.generate(filteredItems.length, (index) {
                              return ItemModel(
                                index: index + 1,
                                name: filteredItems[index].text.trim(),
                              );
                            }),
                          );
                          context.read<AddEditTemplateCubit>().onSubmit(templateModel);
                        }
                      },
                    ).paddingAll(20)
                    : SizedBox(),
            body: SafeArea(
              child:
                  Column(
                    children: [
                      if (checkListItems.isNotEmpty)
                        const CustomTitle(
                          title: 'Keep adding items and use the delete icon to delete or tap on item to edit',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      Spacing.h20,
                      _ChecklistList(
                        checkListItems: checkListItems,
                        focusNodes: focusNodes,
                        selectedIndex: selectedIndex,
                        onSelect: (index) {
                          selectedIndex = index;
                          setState(() {});
                        },
                        onDelete: _deleteItem,
                      ),
                      Spacing.h50,
                    ],
                  ).paddingAll(20).scrollable,
            ),
          );
        },
      ),
    );
  }
}

class _ChecklistList extends StatelessWidget {
  final List<TextEditingController> checkListItems;
  final List<FocusNode> focusNodes;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onDelete;

  const _ChecklistList({
    required this.checkListItems,
    required this.focusNodes,
    required this.selectedIndex,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (checkListItems.isEmpty) {
      return SizedBox(
        height: Screen.height / 1.5,
        child:
            const Text(
              'Tap add icon to add items',
              style: TextStyle(color: Colors.black, fontSize: 14),
            ).center,
      );
    }

    return Column(
      children: List.generate(checkListItems.length, (index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: lightSkyBlue,
            border: Border.all(
              color: (selectedIndex == index) ? Colors.black : Colors.transparent,
              width: 0.1,
            ),
          ),
          width: Screen.width,
          child: TextField(
            onTap: () => onSelect(index),
            focusNode: focusNodes[index],
            controller: checkListItems[index],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(10.0),
              hintText: 'Enter text',
              hintStyle: const TextStyle(fontSize: 14),
              border: InputBorder.none,
              suffixIcon: IconButton(
                onPressed: () => onDelete(index),
                icon: const Icon(Icons.delete, color: Colors.black, size: 20),
              ),
            ),
          ),
        ).paddingOnly(bottom: 10);
      }),
    );
  }
}
