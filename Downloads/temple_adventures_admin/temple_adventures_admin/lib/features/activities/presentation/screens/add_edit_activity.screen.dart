import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/activities/bloc/all_activities.cubit.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_alert_dialog.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_text_field.dart';
import '../../bloc/add_edit_activity.cubit.dart';
import '../../models/activity.model.dart';
import '../../models/activity_color.model.dart';
import '../widgets/all_activity_color.modal.dart';

class AddEditActivityScreen extends StatefulWidget {
  const AddEditActivityScreen({super.key, this.activity});

  final Activity? activity;

  static MaterialPageRoute<dynamic> route({Activity? activity}) =>
      MaterialPageRoute(builder: (context) => AddEditActivityScreen(activity: activity));

  @override
  State<AddEditActivityScreen> createState() => _AddEditActivityScreenState();
}

class _AddEditActivityScreenState extends State<AddEditActivityScreen> {
  late TextEditingController _activityNameTED;
  late TextEditingController _shortActivityNameTED;
  late TextEditingController _priceTED;
  ActivityColor? _selectedColor;
  final _formKey = GlobalKey<FormState>();
  int _selectedPriority = 1;
  List<int> values = [1, 2, 3, 4, 5];

  Activity? get activity => widget.activity;
  bool get editMode => activity != null;

  @override
  void initState() {
    super.initState();
    _activityNameTED = TextEditingController(text: activity?.name);
    _shortActivityNameTED = TextEditingController(text: activity?.shortName);
    _priceTED = TextEditingController(text: activity?.price.toString());
    _selectedPriority = activity?.priority ?? 1;
    _selectedColor = activity?.color;
  }

  @override
  void dispose() {
    _activityNameTED.dispose();
    _shortActivityNameTED.dispose();
    _priceTED.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Activity',
        description: editMode ? 'Edit Activity' : 'Add Activity',
        action: (editMode) ? _buildDeleteButton().paddingOnly(right: 10) : SizedBox(),
      ),
      body: SafeArea(
        child: BlocConsumer<AddEditActivityCubit, AddEditActivityState>(
          listener: (context, state) async {
            if (state.status is AddEditActivitySuccess) {
              // Refresh AllActivitiesCubit before navigating back to ensure list is updated
              await context.read<AllActivitiesCubit>().fetchAllActivities();

              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          builder: (context, state) {
            if (state.status is AddEditActivityError) {
              return Text((state.status as AddEditActivityError).message).center;
            } else {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacing.h16,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          controller: _activityNameTED,
                          labelText: 'Activity name *',
                          validator: (value) => value == null || value.trim().isEmpty ? 'required' : null,
                        ),
                        Spacing.h16,
                        AppTextField(
                          controller: _shortActivityNameTED,
                          labelText: 'Short name *',
                          validator: (value) => value == null || value.trim().isEmpty ? 'required' : null,
                        ),
                        Spacing.h16,
                        AppTextField(
                          controller: _priceTED,
                          labelText: 'Price *',
                          isStrictNumber: true,
                          validator: (value) => value == null || value.trim().isEmpty ? 'required' : null,
                        ),
                        Spacing.h32,
                        _ColorSelector(
                          initialColor: _selectedColor,
                          onChanged: (ActivityColor color) {
                            _selectedColor = color;
                          },
                        ),
                      ],
                    ).paddingHorizontal(20),
                    Spacing.h32,
                    Text(
                      'Select Priority',
                      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
                    ).paddingHorizontal(20),
                    Slider(
                      thumbColor: skyBlueColor,
                      activeColor: lightSkyBlue,
                      value: _selectedPriority.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _selectedPriority.toString(),
                      onChanged: (double value) {
                        setState(() {
                          _selectedPriority = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Low', style: TextStyle(fontSize: 12)),
                        Text('High', style: TextStyle(fontSize: 12)),
                      ],
                    ).paddingHorizontal(20),
                  ],
                ).scrollable,
              );
            }
          },
        ),
      ),
      bottomNavigationBar: _buildActionButton().paddingAll(20),
    );
  }

  Widget _buildDeleteButton() {
    return BlocSelector<AddEditActivityCubit, AddEditActivityState, bool>(
      selector: (state) => state.status is AddEditActivityLoading,

      builder: (context, isLoading) {
        return IconButton(
          onPressed: () async {
            final shouldDelete = await CustomAlertDialog.show(
              context,
              title: 'Are you sure',
              content: 'Activity will be deleted permanently',
            );
            if (shouldDelete == true && context.mounted) {
              final updatedActivity = activity?.copyWith(isDeleted: true);
              await context.read<AddEditActivityCubit>().onSubmit(context, updatedActivity!);
            }
          },
          icon: (isLoading)
              ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2).size(20, 20)
              : Icon(Icons.delete, size: 20, color: Colors.white),
        );
      },
    );
  }

  Widget _buildActionButton() {
    return BlocSelector<AddEditActivityCubit, AddEditActivityState, bool>(
      selector: (state) => state.status is AddEditActivityLoading,
      builder: (context, isLoading) {
        return AppButton.flat(
          text: editMode ? 'Update' : 'Submit',
          showLoading: isLoading,
          onTap: () {
            if (_formKey.currentState?.validate() != true) return;
            final updatedActivity = Activity(
              id: activity?.id,
              name: _activityNameTED.text,
              shortName: _shortActivityNameTED.text,
              price: double.parse(_priceTED.text),
              color: _selectedColor!,
              priority: _selectedPriority,
            );
            context.read<AddEditActivityCubit>().onSubmit(context, updatedActivity);
          },
        );
      },
    );
  }
}

class _ColorSelector extends StatelessWidget {
  final ActivityColor? initialColor;
  final ValueChanged<ActivityColor> onChanged;

  const _ColorSelector({required this.initialColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FormField<ActivityColor>(
      initialValue: initialColor,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        return value == null ? 'Required' : null;
      },
      builder: (FormFieldState<ActivityColor> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeyValuePair(
              title: (field.value != null) ? 'Selected color *' : 'Activity Color *',
              widget: AppButton.miniFlat(
                text: (field.value != null) ? 'Change' : 'Select',
                onTap: () async {
                  final color = await AllActivityColorModal.show(context);
                  if (color == null) return;

                  field.didChange(color);
                  onChanged(color);
                },
              ).right,
            ),
            if (field.errorText != null)
              Text(
                field.errorText!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500),
              ).paddingOnly(top: 5).left,
            if (field.value != null)
              Row(
                children: [
                  Container(height: 24, width: 24, color: field.value!.color.toNormalColor()),
                  Spacing.w10,
                  Text(field.value!.name, style: TextStyle(color: Colors.black, fontSize: 14)),
                ],
              ).paddingOnly(top: 10),
          ],
        );
      },
    );
  }
}
