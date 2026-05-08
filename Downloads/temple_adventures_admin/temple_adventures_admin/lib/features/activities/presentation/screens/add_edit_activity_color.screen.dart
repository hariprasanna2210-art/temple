import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/color.extension.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import '../../../../utils/locator.dart';
import '../../../../widgets/app_text_field.dart';
import '../../bloc/add_edit_activity_color.cubit.dart';
import '../../models/activity_color.model.dart';
import '../../repository/activity.repository.dart';
import '../widgets/color_picker.dialog.dart';

class AddEditActivityColorScreen extends StatefulWidget {
  const AddEditActivityColorScreen({super.key, this.activityColorModel});
  final ActivityColor? activityColorModel;

  static MaterialPageRoute<dynamic> route({ActivityColor? activityColor}) => MaterialPageRoute(
    builder: (_) {
      return BlocProvider(
        create:
            (context) =>
                AddEditActivityColorCubit(repository: locator<ActivityRepository>())
                  ..updateColor(activityColor?.color.toNormalColor()),
        child: AddEditActivityColorScreen(activityColorModel: activityColor),
      );
    },
  );

  @override
  State<AddEditActivityColorScreen> createState() => _AddEditActivityColorScreenState();
}

class _AddEditActivityColorScreenState extends State<AddEditActivityColorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _colorNameTED;
  bool get editMode => widget.activityColorModel != null;

  @override
  void initState() {
    super.initState();
    _colorNameTED = TextEditingController(text: widget.activityColorModel?.name);
  }

  @override
  void dispose() {
    _colorNameTED.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddEditActivityColorCubit, AddEditActivityColorState>(
      listener: (context, state) {
        final status = state.status;
        if (status is AddEditActivityColorSuccess) {
          Navigator.pop(context);
        }
        if (status is AddEditActivityColorError) context.showSnackBar(status.message);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Activity Color',
            description: editMode ? 'Edit Activity Color' : 'Add Activity Color',
          ),
          bottomNavigationBar: AppButton.flat(
            text: editMode ? 'Update' : 'Submit',
            showLoading: state.status is AddEditActivityColorLoading,
            onTap: () {
              if (_formKey.currentState?.validate() != true) return;

              final activityColor = ActivityColor(
                id: widget.activityColorModel?.id,
                name: _colorNameTED.text.trim().capitalizeFirst(),
                color: state.selectedColor.toHex(),
              );

              context.read<AddEditActivityColorCubit>().onSubmit(context, activityColor: activityColor);
            },
          ).paddingAll(20),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Spacing.h20,
                  AppTextField(
                    controller: _colorNameTED,
                    labelText: 'Color name',
                    required: true,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                  ),
                  Spacing.h40,
                  _ColorPreviewWidget(),
                ],
              ).paddingAll(20),
            ),
          ),
        );
      },
    );
  }
}

class _ColorPreviewWidget extends StatelessWidget {
  const _ColorPreviewWidget();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddEditActivityColorCubit, AddEditActivityColorState, Color>(
      selector: (state) => state.selectedColor,
      builder: (context, selectedColor) {
        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selectedColor,
                border: Border.all(color: Colors.black26),
              ),
            ),
            Spacing.w20,
            AppButton.miniFlat(
              width: 120,
              text: 'Change Colour',
              onTap: () {
                context.closeKeyboard();
                ColorPickerDialog.show(
                  context,
                  initialColor: selectedColor,
                  onColorSelected: (color) {
                    context.read<AddEditActivityColorCubit>().updateColor(color);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
