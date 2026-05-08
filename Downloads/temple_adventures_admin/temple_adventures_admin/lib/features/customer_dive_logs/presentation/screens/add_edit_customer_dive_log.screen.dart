import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/custom_title.dart';
import 'package:temple_adventures_admin/features/customer_dive_logs/models/customer_dive_log.model.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:temple_adventures_admin/widgets/app_text_field.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';
import '../../../../widgets/custom_alert_dialog.dart';
import '../../../../widgets/custom_date_time_picker.dart';
import '../../../../widgets/user_selection.modal.dart';
import '../../../bookings/models/booking.model.dart';
import '../../../bookings/models/customer.model.dart';
import '../../../user/models/user.model.dart';
import '../../bloc/add_edit_customer_dive_log.cubit.dart';

class AddEditCustomerDiveLogScreen extends StatefulWidget {
  const AddEditCustomerDiveLogScreen({
    super.key,
    required this.customerDiveLog,
    required this.customer,
    this.booking,
  });

  final CustomerDiveLog? customerDiveLog;
  final Customer customer;
  final Booking? booking;

  static MaterialPageRoute<dynamic> route({
    CustomerDiveLog? customerDiveLog,
    required Customer customer,
    Booking? booking,
  }) => MaterialPageRoute(
    builder:
        (_) => AddEditCustomerDiveLogScreen(
          customerDiveLog: customerDiveLog,
          customer: customer,
          booking: booking,
        ),
  );

  @override
  State<AddEditCustomerDiveLogScreen> createState() => _AddEditCustomerDiveLogScreenState();
}

class _AddEditCustomerDiveLogScreenState extends State<AddEditCustomerDiveLogScreen> {
  DateTime? _diveLogDateTime;
  User? _instructor;
  late TextEditingController _diveSiteTED;
  late TextEditingController _tankTypeTED;
  late TextEditingController _tankNoTED;
  late TextEditingController _bottomTimeTED;
  late TextEditingController _maxDepthTED;
  late TextEditingController _pressureTED;
  late TextEditingController _rentalEquipmentTED;
  final _formKey = GlobalKey<FormState>();

  CustomerDiveLog? get customerDiveLog => widget.customerDiveLog;
  bool get editMode => customerDiveLog != null;

  @override
  initState() {
    super.initState();
    _diveLogDateTime = customerDiveLog?.diveDate;
    _instructor = customerDiveLog?.instructor;
    _diveSiteTED = TextEditingController(text: (editMode) ? customerDiveLog?.diveSite : widget.booking?.boat?.diveSite);
    _tankTypeTED = TextEditingController(text: (editMode) ? customerDiveLog?.tankType : tankType);
    _tankNoTED = TextEditingController(text: customerDiveLog?.tankNo.toString());
    _bottomTimeTED = TextEditingController(text: customerDiveLog?.bottomTime.toString());
    _maxDepthTED = TextEditingController(text: customerDiveLog?.maxDepth.toString());
    _pressureTED = TextEditingController(text: customerDiveLog?.pressure.toString());
    _rentalEquipmentTED = TextEditingController(text: customerDiveLog?.rentalEquipment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Customer Dive Log',
        description: 'Add Dive Log',
        action: editMode ? buildDeleteActionButton() : SizedBox(),
      ),
      bottomNavigationBar: buildActionButton(),
      body: SafeArea(
        child: BlocConsumer<AddEditCustomerDiveLogCubit, AddEditCustomerDiveLogState>(
          listener: (context, state) {
            if (state.status is AddEditCustomerDiveLogSuccess) {
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            return Form(
              key: _formKey,
              child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DateTimeFormField(
                        label: 'Date & Time',
                        initialDateTime: _diveLogDateTime,
                        onChanged: (value) => setState(() => _diveLogDateTime = value),
                        validator: (value) => value == null ? 'required' : null,
                      ),
                      Spacing.h20,
                      UserSelectionFormField(
                        initialUser: _instructor,
                        validator: (user) => user == null ? 'required' : null,
                        onChanged: (user) => setState(() => _instructor = user),
                      ),
                      if (_instructor != null)
                        CustomTitle(
                          title: _instructor!.fullName,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ).paddingOnly(top: 5),
                      Spacing.h15,
                      AppTextField(
                        controller: _diveSiteTED,
                        labelText: 'Dive Site *',
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                      ),
                      Spacing.h15,
                      AppTextField(
                        controller: _tankTypeTED,
                        labelText: 'Tank Type *',
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                      ),
                      Spacing.h15,
                      AppTextField(
                        controller: _tankNoTED,
                        labelText: 'Tank No *',
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                      ),
                      Spacing.h15,
                      AppTextField(
                        controller: _bottomTimeTED,
                        labelText: 'Bottom Time *',
                        keyboardType: TextInputType.number,
                        suffixText: 'mins',
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                      ),
                      Spacing.h15,
                      AppTextField(
                        controller: _maxDepthTED,
                        labelText: 'Max Depth *',
                        suffixText: 'm',
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                      ),
                      Spacing.h15,
                      AppTextField(
                        controller: _pressureTED,
                        labelText: 'Pressure *',
                        suffixText: 'bar',
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                      ),
                      Spacing.h15,
                      AppTextField(
                        controller: _rentalEquipmentTED,
                        labelText: 'Rental Equipment',
                      ),
                      Spacing.h50,
                    ],
                  ).paddingAll(20).scrollable,
            );
          },
        ),
      ),
    );
  }

  String get tankType =>
      (widget.booking?.air ?? 0) != 0
          ? 'Air'
          : (widget.booking?.nitrox ?? 0) != 0
          ? 'Nitrox'
          : '';

  Widget buildActionButton() {
    return BlocSelector<AddEditCustomerDiveLogCubit, AddEditCustomerDiveLogState, bool>(
      selector: (state) => state.status is AddEditCustomerDiveLogLoading,
      builder: (context, isLoading) {
        return AppButton.flat(
          text: (editMode) ? 'Update' : 'Submit',
          showLoading: isLoading,
          onTap: () {
            if (!_formKey.currentState!.validate()) return;
            final updatedCustomerDiveLog = CustomerDiveLog(
              id: customerDiveLog?.id,
              customer: widget.customer,
              diveDate: _diveLogDateTime!,
              instructor: _instructor!,
              diveSite: _diveSiteTED.text.capitalizeFirst(),
              tankType: _tankTypeTED.text.capitalizeFirst(),
              tankNo: int.parse(_tankNoTED.text),
              bottomTime: int.parse(_bottomTimeTED.text),
              pressure: double.parse(_pressureTED.text),
              maxDepth: double.parse(_maxDepthTED.text),
              rentalEquipment: _rentalEquipmentTED.text.capitalizeFirst(),
            );
            context.read<AddEditCustomerDiveLogCubit>().onSubmit(context, updatedCustomerDiveLog);
          },
        ).paddingAll(20);
      },
    );
  }

  Widget buildDeleteActionButton() {
    return BlocSelector<AddEditCustomerDiveLogCubit, AddEditCustomerDiveLogState, bool>(
      selector: (state) => state.status is AddEditCustomerDiveLogLoading,
      builder: (context, isLoading) {
        return IconButton(
          onPressed: () async {
            final shouldDelete = await CustomAlertDialog.show(
              context,
              title: 'Are you sure?',
              content: 'This dive log will be deleted completely.',
            );
            if (shouldDelete == true && context.mounted) {
              await context.read<AddEditCustomerDiveLogCubit>().deleteDiveLog(context, customerDiveLog!.id!);
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

class DateTimeFormField extends StatelessWidget {
  final DateTime? initialDateTime;
  final ValueChanged<DateTime?> onChanged;
  final String label;
  final String? Function(DateTime?)? validator;

  const DateTimeFormField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialDateTime,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: initialDateTime,
      validator: validator,
      builder: (FormFieldState<DateTime> field) {
        final hasError = field.errorText != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            KeyValuePair(
              title: label,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              widget: CustomDateTimePicker(
                type: DateTimePickerType.dateTime,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                initialValue: initialDateTime?.toIso8601String(),
                onChanged: (value) {
                  final parsed = DateTime.tryParse(value);
                  field.didChange(parsed);
                  onChanged(parsed);
                },
                textStyle: const TextStyle(fontSize: 11),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: hasError ? Colors.red.shade700 : Colors.grey,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: hasError ? Colors.red.shade700 : Colors.black,
                      width: 0.8, // thinner when focused
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: hasError ? Colors.red.shade700 : Colors.grey,
                      width: 1.2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                ),
              ),
            ),
            if (hasError) ...[
              Spacing.h5,
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class UserSelectionFormField extends StatelessWidget {
  final dynamic initialUser;
  final ValueChanged<dynamic> onChanged;
  final String? Function(dynamic)? validator;

  const UserSelectionFormField({
    super.key,
    required this.onChanged,
    this.initialUser,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<dynamic>(
      validator: validator,
      initialValue: initialUser,
      builder: (FormFieldState<dynamic> field) {
        final hasError = field.errorText != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            KeyValuePair(
              title: 'Instructor',
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              widget:
                  AppButton.miniFlat(
                    text: 'select',
                    onTap: () async {
                      final user = await UserSelectionModal.selectSingle(
                        context,
                        selectedUser: field.value,
                      );
                      if (user != null) {
                        field.didChange(user);
                        onChanged(user);
                      }
                    },
                  ).right,
            ),
            if (hasError) ...[
              Spacing.h5,
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ).paddingOnly(right: 15),
            ],
          ],
        );
      },
    );
  }
}
