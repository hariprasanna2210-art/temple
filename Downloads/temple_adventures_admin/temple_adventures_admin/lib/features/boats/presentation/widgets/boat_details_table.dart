import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/boats/enums/boat_status.enum.dart';
import 'package:temple_adventures_admin/features/boats/models/boat_info.model.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../utils/styling/spacing_widgets.dart';
import '../../../bookings/models/booking.model.dart';
import '../../bloc/board_plan.cubit.dart';
import '../../models/boats.model.dart';
import 'booking_status.dart';

// Structured constants for better organization
class _BoatTableConstants {
  static const double tableWidth = 190.0;
  static const font = _FontSizes();
  static const col = _ColumnWidths();
}

class _FontSizes {
  const _FontSizes();

  double get normal => 7.0;
  double get header => 14.0;
}

class _ColumnWidths {
  const _ColumnWidths();

  double get slNo => 10.0;
  double get name => 70.0;
  double get tanks => 20.0;
  double get activity => 30.0;
  double get status => 35.0;
  double get heading => 80.0;
  double get staffName => 73.0;
  double get statusAction => 40.0;
  double get airNitrox => 22.0;
  double get surfaceSupport => 64.0;
  double get notes => 100.0;
}

enum _StaffType { dsd, photographer, internPhotographer }

// Map-driven staff configuration - much cleaner than switch-case
const Map<_StaffType, _StaffConfig> _staffConfigMap = {
  _StaffType.dsd: _StaffConfig(
    icon: ' - ',
    nameColor: Colors.red,
    roleText: 'DSD Staff',
  ),
  _StaffType.photographer: _StaffConfig(
    icon: '📷',
    nameColor: Colors.red,
    roleText: 'Photo / Video',
  ),
  _StaffType.internPhotographer: _StaffConfig(
    icon: '📷',
    nameColor: Colors.green,
    roleText: 'Photo / Video',
  ),
};

class BoatDetailsTable extends StatelessWidget {
  const BoatDetailsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BoardPlanCubit, BoardPlanState, Boat?>(
      selector: (state) => state.selectedBoat,
      builder: (context, boat) {
        if (boat == null) return SizedBox();

        final state = context.read<BoardPlanCubit>().state;
        final bookings = state.bookings[boat.id] ?? [];
        final selectedDate = state.selectedDate;

        // Use business logic service to group bookings
        final instructorGroups = _BoatCalculations.groupBookingsByInstructor(bookings);

        return Container(
          width: _BoatTableConstants.tableWidth,
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black)),
          child: Column(
            children: [
              _BoatDetailsHeader(boat: boat, date: selectedDate!),
              const Divider(height: 1, color: Colors.black),
              const _ColumnHeadings(),
              const Divider(height: 1, color: Colors.black),

              // Display instructor groups
              ...instructorGroups.entries.map((entry) {
                final slNo = instructorGroups.keys.toList().indexOf(entry.key) + 1;
                return _InstructorGroupWidget(
                  instructorGroup: entry.value,
                  slNo: slNo,
                );
              }),

              const Divider(color: Colors.black, height: 1),

              // Staff sections using reusable widget
              ..._buildStaffRows(boat.dsdInstructors, _StaffType.dsd),
              ..._buildStaffRows(boat.photographers, _StaffType.photographer),
              ..._buildStaffRows(boat.internPhotographers, _StaffType.internPhotographer),

              const Divider(color: Colors.black, height: 1),
              _AllTotals(boat: boat, bookings: bookings),
            ],
          ),
        );
      },
    );
  }

  /// Builds staff rows for different staff types
  List<Widget> _buildStaffRows(List<TankInfo>? staff, _StaffType staffType) {
    if (staff == null || staff.isEmpty) return [];

    return staff
        .map(
          (staffMember) => _StaffRow(
            staffMember: staffMember,
            staffType: staffType,
          ),
        )
        .toList();
  }
}

/// Reusable widget for staff rows (DSD instructors, photographers, intern photographers)
class _StaffRow extends StatelessWidget {
  final TankInfo staffMember;
  final _StaffType staffType;

  const _StaffRow({
    required this.staffMember,
    required this.staffType,
  });

  @override
  Widget build(BuildContext context) {
    final config = _staffConfigMap[staffType]!;

    return Row(
      children: [
        Text(
          config.icon,
          style: TextStyle(fontSize: _BoatTableConstants.font.normal),
        ).width(_BoatTableConstants.col.slNo),
        SizedBox(
          width: _BoatTableConstants.col.staffName,
          child: Text(
            staffMember.name,
            style: TextStyle(
              fontSize: _BoatTableConstants.font.normal,
              color: config.nameColor,
            ),
          ),
        ).paddingOnly(top: 3, left: 3),
        _TankInfoDisplay(
          air: staffMember.air,
          nitrox: staffMember.nitrox,
          width: _BoatTableConstants.col.tanks,
        ),
        Spacing.w24,
        Text(
          config.roleText,
          style: TextStyle(fontSize: _BoatTableConstants.font.normal, color: Colors.blue),
        ).paddingOnly(top: 3, left: 13),
      ],
    );
  }
}

class _StaffConfig {
  final String icon;
  final Color nameColor;
  final String roleText;

  const _StaffConfig({
    required this.icon,
    required this.nameColor,
    required this.roleText,
  });
}

/// Reusable widget for displaying air-nitrox tank counts in consistent format
class _TankInfoDisplay extends StatelessWidget {
  final int? air;
  final int? nitrox;
  final double? width;

  const _TankInfoDisplay({
    required this.air,
    required this.nitrox,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Text(
            '${air ?? 0}',
            style: TextStyle(fontSize: _BoatTableConstants.font.normal, color: Colors.blue),
          ),
          Text(' - ', style: TextStyle(fontSize: _BoatTableConstants.font.normal)),
          Text(
            '${nitrox ?? 0}',
            style: TextStyle(fontSize: _BoatTableConstants.font.normal, color: Colors.green),
          ),
        ],
      ),
    );
  }
}

class _BoatDetailsHeader extends StatelessWidget {
  final Boat boat;
  final DateTime date;

  const _BoatDetailsHeader({required this.boat, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 90, child: Text(boat.name, style: TextStyle(fontSize: _BoatTableConstants.font.header))),
              _HeadingItem('Time: ', boat.time.formatHHMM),
              _HeadingItem('Date: ', date.formatDDMMYYYY),
              _HeadingItem('Status: ', boat.status.prettyName),
            ],
          ),
          Container(constraints: const BoxConstraints(minWidth: 10)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Spacing.h2,
              if (boat.captains?.isNotEmpty ?? false) _HeadingItem('Captain 1:', " ${boat.captains?[0].name ?? '-'}"),
              if ((boat.captains?.length ?? 0) == 2) _HeadingItem('Captain 2:', " ${boat.captains?[1].name ?? '-'}"),
              _HeadingItem('Dive Site:', " ${boat.diveSite ?? '-'}"),
              Wrap(
                children: [
                  Text(
                    'Surface Support:',
                    style: TextStyle(fontSize: _BoatTableConstants.font.normal, fontWeight: FontWeight.w600),
                  ).paddingSymmetric(vertical: 1),
                  ...(boat.surfaceSupport ?? []).map(
                    (e) => Text(
                      '${e.userFirstName} , ',
                      style: TextStyle(
                        fontSize: _BoatTableConstants.font.normal,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ).width(64),
              if (boat.notes != null) _HeadingItem('Boat Notes:', boat.notes ?? '-'),
              Spacing.h2,
            ],
          ),
        ],
      ).paddingSymmetric(horizontal: 5),
    );
  }
}

class _HeadingItem extends StatelessWidget {
  const _HeadingItem(this.title, this.value);

  final String title, value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$title ',
        style: TextStyle(
          fontSize: _BoatTableConstants.font.normal,
          color: Colors.black,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
        ),
        children: <TextSpan>[
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: _BoatTableConstants.font.normal,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    ).width(_BoatTableConstants.col.notes - 32).paddingSymmetric(vertical: 1);
  }
}

/// Simplified widget for displaying instructor groups
class _InstructorGroupWidget extends StatelessWidget {
  final InstructorGroup instructorGroup;
  final int slNo;

  const _InstructorGroupWidget({
    required this.instructorGroup,
    required this.slNo,
  });

  @override
  Widget build(BuildContext context) {
    if (instructorGroup.bookings.isEmpty) {
      return const SizedBox();
    }

    // If no instructor, show bookings without instructor header
    if (!instructorGroup.hasInstructor) {
      return Column(
        children: [
          // Show other bookings first, then DSD bookings
          ...instructorGroup.otherBookings.asMap().entries.map(
            (entry) => _CustomerItem(entry.key, entry.value, '?'),
          ),
          ...instructorGroup.dsdBookings.asMap().entries.map(
            (entry) => _CustomerItem(entry.key, entry.value, '-'),
          ),
        ],
      );
    }

    // Show instructor header with totals, then bookings
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black26, width: 1))),
      child: Column(
        children: [
          // Instructor header row
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Spacing.w3,
              SizedBox(
                width: 10,
                child: Text(slNo.toString(), style: const TextStyle(fontSize: 7.0)),
              ).paddingOnly(top: 3),
              Text(
                instructorGroup.instructorName ?? '-',
                style: const TextStyle(fontSize: 7.0, color: Colors.red),
              ).paddingOnly(top: 3).left.width(70),
              _TankInfoDisplay(
                air: instructorGroup.airTotal,
                nitrox: instructorGroup.nitroxTotal,
                width: 20,
              ).paddingOnly(top: 3),
            ],
          ),
          // Individual booking rows
          ...instructorGroup.bookings.asMap().entries.map(
            (entry) => _CustomerItem(entry.key, entry.value, ' '),
          ),
        ],
      ),
    );
  }
}

class _CustomerItem extends StatelessWidget {
  const _CustomerItem(this.index, this.booking, this.slNo);

  final int index;
  final String slNo;
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _BoatTableConstants.tableWidth,
      decoration: BoxDecoration(color: index.isOdd ? Colors.white : skyBlueColor.withOpacity(0.2)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Spacing.w3,
              SizedBox(
                width: _BoatTableConstants.col.slNo,
                child: Text(slNo, style: TextStyle(fontSize: _BoatTableConstants.font.normal)),
              ),
              SizedBox(
                width: _BoatTableConstants.col.name,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.primaryCustomer.firstName} x ${booking.noOfPersons}',
                      style: TextStyle(fontSize: _BoatTableConstants.font.normal),
                    ),
                    if (booking.equipmentNotes.stringOrNull != null)
                      Text(
                        'Notes: ${booking.equipmentNotes.stringOrNull ?? '-'}',
                        style: TextStyle(fontSize: _BoatTableConstants.font.normal, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: _BoatTableConstants.col.airNitrox,
                child: _TankInfoDisplay(
                  air: booking.isDSD ? booking.noOfPersons : (booking.air ?? 0),
                  nitrox: booking.nitrox ?? 0,
                ),
              ),
              _TextWidget(' ${booking.activity.shortName}', _BoatTableConstants.col.activity),
              Spacing.w5,
              Container(
                decoration: BoxDecoration(
                  color: BookingStatus.getStatusColor(booking.isDSD, booking.status ?? 0),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: _TextWidget(
                  '${booking.prettyStatus}',
                  _BoatTableConstants.col.statusAction,
                  Colors.black,
                  true,
                ).paddingOnly(top: 2, left: 1, right: 1),
              ),
            ],
          ).paddingOnly(top: 3),
          _DiveBuddyList(booking),
        ],
      ),
    );
  }
}

class _DiveBuddyList extends StatelessWidget {
  final Booking booking;

  const _DiveBuddyList(this.booking);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Spacing.w3,
        Spacing.w10,
        SizedBox(
          width: _BoatTableConstants.col.name,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...(booking.buddies ?? []).map(
                (diveBuddy) => Text(
                  diveBuddy.name.capitalizeFirst(),
                  style: TextStyle(fontSize: _BoatTableConstants.font.normal, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: _BoatTableConstants.col.airNitrox,
          child: Column(
            children: [
              if ((booking.buddies ?? []).isNotEmpty)
                ...(booking.buddies ?? []).map(
                  (diveBuddy) => _TankInfoDisplay(
                    air: diveBuddy.air,
                    nitrox: diveBuddy.nitrox,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColumnHeadings extends StatelessWidget {
  const _ColumnHeadings();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Spacing.w3,
        _TextWidget('#   Name', _BoatTableConstants.col.heading),
        _TextWidget('A - N', _BoatTableConstants.col.tanks),
        _TextWidget('Course', _BoatTableConstants.col.activity, null, true),
        Spacing.w5,
        _TextWidget('Status', _BoatTableConstants.col.status, null, true),
      ],
    ).paddingOnly(top: 2);
  }
}

class _TextWidget extends StatelessWidget {
  const _TextWidget(this.title, [this.width, this.color, this.isCenter = false]);

  final String title;
  final double? width;
  final Color? color;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      title,
      style: TextStyle(fontSize: _BoatTableConstants.font.normal, color: color),
      textAlign: isCenter ? TextAlign.center : null,
    );

    return SizedBox(width: width, child: isCenter ? child.center : child);
  }
}

class _AllTotals extends StatelessWidget {
  final Boat boat;
  final List<Booking> bookings;

  const _AllTotals({required this.boat, required this.bookings});

  @override
  Widget build(BuildContext context) {
    bool hasSpareAir = (boat.spareAir ?? 0) != 0;
    bool hasSpareNitrox = (boat.spareNitrox ?? 0) != 0;

    // Single efficient calculation instead of multiple loops
    final summary = _BoatCalculations.getSummary(bookings, boat);
    final totalAir = summary.totalAir + (boat.spareAir ?? 0);
    final totalNitrox = summary.totalNitrox + (boat.spareNitrox ?? 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeadingItem(
              'Total Air ${hasSpareAir ? '(w Extra / Spare)' : ''}: ',
              '$totalAir',
            ),
            _HeadingItem(
              'Total Nitrox ${hasSpareNitrox ? '(w Extra / Spare)' : ''}: ',
              '$totalNitrox',
            ),
            _HeadingItem(
              'Total Tanks: ',
              '${totalAir + totalNitrox}',
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeadingItem('Total Pax : ', '${summary.totalPax}'),
            _HeadingItem('DSD Instructors : ', '${boat.dsdInstructors?.length}'),
            _HeadingItem('Total DSD PAX : ', '${summary.totalDsdPax}'),
            _HeadingItem('Total Instructors : ', '${summary.totalInstructors}'),
            _HeadingItem('Total Courses : ', '${summary.totalCourses}'),
          ],
        ),
      ],
    ).paddingAll(3);
  }
}

/// Calculation summary for boat data
class BoatSummary {
  final int totalAir;
  final int totalNitrox;
  final int totalPax;
  final int totalInstructors;
  final int totalCourses;
  final int totalDsdPax;
  final int totalDiveBuddies;

  const BoatSummary({
    required this.totalAir,
    required this.totalNitrox,
    required this.totalPax,
    required this.totalInstructors,
    required this.totalCourses,
    required this.totalDsdPax,
    required this.totalDiveBuddies,
  });
}

/// Structured models for instructor groups with calculations
class InstructorGroup {
  final int? instructorId;
  final String? instructorName;
  final List<Booking> bookings;
  final int airTotal;
  final int nitroxTotal;
  final bool hasInstructor;
  final List<Booking> dsdBookings;
  final List<Booking> otherBookings;

  InstructorGroup._({
    required this.instructorId,
    required this.instructorName,
    required this.bookings,
    required this.airTotal,
    required this.nitroxTotal,
    required this.hasInstructor,
    required this.dsdBookings,
    required this.otherBookings,
  });

  factory InstructorGroup.fromBookings(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return InstructorGroup._(
        instructorId: null,
        instructorName: null,
        bookings: [],
        airTotal: 0,
        nitroxTotal: 0,
        hasInstructor: false,
        dsdBookings: [],
        otherBookings: [],
      );
    }

    // Calculate totals
    int airTotal = 0;
    int nitroxTotal = 0;
    for (var booking in bookings) {
      airTotal += booking.instructor?.air ?? 0;
      nitroxTotal += booking.instructor?.nitrox ?? 0;
    }

    // Group by DSD vs other
    final dsdBookings = bookings.where((b) => b.isDSD).toList();
    final otherBookings = bookings.where((b) => !b.isDSD).toList();

    return InstructorGroup._(
      instructorId: bookings.first.instructor?.userId,
      instructorName: bookings.first.instructor?.name,
      bookings: bookings,
      airTotal: airTotal,
      nitroxTotal: nitroxTotal,
      hasInstructor: bookings.first.instructor != null,
      dsdBookings: dsdBookings,
      otherBookings: otherBookings,
    );
  }
}

/// Helper class for boat calculations - extracted for better maintainability
class _BoatCalculations {
  /// Groups bookings by instructor ID, excluding cancelled bookings
  static Map<int, InstructorGroup> groupBookingsByInstructor(List<Booking> bookings) {
    final Map<int, List<Booking>> groupedBookings = {
      0: [], // Bucket for bookings without instructor
    };

    // Group bookings by instructor, filtering out cancelled ones
    for (final booking in bookings) {
      if (booking.cancelBooking ?? false) continue;

      final id = booking.instructor?.userId ?? 0;
      groupedBookings.putIfAbsent(id, () => []).add(booking);
    }

    // Convert to InstructorGroup objects and sort by instructor ID
    final result = <int, InstructorGroup>{};
    for (final key in (groupedBookings.keys.toList()..sort())) {
      if (groupedBookings[key]!.isNotEmpty) {
        result[key] = InstructorGroup.fromBookings(groupedBookings[key]!);
      }
    }

    return result;
  }

  /// Single-loop calculation for maximum efficiency
  /// Excludes deleted bookings from all calculations
  static BoatSummary getSummary(List<Booking> bookings, Boat boat) {
    int totalAir = 0;
    int totalNitrox = 0;
    int totalPax = 0;
    int totalCourses = 0;
    int totalDsdPax = 0;
    final Set<int> uniqueInstructorIds = {};
    final Set<TankInfo> uniqueDiveBuddies = {};

    // Single loop through bookings
    for (var booking in bookings) {
      // Skip deleted bookings completely
      if (booking.cancelBooking ?? false) continue;

      if (booking.boat?.id == boat.id) {
        // Count passengers and courses
        totalPax += booking.noOfPersons;
        totalCourses += booking.noOfPersons;

        // Count DSD passengers
        if (booking.isDSD) {
          totalDsdPax += booking.noOfPersons;
          totalAir += booking.noOfPersons; // DSD uses air tanks
        }

        // Count booking tanks
        totalAir += booking.air ?? 0;
        totalNitrox += booking.nitrox ?? 0;

        // Count instructor tanks and unique instructors
        if (booking.instructor != null) {
          uniqueInstructorIds.add(booking.instructor!.userId!);
          totalAir += booking.instructor!.air ?? 0;
          totalNitrox += booking.instructor!.nitrox ?? 0;
        }

        // Count dive buddy tanks
        for (TankInfo buddy in (booking.buddies ?? [])) {
          uniqueDiveBuddies.add(buddy);
          totalAir += buddy.air ?? 0;
          totalNitrox += buddy.nitrox ?? 0;
        }
      }
    }

    // Add staff tanks
    for (TankInfo staff in (boat.dsdInstructors ?? [])) {
      totalAir += staff.air ?? 0;
      totalNitrox += staff.nitrox ?? 0;
    }

    for (TankInfo photographer in (boat.photographers ?? [])) {
      totalAir += photographer.air ?? 0;
      totalNitrox += photographer.nitrox ?? 0;
    }

    for (TankInfo intern in (boat.internPhotographers ?? [])) {
      totalAir += intern.air ?? 0;
      totalNitrox += intern.nitrox ?? 0;
    }

    // Add staff to passenger count
    final totalStaff =
        (boat.dsdInstructors?.length ?? 0) +
        (boat.photographers?.length ?? 0) +
        (boat.internPhotographers?.length ?? 0);

    return BoatSummary(
      totalAir: totalAir,
      totalNitrox: totalNitrox,
      totalPax: totalPax + uniqueInstructorIds.length + uniqueDiveBuddies.length + totalStaff,
      totalInstructors: uniqueInstructorIds.length,
      totalCourses: totalCourses,
      totalDsdPax: totalDsdPax,
      totalDiveBuddies: uniqueDiveBuddies.length,
    );
  }
}
