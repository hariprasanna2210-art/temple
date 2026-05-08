import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

import '../../../utils/mapping_hooks/double_conversion.dart';
import '../../user/models/user.model.dart';

part 'water_conditions.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class WaterConditions with WaterConditionsMappable {
  final int? id;
  final int depth;
  final int fish;
  final int visibility;
  final int currents;
  final String reef;
  final User updatedBy;
  final DateTime updatedAt;
  final DateTime date;

  const WaterConditions({
    this.id,
    required this.depth,
    required this.fish,
    required this.visibility,
    required this.currents,
    required this.reef,
    required this.updatedBy,
    required this.updatedAt,
    required this.date,
  });
}
