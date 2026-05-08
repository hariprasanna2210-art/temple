import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/boats/enums/boat_type.enum.dart';
import 'package:temple_adventures_admin/features/boats/models/boat_info.model.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';

import '../../../utils/mapping_hooks/datetime_hooks.dart';
import '../../../utils/mapping_hooks/double_conversion.dart';
import '../enums/boat_status.enum.dart';

part 'boats.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class Boat with BoatMappable {
  final int? id;
  final bool hide;
  final BoatType type;
  final BoatStatus status;
  final String? number;
  final String name;
  final String? diveSite;
  final String date;
  final String? notes;

  @MappableField(hook: DateTimeToLocalHook())
  final DateTime time;
  final List<TankInfo>? captains;
  final List<TankInfo>? dsdInstructors;
  final List<TankInfo>? photographers;
  final List<TankInfo>? internPhotographers;
  final List<TankInfo>? surfaceSupport;
  final int? spareNitrox;
  final int? spareAir;

  const Boat({
    this.id,
    required this.hide,
    required this.type,
    this.number,
    required BoatStatus? status,
    required this.name,
    required this.diveSite,
    required this.notes,
    required this.date,
    required this.time,
    this.captains,
    this.dsdInstructors,
    this.photographers,
    this.internPhotographers,
    this.surfaceSupport,
    this.spareNitrox,
    this.spareAir,
  }) : status = status ?? BoatStatus.ready;

  Map<String, dynamic> toRow({bool includeId = false}) {
    final boatMap =
        toMap()
          ..remove('captains')
          ..remove('dsd_instructors')
          ..remove('photographers')
          ..remove('intern_photographers')
          ..remove('surface_support');
    if (includeId == false) boatMap.remove('id');

    return boatMap;
  }

  List<TankInfo> get users => [
    ...captains ?? [],
    ...dsdInstructors ?? [],
    ...photographers ?? [],
    ...internPhotographers ?? [],
    ...surfaceSupport ?? [],
  ];

  String get nameAndTime => '$name @ ${time.formatHHMM}';
}
