import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/boats/enums/boat_status.enum.dart';
import 'package:temple_adventures_admin/features/boats/enums/boat_type.enum.dart';
import 'package:temple_adventures_admin/features/boats/models/boat_info.model.dart';
import 'package:temple_adventures_admin/features/boats/models/boats.model.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/custom_title.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';
import '../../../../theme.dart';
import '../../../../utils/locator.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/custom_alert_dialog.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/custom_time_picker.dart';
import '../../../../widgets/user_selection_tile.dart';
import '../../bloc/add_edit_boat_details.cubit.dart';
import '../../bloc/boats.cubit.dart';
import '../../enums/user_type.enum.dart';
import '../../repository/boats.repository.dart';
import '../widgets/boat_status_selector.dart';
import '../widgets/counter_widget.dart';

class AddEditBoatDetailsScreen extends StatefulWidget {
  final Boat? boat;

  const AddEditBoatDetailsScreen({super.key, this.boat});

  static MaterialPageRoute<dynamic> route({Boat? boat}) {
    return MaterialPageRoute(builder: (_) => AddEditBoatDetailsScreen(boat: boat));
  }

  @override
  State<AddEditBoatDetailsScreen> createState() => _AddEditBoatDetailsScreenState();
}

class _AddEditBoatDetailsScreenState extends State<AddEditBoatDetailsScreen> {
  late bool hideBoat;
  late bool isBoat;
  late BoatType typeOfBoat;
  late BoatStatus status;
  late TextEditingController boatNoTED;
  late TextEditingController boatNameTED;
  late TextEditingController diveSiteTED;
  late TextEditingController notesTED;
  late DateTime selectedTime;
  List<TankInfo> _captains = [];
  List<TankInfo> _dsdInstructors = [];
  List<TankInfo> _photographers = [];
  List<TankInfo> _internPhotographers = [];
  List<TankInfo> _surfaceSupport = [];
  late int spareNitrox;
  late int spareAir;
  final _formKey = GlobalKey<FormState>();

  Boat? get boat => widget.boat;

  @override
  void initState() {
    super.initState();
    hideBoat = boat?.hide ?? false;
    isBoat = (boat == null || (boat?.type == BoatType.boat)) ? true : false;
    typeOfBoat = boat?.type ?? BoatType.boat;
    status = boat?.status ?? BoatStatus.ready;
    boatNoTED = TextEditingController(text: boat?.number);
    boatNameTED = TextEditingController(text: boat?.name);
    diveSiteTED = TextEditingController(text: boat?.diveSite);
    notesTED = TextEditingController(text: boat?.notes);
    _captains = boat?.captains ?? [];
    _dsdInstructors = boat?.dsdInstructors ?? [];
    _photographers = boat?.photographers ?? [];
    _internPhotographers = boat?.internPhotographers ?? [];
    _surfaceSupport = boat?.surfaceSupport ?? [];
    selectedTime = boat?.time ?? context.read<BoatsCubit>().state.selectedDate;
    spareAir = boat?.spareAir ?? 0;
    spareNitrox = boat?.spareNitrox ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddEditBoatDetailsCubit(repository: locator<BoatsRepository>()),
      child: BlocConsumer<AddEditBoatDetailsCubit, AddEditBoatDetailsState>(
        listener: (context, state) {
          final status = state.status;
          if (status is AddEditBoatDetailsSuccess) {
            context.read<BoatsCubit>().fetchBookingAndBoats();
            context.showSnackBar((boat == null) ? 'Boat Added Successfully' : 'Boat Updated Successfully');
            Navigator.pop(context);
          }
          if (status is AddEditBoatDetailsError) {
            context.showSnackBar('Error: ${status.message}');
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: CustomAppBar(
              title: 'Boat Details',
              description: (boat == null) ? 'Add Boat Details' : 'Edit Boat Details',
              action:
                  (boat != null)
                      ? IconButton(
                        onPressed: () async {
                          final shouldDelete = await CustomAlertDialog.show(
                            context,
                            title: 'Are you sure ?',
                            content: 'This Boat will be deleted completely.',
                          );
                          if (shouldDelete == true && context.mounted) {
                            await context.read<AddEditBoatDetailsCubit>().deleteBoat(boat!.id!);
                          }
                        },
                        icon:
                            (state.status is AddEditBoatDetailsLoading)
                                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2).size(20, 20)
                                : Icon(Icons.delete, size: 20, color: Colors.white),
                      ).paddingOnly(right: 10)
                      : SizedBox(),
            ),
            bottomNavigationBar: AppButton.flat(
              text: (boat == null) ? 'Submit' : 'Update',
              showLoading: state.status is AddEditBoatDetailsLoading,
              onTap: () async {
                if (_formKey.currentState?.validate() != true) return;

                final newBoat = Boat(
                  id: boat?.id,
                  hide: hideBoat,
                  type: typeOfBoat,
                  number: boatNoTED.text.trim(),
                  name: boatNameTED.text.trim(),
                  notes: notesTED.text,
                  diveSite: diveSiteTED.text.trim(),
                  date: selectedTime.formatDDMMYYYY,
                  time: selectedTime,
                  captains: _captains.map((tank) => tank.copyWith(role: Role.captains)).toList(),
                  dsdInstructors: _dsdInstructors.map((tank) => tank.copyWith(role: Role.dsdInstructors)).toList(),
                  photographers: _photographers.map((tank) => tank.copyWith(role: Role.photographers)).toList(),
                  internPhotographers:
                      _internPhotographers.map((tank) => tank.copyWith(role: Role.internPhotographers)).toList(),
                  surfaceSupport: _surfaceSupport.map((tank) => tank.copyWith(role: Role.surfaceSupport)).toList(),
                  spareNitrox: spareNitrox,
                  spareAir: spareAir,
                  status: status,
                );

                context.read<AddEditBoatDetailsCubit>().onSubmit(newBoat);
              },
            ).paddingAll(20),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        BoatStatusSelector(
                          initialStatus: status,
                          onChanged: (updatedStatus) {
                            setState(() {
                              status = updatedStatus;
                            });
                          },
                        ),
                        Row(
                          children: [
                            Text(
                              'Hide Boat',
                              style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Switch(
                              value: hideBoat,
                              onChanged: (value) {
                                setState(() {
                                  hideBoat = value;
                                });
                              },
                              activeThumbColor: skyBlueColor,
                              inactiveThumbColor: Colors.grey,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Other',
                              style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Switch(
                              value: isBoat,
                              onChanged: (value) {
                                setState(() {
                                  isBoat = value;
                                  typeOfBoat = isBoat ? BoatType.boat : BoatType.other;
                                });
                              },
                              activeThumbColor: skyBlueColor,
                              inactiveThumbColor: Colors.grey,
                            ),
                            Text(
                              'Boat',
                              style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        AppTextField(controller: boatNoTED, labelText: 'Boat No'),
                        AppTextField(
                          controller: boatNameTED,
                          labelText: 'Boat Name *',
                          validator: (value) => value == null || value.trim().isEmpty ? 'required' : null,
                        ),
                        AppTextField(
                          controller: diveSiteTED,
                          labelText: 'Dive Site *',
                          validator: (value) => value == null || value.trim().isEmpty ? 'required' : null,
                        ),
                        Spacing.h10,
                        KeyValuePair(
                          title: 'Boat Time',
                          widget: GestureDetector(
                            onTap: () {
                              selectTime(context);
                            },
                            child: Container(
                              height: 30,
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child:
                                  Text(
                                    selectedTime.formatHHMM,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ).center,
                            ),
                          ),
                        ),
                        Spacing.h5,
                        Column(
                          children: [
                            UserSelectorTile(
                              title: 'Captains',
                              selectedUsers: _captains,
                              userType: UserType.showCaptains,
                              tanksRequired: false,
                              onUsersSelected: (users) => setState(() => _captains = users),
                            ),
                            UserSelectorTile(
                              title: 'DSD Instructors',
                              selectedUsers: _dsdInstructors,
                              userType: UserType.showDiveTeam,
                              onUsersSelected: (users) => setState(() => _dsdInstructors = users),
                            ),
                            UserSelectorTile(
                              title: 'Photographers',
                              selectedUsers: _photographers,
                              userType: UserType.showFreelancersDivers,
                              onUsersSelected: (users) => setState(() => _photographers = users),
                            ),
                            UserSelectorTile(
                              title: 'Intern Photographers',
                              selectedUsers: _internPhotographers,
                              userType: UserType.showInterns,
                              onUsersSelected: (users) => setState(() => _internPhotographers = users),
                            ),
                            Spacing.h5,
                            UserSelectorTile(
                              title: 'Surface Support',
                              selectedUsers: _surfaceSupport,
                              tanksRequired: false,
                              userType: UserType.showAllUsers,
                              onUsersSelected: (users) => setState(() => _surfaceSupport = users),
                            ),
                          ],
                        ),
                        AppTextField(controller: notesTED, labelText: 'Notes'),
                        Spacing.h5,
                        CustomTitle(title: 'Extra / Spare Tanks', fontSize: 14, fontWeight: FontWeight.w600),
                        Spacing.h10,
                        Row(
                          children: [
                            CounterWidget(
                              label: 'Nitrox',
                              onChanged: (int val) {
                                spareNitrox = val;
                              },
                              initialValue: spareNitrox,
                            ),
                            Spacer(),
                            CounterWidget(
                              label: 'Air',
                              onChanged: (int val) {
                                spareAir = val;
                              },
                              initialValue: spareAir,
                            ),
                          ],
                        ),
                      ],
                    ).paddingAll(20).scrollable,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> selectTime(BuildContext context) async {
    final DateTime? pickedTime = await TimePicker.show(context, initialTime: selectedTime);

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }
}
