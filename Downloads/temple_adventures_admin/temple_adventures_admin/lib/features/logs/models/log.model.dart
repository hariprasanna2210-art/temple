import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';
import 'package:temple_adventures_admin/features/logs/enums/action_type.enum.dart';
import 'package:temple_adventures_admin/utils/mapping_hooks/datetime_hooks.dart';
import 'package:temple_adventures_admin/utils/mapping_hooks/double_conversion.dart';

import '../../user/models/user.model.dart';

part 'log.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class LogModel with LogModelMappable {
  final int? id;
  final ActionType actionType;
  final User createdBy;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime? createdAt;
  final Map<String, dynamic> additionalInformation;

  LogModel({
    this.id,
    required this.actionType,
    required this.createdBy,
    DateTime? createdAt,
    required this.additionalInformation,
  }) : createdAt = createdAt ?? DateTime.now();
}
