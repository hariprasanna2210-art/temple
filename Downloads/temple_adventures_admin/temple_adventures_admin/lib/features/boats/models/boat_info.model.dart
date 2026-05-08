import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

part 'boat_info.model.mapper.dart';

@immutable
@MappableClass()
class TankInfo with TankInfoMappable {
  final int? userId;
  final String? userFirstName;
  final String? userLastName;
  final Role? role;
  final int? nitrox;
  final int? air;

  const TankInfo({
    required this.userId,
    required this.userFirstName,
    required this.userLastName,
    required this.role,
    required this.nitrox,
    required this.air,
  });

  String formatedTankInfo([bool tanksRequired = true]) {
    if (tanksRequired) {
      return '$name ($nitrox - $air)';
    }
    return name;
  }

  String get name => '$userFirstName $userLastName';
}

@MappableEnum(caseStyle: CaseStyle.snakeCase)
enum Role {
  captains,
  internPhotographers,
  photographers,
  surfaceSupport,
  dsdInstructors,
  instructor,
  buddy,
  dsdPool,
  dsdOceanLeader,
  dsdCenterStaff,
  harbourStaff,
  dayOffs,
  leaves,
}
