import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:temple_adventures_admin/features/general_info/models/general_info.model.dart';
import 'package:temple_adventures_admin/features/user/bloc/all_users.cubit.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../utils/styling/spacing_widgets.dart';
import '../../../general_info/enums/bcd.enum.dart';
import '../../../general_info/enums/weights.enum.dart';
import '../../models/boat_info.model.dart';

const TextStyle _dateStyle = TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600);
const TextStyle _keyStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 11);
const TextStyle _fontSize11 = TextStyle(fontSize: 11);
const TextStyle _fontWeightBold = TextStyle(fontWeight: FontWeight.bold);

class GeneralInfoTable extends StatelessWidget {
  final GeneralInfo? generalInfo;
  final DateTime selectedDate;

  const GeneralInfoTable({super.key, required this.generalInfo, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    if (generalInfo == null) return Text("No data found");

    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Spacing.h10,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('General Info :'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedDate.formatDDMMYYYY, style: _dateStyle).paddingSymmetric(vertical: 5),
                  Text(DateFormat('EEEE').format(selectedDate), style: _dateStyle),
                ],
              ),
            ],
          ),
          Spacing.h3,
          const Text('BCD', style: _keyStyle).left,
          Spacing.h5,
          RichText(
            text: TextSpan(
              text: 'XS - ',
              style: _fontSize11.copyWith(color: Colors.black),
              children: <TextSpan>[
                TextSpan(text: '${generalInfo?.bcd?[Bcd.xs] ?? 0}, ', style: _fontWeightBold),
                const TextSpan(text: 'S - ', style: _fontSize11),
                TextSpan(text: '${generalInfo?.bcd?[Bcd.s] ?? 0}, ', style: _fontWeightBold),
                const TextSpan(text: 'M - ', style: _fontSize11),
                TextSpan(text: '${generalInfo?.bcd?[Bcd.m] ?? 0}, ', style: _fontWeightBold),
                TextSpan(
                  text: 'L - ',
                  style: _fontSize11.copyWith(color: Colors.black),
                  children: <TextSpan>[
                    TextSpan(text: '${generalInfo?.bcd?[Bcd.l] ?? 0}, ', style: _fontWeightBold),
                    const TextSpan(text: 'XL - ', style: _fontSize11),
                    TextSpan(text: '${generalInfo?.bcd?[Bcd.xl] ?? 0}, ', style: _fontWeightBold),
                    const TextSpan(text: 'XXL - ', style: _fontSize11),
                    TextSpan(text: '${generalInfo?.bcd?[Bcd.xxl] ?? 0}, ', style: _fontWeightBold),
                  ],
                ),
              ],
            ),
          ),
          Spacing.h6,
          const Text('Weights', style: _keyStyle).left,
          Spacing.h5,
          RichText(
            text: TextSpan(
              text: '3KG - ',
              style: _fontSize11.copyWith(color: Colors.black),
              children: <TextSpan>[
                TextSpan(text: '${generalInfo?.weights?[Weights.w3] ?? 0}, ', style: _fontWeightBold),
                const TextSpan(text: '4KG - ', style: _fontSize11),
                TextSpan(text: '${generalInfo?.weights?[Weights.w4] ?? 0}, ', style: _fontWeightBold),
                TextSpan(
                  text: '5KG - ',
                  style: _fontSize11.copyWith(color: Colors.black),
                  children: <TextSpan>[
                    TextSpan(text: '${generalInfo?.weights?[Weights.w5] ?? 0}, ', style: _fontWeightBold),
                    const TextSpan(text: '6KG - ', style: _fontSize11),
                    TextSpan(text: '${generalInfo?.weights?[Weights.w6] ?? 0}, ', style: _fontWeightBold),
                    const TextSpan(text: '7KG - ', style: _fontSize11),
                    TextSpan(text: '${generalInfo?.weights?[Weights.w7] ?? 0}, ', style: _fontWeightBold),
                  ],
                ),
              ],
            ),
          ),
          Spacing.h6,
          _LineItem('Fins', '${generalInfo?.fins ?? 0}'),
          _LineItem('Mask', '${generalInfo?.mask ?? 0}'),
          _LineItem('Regulator', '${generalInfo?.regulator ?? 0}'),
          _LineItem('Power Mask', "${generalInfo?.powerMask ?? 0} (${generalInfo?.powerNotes ?? '-'})"),
          Spacing.h3,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Weather :'),
                  Spacing.h3,
                  _LineItem('Waves', "${generalInfo?.waves ?? '-'} m/s"),
                  _LineItem('Winds', "${generalInfo?.winds ?? '-'} km/h"),
                  _LineItem('Low Tides', generalInfo?.lowTide?.formatHHMM ?? '-'),
                  _LineItem('High Tides', generalInfo?.highTide?.formatHHMM ?? '-'),
                ],
              ),
            ],
          ),
          Spacing.h3,
          _SectionTitle('Employees : '),
          Spacing.h3,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DSD Pool', style: _keyStyle),
                  Spacing.h3,
                  Text(generalInfo!.dsdPool.names(true), style: _fontSize11),
                  Spacing.h3,
                  const Text('DSD Ocean Leader', style: _keyStyle),
                  Spacing.h3,
                  Text(generalInfo!.dsdOceanLeader.names(true), style: _fontSize11),
                  Spacing.h3,
                  const Text('DSD Center Staff', style: _keyStyle),
                  Spacing.h3,
                  Text(generalInfo!.dsdCenterStaff.names(true), style: _fontSize11),
                  Spacing.h3,
                  const Text('Harbour Staff', style: _keyStyle),
                  Spacing.h3,
                  Text(generalInfo!.harbourStaff.names(true), style: _fontSize11),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Day offs', style: _keyStyle),
                  Spacing.h3,
                  Text(generalInfo!.dayOffs.names(true), style: _fontSize11),
                  Spacing.h3,
                  const Text('Leaves', style: _keyStyle),
                  Spacing.h3,
                  Text(generalInfo!.leaves?.names(true) ?? '-', style: _fontSize11),
                  Spacing.h3,
                  const Text('Long leaves', style: _keyStyle),
                  Spacing.h3,
                  _LongLeavesList(selectedDate: selectedDate),
                  Spacing.h3,
                  const Text('General Notes', style: _keyStyle).left,
                  Spacing.h3,
                  SizedBox(width: 90, child: Text(generalInfo!.notes?.stringOrNull ?? '-', style: _fontSize11)),
                ],
              ),
            ],
          ),
          Spacing.h10,
        ],
      ).paddingOnly(left: 15, right: 15),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Colors.black,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.w600,
      ),
    ).paddingSymmetric(vertical: 5);
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem(this.title, this.value);

  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
        Text(value.stringOrNull ?? '-', style: _fontSize11),
      ],
    ).paddingOnly(bottom: 3);
  }
}

extension _TankInfoX on List<TankInfo>? {
  String names([bool useNextLine = false]) {
    if (this?.isEmpty ?? false) {
      return '-';
    }

    String names = '';
    for (var ins in this!) {
      if (useNextLine) {
        names += '${ins.name}, \n';
      } else {
        names += '${ins.name}, ';
      }
    }
    if (useNextLine) {
      return names.substring(0, names.length - 3);
    }
    return names.substring(0, names.length - 2);
  }
}

/// Widget to display employees on long leave for the selected date
class _LongLeavesList extends StatelessWidget {
  final DateTime selectedDate;

  const _LongLeavesList({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllUsersCubit, AllUsersState>(
      builder: (context, state) {
        // Fetch users if not already loaded
        if (state.users.isEmpty) {
          context.read<AllUsersCubit>().fetchAllUsers();
          return const Text('-', style: _fontSize11);
        }

        // Filter users who are on leave for the selected date
        final usersOnLeave = state.users.where((user) {
          if (user.leaveStartDate == null || user.leaveEndDate == null) {
            return false;
          }

          // Normalize dates to compare only year, month, day (ignore time)
          final selectedDateOnly = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
          );
          final leaveStartOnly = DateTime(
            user.leaveStartDate!.year,
            user.leaveStartDate!.month,
            user.leaveStartDate!.day,
          );
          final leaveEndOnly = DateTime(
            user.leaveEndDate!.year,
            user.leaveEndDate!.month,
            user.leaveEndDate!.day,
          );

          // Check if selected date is between leave start and end date (inclusive)
          // selectedDate >= leaveStartDate AND selectedDate <= leaveEndDate
          return !selectedDateOnly.isBefore(leaveStartOnly) &&
              !selectedDateOnly.isAfter(leaveEndOnly);
        }).toList();

        if (usersOnLeave.isEmpty) {
          return const Text('-', style: _fontSize11);
        }

        // Format names similar to other employee lists
        String names = '';
        for (var user in usersOnLeave) {
          names += '${user.fullName}, \n';
        }
        // Remove trailing comma and newline
        if (names.isNotEmpty) {
          names = names.substring(0, names.length - 3);
        }

        return Text(names, style: _fontSize11);
      },
    );
  }
}
