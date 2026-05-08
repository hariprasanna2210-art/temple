import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/mapping_hooks/double_conversion.dart';
import '../../../utils/mapping_hooks/datetime_hooks.dart';
import '../../user/models/user.model.dart';
part 'event.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
///Named as Event model instead of Event due to inbuilt dart event mapper existence
class EventModel with EventModelMappable {
  final int? id;
  final String sessionName;
  final String location;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime eventDateTime;
  final User contactPerson;
  final User createdBy;

  const EventModel({
    this.id,
    required this.location,
    required this.sessionName,
    required this.contactPerson,
    required this.eventDateTime,
    required this.createdBy,
  });
}
