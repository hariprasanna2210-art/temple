import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

import '../../../utils/mapping_hooks/double_conversion.dart';
import '../../user/models/user.model.dart';

part 'surface_conditions.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class SurfaceConditions with SurfaceConditionsMappable {
  final int? id;
  final String reefName;
  final double temp;
  final double speed;
  final double currents;
  final double swell;
  final User updatedBy;
  final DateTime updatedAt;
  final DateTime date;

  const SurfaceConditions({
    this.id,
    required this.reefName,
    required this.temp,
    required this.speed,
    required this.currents,
    required this.swell,
    required this.updatedBy,
    required this.updatedAt,
    required this.date,
  });
}
