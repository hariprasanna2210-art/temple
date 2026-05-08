import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/user/bloc/user.cubit.dart';
import 'package:temple_adventures_admin/widgets/app_text_field.dart';
import 'package:temple_adventures_admin/widgets/basic_snack_bar.dart';
import 'package:temple_adventures_admin/widgets/custom_date_time_picker.dart';

import '../../../utils/styling/spacing_widgets.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/key_value_pair.dart';
import '../../../widgets/user_selection.modal.dart';
import '../../user/models/user.model.dart';
import '../bloc/add_edit_event.cubit.dart';
import '../models/event.model.dart';

const TextStyle _keyValuePairStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
);

class AddEditEventModal extends StatefulWidget {
  final EventModel? events;

  const AddEditEventModal({super.key, this.events});

  static Future<EventModel?> show(BuildContext context, {EventModel? event}) {
    return showModalBottomSheet<EventModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditEventModal(events: event),
    );
  }

  @override
  State<AddEditEventModal> createState() => _AddEditEventModalState();
}

class _AddEditEventModalState extends State<AddEditEventModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _sessionNameTED;
  late TextEditingController _locationTED;

  EventModel? get events => widget.events;

  bool get editEvent => events != null;
  DateTime? _eventDateTime;
  User? _contactPerson;

  @override
  void initState() {
    super.initState();
    _sessionNameTED = TextEditingController(text: events?.sessionName);
    _locationTED = TextEditingController(text: events?.location);
    _eventDateTime = events?.eventDateTime ?? DateTime.now();
    _contactPerson = events?.contactPerson;
  }

  @override
  void dispose() {
    _sessionNameTED.dispose();
    _locationTED.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddEditEventCubit, AddEditEventState>(
      listener: (context, state) {
        if (state.status is AddEditEventSuccess) {
          Navigator.of(context).pop((state.status as AddEditEventSuccess).updatedEvent);
          return;
        }
        if (state.status is AddEditEventError) {
          BasicSnackBar.show(context, message: 'Error occured: ${(state.status as AddEditEventError).message}');
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    editEvent ? 'Edit Event' : 'Add Event',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Spacing.h20,
              KeyValuePair(
                title: 'Session Name',
                titleStyle: _keyValuePairStyle,
                widget: AppTextField(
                  controller: _sessionNameTED,
                  validator: (val) => val == null || val.isEmpty ? "required" : null,
                ),
              ),
              Spacing.h20,
              KeyValuePair(
                title: 'Location',
                titleStyle: _keyValuePairStyle,
                widget: AppTextField(
                  controller: _locationTED,
                  validator: (val) => val == null || val.trim().isEmpty ? "required" : null,
                ),
              ),
              Spacing.h40,
              KeyValuePair(
                title: 'Date & Time',
                titleStyle: _keyValuePairStyle,
                widget: CustomDateTimePicker(
                  type: DateTimePickerType.dateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialValue: _eventDateTime?.toIso8601String(),
                  dateLabelText: "Select Event Date & Time",
                  onChanged: (value) => setState(() => _eventDateTime = DateTime.tryParse(value)),
                  decoration: const InputDecoration(
                    labelText: "Event Date & Time",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  ),
                ),
              ),
              Spacing.h35,
              AppButton.miniFlat(
                text: "Select Employee",
                width: 120,
                onTap: () async {
                  final user = await UserSelectionModal.selectSingle(
                    context,
                    selectedUser: _contactPerson,
                  );
                  setState(() {
                    _contactPerson = user;
                  });
                },
              ),
              if (_contactPerson != null) ...[
                Spacing.h10,
                Chip(
                  label: Text(_contactPerson!.fullName),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _contactPerson = null),
                ),
              ],
              const Spacer(),
              BlocSelector<AddEditEventCubit, AddEditEventState, bool>(
                selector: (state) => state.status is AddEditEventLoading,
                builder:
                    (context, isLoading) => AppButton.flat(
                      text: editEvent ? 'Update' : 'Submit',
                      width: double.infinity,
                      showLoading: isLoading,
                      onTap: () {
                        if (_formKey.currentState?.validate() != true) return;
                        final newEvent = EventModel(
                          id: events?.id,
                          sessionName: _sessionNameTED.text.trim(),
                          location: _locationTED.text.trim(),
                          contactPerson: _contactPerson!,
                          eventDateTime: _eventDateTime!,
                          createdBy: context.read<UserCubit>().state.currentUser!,
                        );
                        context.read<AddEditEventCubit>().onSubmit(this.context, newEvent);
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
