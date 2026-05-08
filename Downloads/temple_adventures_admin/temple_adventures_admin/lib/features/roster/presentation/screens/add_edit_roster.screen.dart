import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/boats/models/boat_info.model.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/custom_title.dart';
import 'package:temple_adventures_admin/features/roster/models/dsd_customer.model.dart';
import 'package:temple_adventures_admin/features/roster/presentation/widgets/customer_feedback.modal.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/user_selection.modal.dart';
import '../../../boats/enums/user_type.enum.dart';
import '../../../user/models/user.model.dart';
import '../../bloc/add_edit_roster.cubit.dart';
import '../../bloc/roster.cubit.dart';
import '../../models/roster.model.dart';
import '../../repository/roster.repository.dart';
import '../widgets/roster_time_editor.modal.dart';

class AddEditRosterScreen extends StatefulWidget {
  const AddEditRosterScreen({
    super.key,
    required this.instructors,
    required this.customer,
    required this.selectedDate,
  });

  final List<TankInfo> instructors;
  final DSDCustomer customer;
  final DateTime selectedDate;

  static MaterialPageRoute<dynamic> route({
    required List<TankInfo> instructors,
    required DSDCustomer customer,
    required DateTime selectedDate,
    Roster? roster,
  }) => MaterialPageRoute(
    builder: (context) {
      return BlocProvider(
        create: (context) => AddEditRosterCubit(repository: locator<RosterRepository>()),
        child: AddEditRosterScreen(
          instructors: instructors,
          customer: customer,
          selectedDate: selectedDate,
        ),
      );
    },
  );

  @override
  State<AddEditRosterScreen> createState() => _AddEditRosterScreenState();
}

class _AddEditRosterScreenState extends State<AddEditRosterScreen> {
  User? _instructor;
  TimeOfDay? _timeIn;
  TimeOfDay? _timeOut;
  bool _isDived = false;

  Roster? get roster => widget.customer.roster;
  bool get editMode => roster != null;

  @override
  void initState() {
    super.initState();
    _instructor = roster?.instructor;
    _timeIn = roster?.timeIn;
    _timeOut = roster?.timeOut;
    _isDived = roster?.isDived ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: editMode ? 'Update Roster' : 'Add Roster', description: ''),
      body: SafeArea(
        child: BlocConsumer<AddEditRosterCubit, AddEditRosterState>(
          listener: (context, state) {
            final status = state.status;
            if (status is AddEditRosterSuccess) {
              Navigator.pop(context);
              // Refresh the roster data while preserving the current boat selection
              context.read<RosterCubit>().refreshData();
            }

            if (status is AddEditRosterError) context.showSnackBar(status.message);
          },
          builder: (context, state) {
            return Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 50,
                  ),
                ).size(70, 70).center,
                Spacing.h20,
                CustomTitle(
                  title: widget.customer.fullName,
                  fontWeight: FontWeight.w700,
                ),
                Spacing.h20,
                Spacing.h20,
                KeyValuePair(
                  title: 'Instructor',
                  widget:
                      AppButton.miniFlat(
                        text: 'Select',
                        onTap: () async {
                          // Select a single instructor
                          final instructor = await UserSelectionModal.selectSingle(
                            context,
                            selectedUser: _instructor,
                            dsdInstructors:
                                widget.instructors
                                    .where((instructor) => instructor.userId != null)
                                    .map((instructor) => instructor.userId!)
                                    .toList(),
                            userType: UserType.showAllUsers,
                          );

                          _instructor = instructor;
                          setState(() {});
                        },
                      ).right,
                ),
                Spacing.h20,
                if (_instructor != null)
                  CustomTitle(
                    title: _instructor?.fullName ?? '',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ).left,
                Spacing.h20,
                Row(
                  children: [
                    _TimeButtons(
                      title: 'In the water',
                      onTap: () {
                        _timeIn ??= TimeOfDay.now();
                        setState(() {});
                      },
                      color: (_timeIn != null) ? lightSkyBlue : Colors.white,
                    ),
                    Spacing.w20,
                    _TimeButtons(
                      title: 'Out of water',
                      onTap: () {
                        _timeOut ??= TimeOfDay.now();
                        setState(() {});
                      },
                      color: (_timeOut != null) ? lightSkyBlue : Colors.white,
                    ),
                  ],
                ),
                Spacing.h20,
                Row(
                  children: [
                    if (_timeIn != null)
                      Expanded(
                        child: Text(
                          'In water time : ${_timeIn!.formatTimeOfDay}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    Spacing.w20,
                    if (_timeOut != null)
                      Expanded(
                        child: Text(
                          'Out water time : ${_timeOut!.formatTimeOfDay}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
                Spacing.h10,
                if (_timeIn != null || _timeOut != null)
                  _TextEditor(
                    title: 'Change, In the water and out the water timings ',
                    onTap: () async {
                      List<TimeOfDay?> times = await RoasterTimeEditorModal.show(
                        context,
                        _timeIn,
                        _timeOut,
                      );

                      if (times.isNotEmpty) {
                        _timeIn = times[0];
                        _timeOut = times[1];
                        setState(() {});
                      }

                      if (_timeIn == null && _timeOut == null) {
                        _isDived = false;
                        setState(() {});
                        return;
                      }
                    },
                  ).paddingOnly(bottom: 20),
                _buildIsDivedButtons(),
                Spacing.h30,
                if (widget.customer.customerFeedback != null)
                  _TextEditor(
                    title: 'Customer feedback is already submitted to fill again click ',
                    onTap: () async {
                      await CustomerFeedbackModal.show(
                        context,
                        customerFeedback: widget.customer.customerFeedback,
                        bookingId: widget.customer.bookingId!,
                        customerId: widget.customer.customerId!,
                        isFeedbackAlreadySubmitted: true,
                      );
                    },
                  ),
                Spacer(),
                AppButton.flat(
                  width: Screen.width,
                  text: editMode ? 'Update' : 'Submit',
                  showLoading: state.status is AddEditRosterLoading,
                  onTap: () {
                    final updateRoster = Roster(
                      id: roster?.id,
                      instructor: _instructor,
                      timeIn: _timeIn,
                      timeOut: _timeOut,
                      isDived: _isDived,
                      customerId: widget.customer.customerId!,
                      bookingId: widget.customer.bookingId!,
                    );
                    context.read<AddEditRosterCubit>().onSubmit(roster: updateRoster);
                  },
                ),
              ],
            );
          },
        ).paddingAll(20),
      ),
    );
  }

  Widget _buildIsDivedButtons() {
    return Row(
      children: [
        Text(
          'Is Dived Completed',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
        Spacing.w20,
        _TimeButtons(
          title: 'Yes',
          onTap: () {
            setState(() {
              _isDived = true;
            });
          },
          color: (_isDived == true) ? lightSkyBlue : Colors.white,
        ),
        Spacing.w10,
        _TimeButtons(
          title: 'No',
          onTap: () {
            setState(() {
              _isDived = false;
            });
          },
          color: (_isDived == false) ? lightSkyBlue : Colors.white,
        ),
      ],
    );
  }
}

class _TextEditor extends StatelessWidget {
  final String title;
  final GestureTapCallback onTap;

  const _TextEditor({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10),
        ),
        InkWell(
          onTap: onTap,
          child: const Text(
            ' here',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeButtons extends StatelessWidget {
  const _TimeButtons({required this.title, required this.onTap, required this.color});

  final String title;
  final GestureTapCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
            ),
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(title),
        ),
      ),
    );
  }
}
