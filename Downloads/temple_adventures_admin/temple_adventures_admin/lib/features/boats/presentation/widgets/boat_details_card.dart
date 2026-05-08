import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/bookings/models/booking.model.dart';
import 'package:temple_adventures_admin/utils/debouncer.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/app_text_field.dart';
import 'package:temple_adventures_admin/widgets/user_tank_selection.modal.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/bloc/filtered_bookings_list.cubit.dart';
import '../../../../widgets/key_value_pair.dart';
import '../../../bookings/presentation/widgets/custom_title.dart';
import '../../bloc/boat_details_card.cubit.dart';
import '../../enums/user_type.enum.dart';
import '../../helpers/board_plan.helper.dart';
import '../../models/boat_info.model.dart';
import '../../models/boats.model.dart';
import '../screens/add_edit_boat_details.screen.dart';
import 'booking_status.dart';
import 'counter_widget.dart';

class BoatDetailsCard extends StatefulWidget {
  final Booking booking;
  final DateTime selectedDate;
  final List<Boat> allBoats;

  const BoatDetailsCard({super.key, required this.booking, required this.selectedDate, required this.allBoats});

  @override
  State<BoatDetailsCard> createState() => _BoatDetailsCardState();
}

class _BoatDetailsCardState extends State<BoatDetailsCard> {
  bool _expanded = false;

  final Debouncer debouncer = Debouncer();
  late TextEditingController equipmentNotesTED;

  late Booking updatedBooking;

  @override
  void initState() {
    updatedBooking = widget.booking;
    equipmentNotesTED = TextEditingController(text: updatedBooking.equipmentNotes);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = widget.selectedDate;
    return Container(
      decoration: BoxDecoration(
        color: (updatedBooking.cancelBooking ?? false) ? Colors.red.shade300 : updatedBooking.activity.toDartColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: CustomTitle(
                    title: '${updatedBooking.primaryCustomer.firstName} x ${updatedBooking.noOfPersons}',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ).paddingOnly(left: 15),
                ),
                if (updatedBooking.boat != null) Icon(Icons.directions_boat, size: 14).paddingOnly(right: 10),
                if (updatedBooking.instructor != null) Icon(Icons.scuba_diving, size: 14).paddingOnly(right: 10),
                if (updatedBooking.isQuickBooking)
                  Text('(Quick)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded ? _buildExpandedContent(selectedDate) : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(DateTime selectedDate) {
    return BlocBuilder<BoatDetailsCardCubit, BoatDetailsCardState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            if (updatedBooking.cancelBooking == true)
              KeyValuePair(title: 'Cancellation Reason', value: updatedBooking.cancellationReason),
            KeyValuePair(title: 'Booking Id', value: '${updatedBooking.id}'),
            KeyValuePair(title: 'Activity', value: updatedBooking.activity.name),
            KeyValuePair(title: 'Pax', value: '${updatedBooking.noOfPersons}'),
            KeyValuePair(title: 'Time', value: getSessionsAndTimes(selectedDate, false).join(', ')),
            KeyValuePair(title: 'Session', value: getSessionsAndTimes(selectedDate, true).join(', ')),
            KeyValuePair(title: 'Registered', value: '1 / 2'),
            KeyValuePair(title: 'Remarks', value: updatedBooking.remarks),
            if (!updatedBooking.isDSD) ...[
              Spacing.h10,
              KeyValuePair(
                title: 'Instructor (N - A)',
                titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                widget:
                    AppButton.miniFlat(
                      text: 'Manage',
                      onTap: () async {
                        final selectedInstructor = await UserTankSelectionModal.selectSingle(
                          context,
                          selectedTankInfo:
                        (updatedBooking.instructor != null)? updatedBooking.instructor!:null,
                          userType: UserType.showFreelancersDivers,
                        );

                        if (!context.mounted) return;
                        final booking = context.read<BoatDetailsCardCubit>().updateInstructor(
                          selectedInstructor,
                          updatedBooking,
                        );

                        if (booking != null) {
                          updatedBooking = booking;
                          setState(() {});
                        }

                        /// update boardPlan on the selectedDate
                        _updateBoardPlan(selectedDate);

                      },
                    ).right,
              ),
              if (updatedBooking.instructor != null)
                CustomTitle(
                  title: updatedBooking.instructor!.formatedTankInfo(),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
            ],
            Spacing.h10,
            KeyValuePair(
              title: 'Dive Buddies (N - A)',
              titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              widget:
                  AppButton.miniFlat(
                    text: 'Manage',
                    onTap: () async {
                      final selectedDiveBuddies = await UserTankSelectionModal.selectMultiple(
                        context,
                        initialTankInfos: updatedBooking.buddies ?? [],
                        userType: UserType.showFreelancersDivers,
                      );

                      if (!context.mounted) return;
                      final booking = context.read<BoatDetailsCardCubit>().updateDiveBuddies(
                        selectedDiveBuddies,
                        updatedBooking,
                      );

                      if (booking != null) {
                        updatedBooking = booking;
                        setState(() {});
                      }

                      /// update boardPlan on the selectedDate
                      _updateBoardPlan(selectedDate);

                    },
                  ).right,
            ),
            ...(updatedBooking.buddies ?? []).map(
              (TankInfo user) => CustomTitle(title: user.formatedTankInfo(), fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Spacing.h10,
            Row(
              children: [
                BookingStatus(
                  initialStatus: updatedBooking.status ?? 0,
                  onChanged: (int status) {
                    debouncer(() {
                      updatedBooking = updatedBooking.copyWith(status: status);
                      context.read<BoatDetailsCardCubit>().updateBooking(updatedBooking);

                      /// update boardPlan on the selectedDate
                      _updateBoardPlan(selectedDate);

                    });
                  },
                  isDSD: true,
                ),
                Spacer(),
                BoatSelector(
                  allBoats: widget.allBoats,
                  onChanged: (Boat? boat)  {
                    updatedBooking = updatedBooking.copyWith(boat: boat);
                    context.read<BoatDetailsCardCubit>().updateBoatStatus(
                      boatStatusId: updatedBooking.bookingStatusId!,
                      boatId: updatedBooking.boat?.id,
                      nitrox: updatedBooking.nitrox,
                      air: updatedBooking.air,
                    );
                    context.read<FilteredBookingsListCubit>().updateBooking(updatedBooking);

                    /// update boardPlan on the selectedDate
                    _updateBoardPlan(selectedDate);
                  },
                ),
              ],
            ),
            CustomTitle(
              title: updatedBooking.boat?.nameAndTime ?? '',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ).paddingOnly(top: 5).right,
            Spacing.h10,
            if (!updatedBooking.isDSD)
              Row(
                children: [
                  CounterWidget(
                    label: 'Nitrox',
                    onChanged: (int nitrox) {
                      updatedBooking = updatedBooking.copyWith(nitrox: nitrox);
                      debouncer(()  {
                        if (updatedBooking.bookingStatusId == null) return;
                        context.read<BoatDetailsCardCubit>().updateBoatStatus(
                          boatStatusId: updatedBooking.bookingStatusId!,
                          nitrox: nitrox,
                          air: updatedBooking.air,
                          boatId: updatedBooking.boat?.id,
                        );

                        /// update boardPlan on the selectedDate
                        _updateBoardPlan(selectedDate);

                      });
                    },
                    initialValue: updatedBooking.nitrox ?? 0,
                  ),
                  Spacer(),
                  CounterWidget(
                    label: 'Air',
                    onChanged: (int air) {
                      updatedBooking = updatedBooking.copyWith(air: air);
                      debouncer(() {
                        if (updatedBooking.bookingStatusId == null) return;
                        context.read<BoatDetailsCardCubit>().updateBoatStatus(
                          boatStatusId: updatedBooking.bookingStatusId!,
                          air: air,
                          nitrox: updatedBooking.nitrox,
                          boatId: updatedBooking.boat?.id,
                        );

                        /// update boardPlan on the selectedDate
                        _updateBoardPlan(selectedDate);

                      });
                    },
                    initialValue: updatedBooking.air ?? 0,
                  ),
                ],
              ),
            AppTextField(controller: equipmentNotesTED, labelText: 'Equipment Notes'),
            Text('Notes wont be saved until "Update Notes" button is pressed', style: TextStyle(fontSize: 10)),
            Spacing.h5,
            AppButton.miniFlat(
              text: 'Update',
              onTap: () {
                context.closeKeyboard();
                updatedBooking = updatedBooking.copyWith(equipmentNotes: equipmentNotesTED.text);
                context.read<BoatDetailsCardCubit>().updateBooking(updatedBooking);

                /// update boardPlan on the selectedDate
                _updateBoardPlan(selectedDate);
              },
            ).right,
            Spacing.h20,
            CustomTitle(
              title: 'Created by :  ${updatedBooking.createdBy.fullName}',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ],
        );
      },
    ).paddingAll(15);
  }

  Future<void> _updateBoardPlan(DateTime selectedDate) async {
    await BoardPlanHelper.updateBoardPlan(selectedDate);
  }


  List<String> getSessionsAndTimes(DateTime selectedDate, bool returnSessionsOnly) {
    final poolTimes =
        updatedBooking.poolDate?.where((d) => d.isSameDate(selectedDate)).map((d) => d.formatHHMM).toList() ?? [];

    // Dive Times
    final diveTimes =
        updatedBooking.diveDate?.where((d) => d.isSameDate(selectedDate)).map((d) => d.formatHHMM).toList() ?? [];

    // Theory Times
    final theoryTimes =
        updatedBooking.theoryDate?.where((d) => d.isSameDate(selectedDate)).map((d) => d.formatHHMM).toList() ?? [];

    // Sessions
    final sessions = <String>[];
    if (poolTimes.isNotEmpty) sessions.add('Pool');
    if (diveTimes.isNotEmpty) sessions.add('Dive');
    if (theoryTimes.isNotEmpty) sessions.add('Theory');

    if (returnSessionsOnly) return sessions;

    final allTimes = [...poolTimes, ...diveTimes, ...theoryTimes];
    return allTimes;
  }
}

class BoatSelector extends StatefulWidget {
  final List<Boat> allBoats;
  final ValueChanged<Boat?> onChanged;

  const BoatSelector({super.key, required this.allBoats, required this.onChanged});

  @override
  State<BoatSelector> createState() => _BoatSelectorState();
}

class _BoatSelectorState extends State<BoatSelector> {
  Boat? selectedBoat;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<dynamic>(
      color: Colors.white,
      child: Container(
        height: 31,
        width: 90,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
        child:
            Text(
              (selectedBoat == null) ? 'Select Boat' : 'Change Boat',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ).center,
      ),
      itemBuilder: (BuildContext context) {
        return [
          ...widget.allBoats.map((boat) {
            return PopupMenuItem<dynamic>(
              value: boat.name,
              onTap: () {
                selectedBoat = boat;
                widget.onChanged(selectedBoat);
              },
              child:
                  Text(
                    boat.nameAndTime,
                    style: TextStyle(fontSize: 12),
                  ).center,
            );
          }),
          if (widget.allBoats.isNotEmpty)
            PopupMenuItem<dynamic>(
              value: 'Un-Assign Boat',
              onTap: () {
                selectedBoat = null;
                widget.onChanged(selectedBoat);
              },
              child: Column(
                children: [
                  const Divider(color: Colors.black26),
                  const SizedBox(height: 5),
                  const Text('Un-Assign Boat', style: TextStyle(fontSize: 12)).paddingOnly(bottom: 2),
                ],
              ),
            ),
          PopupMenuItem<dynamic>(
            value: 'Add Boat',
            onTap: () {
              Navigator.push(context, AddEditBoatDetailsScreen.route());
            },
            child: Column(
              children: [
                const Divider(color: Colors.black26),
                const SizedBox(height: 5),
                const Text('Add Boat', style: TextStyle(fontSize: 12)).paddingOnly(bottom: 2),
              ],
            ),
          ),
        ];
      },
    );
  }
}
