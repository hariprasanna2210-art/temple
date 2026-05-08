import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/activities/models/activity_color.model.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';

part 'activity.model.mapper.dart';

@immutable
@MappableClass()
class Activity with ActivityMappable {
  final int? id;
  final String name;
  final String shortName;
  final double price;
  final ActivityColor color;
  final int priority;
  final bool isDeleted;

  const Activity({
    this.id,
    required this.name,
    required this.shortName,
    required this.price,
    required this.color,
    required this.priority,
    this.isDeleted = false,
  });

  Color get toDartColor => color.color.toNormalColor();
}
