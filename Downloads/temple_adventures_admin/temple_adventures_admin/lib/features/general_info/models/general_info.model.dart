import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/general_info/enums/bcd.enum.dart';
import 'package:temple_adventures_admin/features/general_info/enums/weights.enum.dart';

import '../../../utils/mapping_hooks/datetime_hooks.dart';
import '../../../utils/mapping_hooks/double_conversion.dart';
import '../../boats/models/boat_info.model.dart';

part 'general_info.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class GeneralInfo with GeneralInfoMappable {
  final int? id;
  final String date;
  final Map<Bcd, int>? bcd;
  final int? regulator;
  final int? mask;
  final int? powerMask;
  final String? powerNotes;
  final int? fins;
  final Map<Weights, int>? weights;
  final List<TankInfo>? dsdPool;
  final List<TankInfo>? dsdOceanLeader;
  final List<TankInfo>? dsdCenterStaff;
  final List<TankInfo>? harbourStaff;
  final List<TankInfo>? dayOffs;
  final List<TankInfo>? leaves;
  final String? notes;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime? lowTide;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime? highTide;
  final String? waves;
  final String? winds;

  const GeneralInfo({
    this.id,
    required this.date,
    this.bcd,
    this.regulator,
    this.mask,
    this.powerMask,
    this.powerNotes,
    this.fins,
    this.weights,
    this.dsdPool,
    this.dsdOceanLeader,
    this.dsdCenterStaff,
    this.harbourStaff,
    this.dayOffs,
    this.leaves,
    this.notes,
    this.lowTide,
    this.highTide,
    this.waves,
    this.winds,
  });

  Map<String, dynamic> toRow({bool includeId = false}) {
    final generalInfoMap =
        toMap()
          ..remove('dsd_pool')
          ..remove('dsd_ocean_leader')
          ..remove('dsd_center_staff')
          ..remove('harbour_staff')
          ..remove('day_offs')
          ..remove('leaves');
    if (includeId == false) generalInfoMap.remove('id');

    return generalInfoMap;
  }

  List<TankInfo> get users => [
    ...dsdPool ?? [],
    ...dsdOceanLeader ?? [],
    ...dsdCenterStaff ?? [],
    ...harbourStaff ?? [],
    ...dayOffs ?? [],
    ...leaves ?? [],
  ];
}
