import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/mapping_hooks/time_hooks.dart';

import '../../user/models/user.model.dart';

part 'roster.model.mapper.dart';

@immutable
@MappableClass()
class Roster with RosterMappable {
  final int? id;
  final int customerId;
  final int bookingId;

  final User? instructor;
  @MappableField(hook: TimeOfDayHook())
  final TimeOfDay? timeIn;
  @MappableField(hook: TimeOfDayHook())
  final TimeOfDay? timeOut;
  final bool? isDived;

  const Roster({
    this.id,
    required this.instructor,
    required this.customerId,
    required this.bookingId,
    required this.timeIn,
    required this.timeOut,
    required this.isDived,
  });

  Map<String, dynamic> toRow({bool removeId = true}) {
    final rosterMap = toMap()..remove('instructor');
    if (removeId) rosterMap.remove('id');

    rosterMap['instructor_id'] = instructor?.id;

    return rosterMap;
  }
}
